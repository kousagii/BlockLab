using UnityEngine;
using System;
using System.Collections.Generic;

public class LoadManager : MonoBehaviour
{
    public GameObject[] blockPrefabs;
    public HierarchyManager hierarchyManager;
    public string SessionId { get; private set; }
    [Serializable] private class SessionRequest { public string sessionId; public string sceneDataJson; }
    [Serializable] private class Reply { public string messageType; public string sessionId; public string message; }

    public void RequestReady(string requestedSession) { ReplyToFlutter("UNITY_READY", requestedSession); }
    public void BeginSession(string json)
    {
        try
        {
            var request = JsonUtility.FromJson<SessionRequest>(json);
            if (request == null || string.IsNullOrEmpty(request.sessionId)) throw new ArgumentException("Missing session");
            if (request.sessionId != SessionId)
            {
                if (string.IsNullOrEmpty(request.sceneDataJson)) ClearScene("");
                else Restore(ParseAndValidate(request.sceneDataJson));
                SessionId = request.sessionId;
            }
            ReplyToFlutter("SESSION_STARTED", SessionId);
            FindObjectOfType<SandboxUIController>()?.PublishState();
        }
        catch (Exception error) { ReplyToFlutter("ERROR", "", error.Message); }
    }
    public void LoadBuildFromJson(string json)
    {
        try { Restore(ParseAndValidate(json)); }
        catch (Exception error) { ReplyToFlutter("ERROR", SessionId, error.Message); }
    }
    private static bool Finite(float n) { return !float.IsNaN(n) && !float.IsInfinity(n); }
    public SceneSaveWrapper ParseAndValidate(string json)
    {
        if (string.IsNullOrEmpty(json) || json.Length > 8 * 1024 * 1024) throw new ArgumentException("Invalid scene size");
        var scene = JsonUtility.FromJson<SceneSaveWrapper>(json);
        if (scene == null || scene.blocks == null || scene.blocks.Count > 2000 || scene.schemaVersion < 0 || scene.schemaVersion > 2)
            throw new ArgumentException("Unsupported scene format");
        var ids = new HashSet<string>();
        foreach (var b in scene.blocks)
        {
            if (b == null || b.shapeType < 0 || b.shapeType >= blockPrefabs.Length || blockPrefabs[b.shapeType] == null ||
                blockPrefabs[b.shapeType].GetComponent<BlockData>() == null) throw new ArgumentException("Unknown block shape");
            foreach (var n in new[] { b.widthOrRadius, b.height, b.length })
                if (!Finite(n) || n < .1f || n > 100) throw new ArgumentException("Invalid block dimensions");
            foreach (var n in new[] { b.position.x, b.position.y, b.position.z })
                if (!Finite(n) || Mathf.Abs(n) > 10000) throw new ArgumentException("Invalid block position");
            foreach (var n in new[] { b.color.r, b.color.g, b.color.b, b.color.a })
                if (!Finite(n) || n < 0 || n > 1) throw new ArgumentException("Invalid block color");
            if (scene.schemaVersion >= 2)
            {
                var q = b.rotation;
                foreach (var n in new[] {q.x, q.y, q.z, q.w})
                    if (!Finite(n)) throw new ArgumentException("Invalid rotation");
                float magnitude = q.x*q.x + q.y*q.y + q.z*q.z + q.w*q.w;
                if (magnitude < .99f || magnitude > 1.01f) throw new ArgumentException("Invalid rotation");
            }
            if (string.IsNullOrEmpty(b.blockId)) b.blockId = Guid.NewGuid().ToString("N");
            if (!ids.Add(b.blockId)) throw new ArgumentException("Duplicate block ID");
        }
        return scene;
    }
    private void Restore(SceneSaveWrapper scene)
    {
        var stage = new GameObject("SceneLoadStaging");
        stage.SetActive(false);
        try
        {
            foreach (var data in scene.blocks)
            {
                var prefab = blockPrefabs[data.shapeType];
                var obj = Instantiate(prefab, stage.transform);
                obj.name = string.IsNullOrWhiteSpace(data.blockName) ? prefab.name : data.blockName;
                obj.transform.rotation = scene.schemaVersion >= 2 ? data.rotation : prefab.transform.rotation;
                var block = obj.GetComponent<BlockData>();
                block.blockId = data.blockId;
                block.RestoreDimensions(data.widthOrRadius, data.height, data.length);
                obj.transform.position = data.position;
                block.SetColor(data.color);
                var outline = obj.GetComponent<Outline>();
                if (outline != null) outline.enabled = false;
            }
        }
        catch { Destroy(stage); throw; }
        ClearScene("");
        foreach (var block in stage.GetComponentsInChildren<BlockData>(true))
        {
            block.transform.SetParent(null, true);
            block.gameObject.SetActive(true);
            if (hierarchyManager != null) hierarchyManager.AddBlockToList(block.gameObject);
        }
        Destroy(stage);
        Physics.SyncTransforms();
    }
    public void ClearScene(string unused)
    {
        foreach (var selection in FindObjectsOfType<SelectionManager>()) selection.DeselectCurrent();
        SelectionManager.isDraggingBlock = false;
        CameraHandler.IsCameraLocked = false;
        if (UndoManager.Instance != null) UndoManager.Instance.ClearHistory();
        foreach (var block in FindObjectsOfType<BlockData>(true))
        {
            if (block.transform.parent != null && block.transform.parent.name == "SceneLoadStaging") continue;
            block.gameObject.SetActive(false);
            Destroy(block.gameObject);
        }
        if (hierarchyManager != null) hierarchyManager.ClearHierarchyUI();
    }
    private static void ReplyToFlutter(string kind, string session, string message = null)
    {
        SendToFlutter.Send(JsonUtility.ToJson(new Reply {messageType = kind, sessionId = session, message = message}));
    }
}
