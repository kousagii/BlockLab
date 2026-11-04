using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;

[System.Serializable]
public class SceneSaveWrapper 
{
    public string messageType = "SAVE_BUILD"; 
    public string imageBase64; 
    public List<BlockSaveData> blocks = new List<BlockSaveData>();
}

[System.Serializable]
public class BlockSaveData 
{
    public string blockName;
    public int shapeType; 
    public Vector3 position;
    public Color color;
    public float widthOrRadius;
    public float height;
    public float length;
}

public class SaveManager : MonoBehaviour
{
    [Header("UI Reference")]
    public GameObject mainUiCanvas; 

    public void ClickSaveBuild()
    {
        StartCoroutine(CaptureScreenshotAndSave());
    }

    private IEnumerator CaptureScreenshotAndSave()
    {

        if (mainUiCanvas != null)
        {
            mainUiCanvas.SetActive(false);
        }
        yield return new WaitForEndOfFrame();
        int width = Screen.width;
        int height = Screen.height;
        Texture2D tex = new Texture2D(width, height, TextureFormat.RGB24, false);
        tex.ReadPixels(new Rect(0, 0, width, height), 0, 0);
        tex.Apply();
        if (mainUiCanvas != null)
        {
            mainUiCanvas.SetActive(true);
        }
        byte[] imageBytes = tex.EncodeToJPG(50);
        Destroy(tex);
        string base64Image = Convert.ToBase64String(imageBytes);

        SceneSaveWrapper wrapper = new SceneSaveWrapper();
        wrapper.imageBase64 = base64Image;

        BlockData[] allBlocks = FindObjectsOfType<BlockData>();
        foreach (BlockData block in allBlocks)
        {
            BlockSaveData data = new BlockSaveData();
            data.blockName = block.gameObject.name;
            data.shapeType = (int)block.shapeType; 
            data.position = block.transform.position;
            data.color = block.blockColor;
            data.widthOrRadius = block.widthOrRadius;
            data.height = block.height;
            data.length = block.length;

            wrapper.blocks.Add(data);
        }

        string jsonString = JsonUtility.ToJson(wrapper);

        Debug.Log("Exporting clean thumbnail to Flutter!");
        SendToFlutter.Send(jsonString);
    }
}