using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

// Batch Play Mode integration checks against the real scene and prefabs.
[InitializeOnLoad]
public static class BlockLabWorkspaceChecks
{
    private const string Pending = "BlockLab.WorkspaceChecks.Pending";
    private const string Result = "BlockLab.WorkspaceChecks.Result";
    [Serializable] private class Request { public string sessionId; public string sceneDataJson; }
    static BlockLabWorkspaceChecks() { EditorApplication.playModeStateChanged += OnPlayMode; }
    public static void Run()
    {
        BlockLabBuild.Configure();
        SessionState.SetBool(Pending, true);
        SessionState.SetInt(Result, -1);
        EditorApplication.EnterPlaymode();
    }
    private static void Require(bool condition, string message)
    {
        if (!condition) throw new Exception(message);
    }
    private static void OnPlayMode(PlayModeStateChange state)
    {
        if (state == PlayModeStateChange.EnteredPlayMode && SessionState.GetBool(Pending, false))
            EditorApplication.delayCall += Check;
        if (state == PlayModeStateChange.EnteredEditMode && SessionState.GetInt(Result, -1) >= 0)
            EditorApplication.delayCall += () => {
                int result = SessionState.GetInt(Result, 1);
                SessionState.SetInt(Result, -1);
                EditorApplication.Exit(result);
            };
    }
    private static void ExitSafely(int result)
    {
        SessionState.SetInt(Result, result);
        EditorApplication.ExitPlaymode();
    }
    private static void Check()
    {
        SessionState.SetBool(Pending, false);
        try
        {
            var loader = UnityEngine.Object.FindObjectOfType<LoadManager>();
            var hierarchy = UnityEngine.Object.FindObjectOfType<HierarchyManager>(true);
            var ui=UnityEngine.Object.FindObjectOfType<SandboxUIController>();
            ui.ToggleShapes();
            var palette=ui.canvas.GetComponentInChildren<UIDragItem>();
            var pointer=new UnityEngine.EventSystems.PointerEventData(UnityEngine.EventSystems.EventSystem.current) {
                pressPosition=new Vector2(10,30),position=new Vector2(10,60)
            };
            palette.OnBeginDrag(pointer);
            Require(CameraHandler.IsCameraLocked,"Palette scrolling did not lock the camera");
            palette.OnEndDrag(pointer);
            Require(!CameraHandler.IsCameraLocked,"Palette scrolling left the camera locked");
            ui.CloseDrawer();
            foreach(var text in ui.canvas.GetComponentsInChildren<TMPro.TMP_Text>(true))
                Require(text.font!=null && text.font.name=="Nunito SDF", "Sandbox label is not using bundled Nunito: "+text.name);
            var source = new SceneSaveWrapper {schemaVersion = 2, blocks = new List<BlockSaveData>()};
            for (int i = 0; i < 5; i++) source.blocks.Add(new BlockSaveData {
                blockId = "roundtrip-" + i, blockName = "Custom saved name " + i, shapeType = i,
                position = new Vector3(i * 4, i, -3), rotation = loader.blockPrefabs[i].transform.rotation,
                color = new Color(.2f, .4f, .6f, 1), widthOrRadius = 2, height = 3, length = 4
            });
            string json = JsonUtility.ToJson(source);
            loader.BeginSession(JsonUtility.ToJson(new Request {sessionId = "test-session", sceneDataJson = json}));
            var actual = SaveManager.Capture();
            Require(actual.blocks.Count == 5, "Scene did not restore five shapes");
            foreach (var expected in source.blocks)
            {
                var b = actual.blocks.Single(x => x.blockId == expected.blockId);
                Require(b.blockName == expected.blockName && b.shapeType == expected.shapeType, "Identity/name/shape changed");
                Require(Vector3.Distance(b.position, expected.position) < .0001f, "Loading moved a saved block");
                Require(Quaternion.Angle(b.rotation, expected.rotation) < .01f, "Saved orientation changed");
                Require(b.widthOrRadius == expected.widthOrRadius && b.height == expected.height && b.length == expected.length, "Dimensions changed");
                Require(b.color == expected.color, "Color changed");
            }
            loader.BeginSession(JsonUtility.ToJson(new Request {sessionId = "test-session", sceneDataJson = ""}));
            Require(SaveManager.Capture().blocks.Count == 5, "Repeated session reset the scene");
            loader.LoadBuildFromJson("{\"blocks\":[{\"shapeType\":99}]}");
            Require(SaveManager.Capture().blocks.Count == 5, "Invalid import destroyed current work");
            var block = UnityEngine.Object.FindObjectsOfType<BlockData>().First();
            hierarchy.AddBlockToList(block.gameObject); // Duplicate registration must be harmless.
            var oldName = block.name;
            var before = block.transform.position;
            UndoManager.Instance.RecordCommand(new MoveCommand(block.transform, before));
            block.transform.position += Vector3.right * 5;
            UndoManager.Instance.ClickUndo();
            Require(block.transform.position == before, "Move undo failed");
            int savedRevision=WorkspaceState.Revision;
            ui.SetAppearance("{\"mode\":\"dark\",\"textScale\":2,\"pixelRatio\":1}");
            Require(block.transform.position==before && WorkspaceState.Revision==savedRevision, "Appearance changed scene/dirty state");
            WorkspaceState.Edit();
            var save=loader.GetComponent<SaveManager>();
            save.AcknowledgeSave("{\"sessionId\":\"test-session\",\"revision\":"+savedRevision+"}");
            Require(WorkspaceState.Dirty,"Stale save acknowledgement cleared newer edits");
            save.AcknowledgeSave("{\"sessionId\":\"test-session\",\"revision\":"+WorkspaceState.Revision+"}");
            Require(!WorkspaceState.Dirty,"Successful save acknowledgement did not clear dirty state");
            var snapshot = new WorkspaceSnapshotCommand();
            var positions = UnityEngine.Object.FindObjectsOfType<BlockData>().ToDictionary(b => b.blockId, b => b.transform.position);
            block.height = 8; block.ApplyDimensions(); block.SetColor(Color.red);
            snapshot.Undo();
            Require(block.height == 3 && block.blockColor == source.blocks[0].color, "Resize/color snapshot undo failed");
            foreach (var b in UnityEngine.Object.FindObjectsOfType<BlockData>()) Require(b.transform.position == positions[b.blockId], "Neighbor position was not restored");
            hierarchy.RemoveBlockFromList(block.gameObject);
            block.gameObject.SetActive(false);
            new DeleteCommand(block.gameObject, hierarchy).Undo();
            Require(block.gameObject.activeSelf && block.name == oldName, "Delete undo lost the block/name");
            var added = UnityEngine.Object.Instantiate(loader.blockPrefabs[0]);
            hierarchy.AddBlockToList(added);
            new UndoManager.AddCommand(added, hierarchy).Undo();
            Require(!added.activeSelf, "Add undo failed");
            UnityEngine.Object.FindObjectOfType<SelectionManager>().ForceSelectBlock(block);
            int frame = Time.frameCount;
            EditorApplication.CallbackFunction finish = null;
            finish = () => {
                if (Time.frameCount < frame + 3) return;
                EditorApplication.update -= finish;
                try
                {
                    var properties = UnityEngine.Object.FindObjectOfType<PropertiesUIManager>(true);
                    Require(properties.propertiesPanel.activeSelf, "First selection closed the properties panel during Start");
                    loader.BeginSession(JsonUtility.ToJson(new Request {sessionId = "new-session", sceneDataJson = ""}));
                    Require(SaveManager.Capture().blocks.Count == 0, "New session retained old blocks");
                    Require(!SelectionManager.isDraggingBlock && !CameraHandler.IsCameraLocked, "New session retained gesture locks");
                    Debug.Log("BLOCKLAB_WORKSPACE_CHECKS_PASSED: real five-shape load/save, names, rotations, repeated session, invalid import, hierarchy, move, resize/color, add/delete undo, first selection and session cleanup.");
                    ExitSafely(0);
                }
                catch (Exception error) { Debug.LogException(error); ExitSafely(1); }
            };
            EditorApplication.update += finish;
        }
        catch (Exception error) { Debug.LogException(error); ExitSafely(1); }
    }
}
