using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

public static class BlockLabBuild
{
    [MenuItem("BlockLab/Prepare Android workspace")]
    public static void Configure()
    {
        EditorUserBuildSettings.exportAsGoogleAndroidProject = true;
        EditorUserBuildSettings.buildAppBundle = false;
        PlayerSettings.SetScriptingBackend(BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
        PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel29;
        PlayerSettings.Android.targetSdkVersion = (AndroidSdkVersions)36;
        PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.example.unity_flutter");
        PlayerSettings.productName = "BlockLab";
        PlayerSettings.SetGraphicsAPIs(BuildTarget.Android, new[] { GraphicsDeviceType.OpenGLES3 });
        PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene("Assets/Unity_Flutter.unity", true) };
        var scene = EditorSceneManager.OpenScene("Assets/Unity_Flutter.unity");
        var loader = UnityEngine.Object.FindObjectOfType<LoadManager>(true);
        var save = UnityEngine.Object.FindObjectOfType<SaveManager>(true);
        var selection = UnityEngine.Object.FindObjectOfType<SelectionManager>(true);
        if (loader == null || save == null || selection == null) throw new Exception("Missing workspace bridge or selection manager.");
        BlockLabUIBuilder.Ensure(loader, save, selection);
        var hierarchy = UnityEngine.Object.FindObjectOfType<HierarchyManager>(true);
        var properties = UnityEngine.Object.FindObjectOfType<PropertiesUIManager>(true);
        if (loader == null || save == null || hierarchy == null || selection == null || properties == null)
            throw new Exception($"Workspace managers: load={loader != null}, save={save != null}, hierarchy={hierarchy != null}, selection={selection != null}, properties={properties != null}");
        if (loader.gameObject != save.gameObject) throw new Exception("Save/load bridge must share one GameObject.");
        loader.gameObject.name = "SaveLoadSystem";
        string[] names = {"Cube", "Triprism", "Cylinder", "Trapezoid", "Half-Cylinder"};
        loader.blockPrefabs = names.Select(n => AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefab/" + n + ".prefab")).ToArray();
        for (int i = 0; i < loader.blockPrefabs.Length; i++)
        {
            var prefab = loader.blockPrefabs[i];
            if (prefab == null || prefab.GetComponent<BlockData>() == null || prefab.GetComponentInChildren<Collider>() == null)
                throw new Exception("Missing block prefab/component: " + names[i]);
            if ((int)prefab.GetComponent<BlockData>().shapeType != i) throw new Exception("Incorrect shape ID on " + names[i]);
        }
        loader.hierarchyManager = hierarchy;
        hierarchy.selectionManager = selection;
        selection.uiManager = properties;
        properties.hierarchyManager = hierarchy;
        foreach (var text in UnityEngine.Object.FindObjectsOfType<TMPro.TMP_Text>(true))
            if (text.text == "Pyramid") text.text = "Prism";
        foreach (var item in UnityEngine.Object.FindObjectsOfType<UIDragItem>(true))
        {
            item.hierarchyManager = hierarchy;
            item.selectionManager = selection;
        }
        if (UnityEngine.Object.FindObjectOfType<UndoManager>(true) == null) loader.gameObject.AddComponent<UndoManager>();
        if (save.mainUiCanvas == null) save.mainUiCanvas = properties.GetComponentInParent<Canvas>()?.gameObject;
        if (Camera.main == null || properties.propertiesPanel == null || hierarchy.itemPrefab == null || hierarchy.contentPanel == null)
            throw new Exception("Workspace UI/camera references are incomplete.");
        foreach (var root in scene.GetRootGameObjects())
            foreach (var transform in root.GetComponentsInChildren<Transform>(true))
                if (GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(transform.gameObject) > 0)
                    throw new Exception("Missing script on " + transform.name);
        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene);
        AssetDatabase.SaveAssets();
        Debug.Log("BLOCKLAB_SCENE_VALIDATED: five prefabs and all required managers are wired.");
    }

    public static void ExportAndroid()
    {
        Configure();
        ProjectExporterBatchmode.ExportProject();
    }

    public static void VerifySceneRoundTrip()
    {
        Configure();
        var loader = UnityEngine.Object.FindObjectOfType<LoadManager>(true);
        var source = new SceneSaveWrapper {schemaVersion = 2, blocks = new System.Collections.Generic.List<BlockSaveData>()};
        for (int i = 0; i < 5; i++) source.blocks.Add(new BlockSaveData {
            blockId = "test-" + i, blockName = "Saved name " + i, shapeType = i,
            position = new Vector3(i * 3, i, 0), rotation = loader.blockPrefabs[i].transform.rotation,
            color = new Color(.1f, .4f, .8f, 1), widthOrRadius = 2, height = 3, length = 4
        });
        string json = JsonUtility.ToJson(source);
        var result = loader.ParseAndValidate(json);
        if (JsonUtility.ToJson(result) != json) throw new Exception("Scene data round trip failed.");
        var invalid = JsonUtility.FromJson<SceneSaveWrapper>(json);
        invalid.blocks[0].shapeType = 99;
        bool rejected = false;
        try { loader.ParseAndValidate(JsonUtility.ToJson(invalid)); } catch (ArgumentException) { rejected = true; }
        if (!rejected) throw new Exception("Invalid scene accepted.");
        Debug.Log("BLOCKLAB_SERIALIZATION_CHECK_PASSED: five shape records and invalid-shape rejection.");
    }
}
