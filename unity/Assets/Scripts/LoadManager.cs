using UnityEngine;
using System.Collections.Generic;

public class LoadManager : MonoBehaviour
{
    [Header("Block Prefabs")]
    [Tooltip("Drag your block prefabs here. Make sure the order matches your ShapeType enum!")]
    public GameObject[] blockPrefabs;

    [Header("UI Reference")]
    public HierarchyManager hierarchyManager; 

    public void LoadBuildFromJson(string jsonString)
    {
        ClearScene("");

        if (string.IsNullOrEmpty(jsonString))
        {
            Debug.Log("No save data provided. Starting a fresh build.");
            return;
        }

        Debug.Log("Loading build from Flutter: " + jsonString);

        // 1. Convert the JSON text back into our Save Wrapper object
        SceneSaveWrapper wrapper = JsonUtility.FromJson<SceneSaveWrapper>(jsonString);

        if (wrapper == null || wrapper.blocks == null) return;

        // 2. Loop through every saved block
        foreach (BlockSaveData data in wrapper.blocks)
        {
            // Safety check: do we have a prefab for this shape type?
            if (data.shapeType < 0 || data.shapeType >= blockPrefabs.Length) 
            {
                Debug.LogWarning("Shape type " + data.shapeType + " is missing from the LoadManager array!");
                continue;
            }

           // 3. Spawn the block (Using prefab rotation to prevent the 90-degree bug!)
            GameObject prefabToSpawn = blockPrefabs[data.shapeType];
            GameObject newBlock = Instantiate(prefabToSpawn, data.position, prefabToSpawn.transform.rotation);
            newBlock.name = data.blockName;

            // 4. Restore the block's size and color
            BlockData blockComponent = newBlock.GetComponent<BlockData>();
            if (blockComponent != null)
            {
                blockComponent.SetColor(data.color);
                blockComponent.widthOrRadius = data.widthOrRadius;
                blockComponent.height = data.height;
                blockComponent.length = data.length;
                blockComponent.ApplyDimensions();
                newBlock.transform.position = data.position;
            }

            // 5. Add it back to the Hierarchy UI list!
            if (hierarchyManager != null)
            {
                hierarchyManager.AddBlockToList(newBlock);
            }
        }
    }

public void ClearScene(string emptyMessage)
    {
        // 1. Destroy all the 3D blocks in the world
        GameObject[] existingBlocks = GameObject.FindGameObjectsWithTag("Block");
        foreach (GameObject block in existingBlocks)
        {
            Destroy(block);
        }

        if (hierarchyManager != null)
        {
            hierarchyManager.ClearHierarchyUI();
            Debug.Log("Hierarchy UI cleared!");
        }
        else
        {
            Debug.LogWarning("Hierarchy Manager is not linked in the Inspector!");
        }
    }

    void OnApplicationFocus(bool hasFocus)
    {
        if (hasFocus)
        {
            Debug.Log("Unity application is now in focus.");
            SendToFlutter.Send("UNITY_READY"); 
        }
    }
}