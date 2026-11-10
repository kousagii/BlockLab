using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

[Serializable]
public class SceneSaveWrapper
{
    public int schemaVersion;
    public string messageType = "SAVE_BUILD";
    public string sessionId;
    public string imageBase64;
    public int revision;
    public List<BlockSaveData> blocks;
}
[Serializable]
public class BlockSaveData
{
    public string blockId, blockName;
    public int shapeType;
    public Vector3 position;
    public Quaternion rotation;
    public Color color;
    public float widthOrRadius, height, length;
}
public class SaveManager : MonoBehaviour
{
    public GameObject mainUiCanvas;
    private bool _saving;
    [Serializable] private class SaveAcknowledgement { public string sessionId; public int revision; }
    public void AcknowledgeSave(string json) {
        var acknowledgement = JsonUtility.FromJson<SaveAcknowledgement>(json);
        if (acknowledgement != null && acknowledgement.sessionId == GetComponent<LoadManager>().SessionId)
            WorkspaceState.Saved(acknowledgement.revision);
    }
    public void RequestSave(string unused) { ClickSaveBuild(); }
    public static SceneSaveWrapper Capture()
    {
        var wrapper = new SceneSaveWrapper { schemaVersion = 2, revision = WorkspaceState.Revision, blocks = new List<BlockSaveData>() };
        foreach (var block in FindObjectsOfType<BlockData>())
        {
            if (block.IsPreview) continue;
            block.EnsureIdentity();
            wrapper.blocks.Add(new BlockSaveData {
                blockId = block.blockId, blockName = block.name, shapeType = (int)block.shapeType,
                position = block.transform.position, rotation = block.transform.rotation,
                color = block.blockColor, widthOrRadius = block.widthOrRadius,
                height = block.height, length = block.length
            });
        }
        return wrapper;
    }
    public void ClickSaveBuild()
    {
        GetComponent<MoveGizmo>()?.End();
        FindObjectOfType<SelectionManager>()?.FinishDrag();
        if (!_saving) StartCoroutine(CaptureScreenshotAndSave());
    }
    private IEnumerator CaptureScreenshotAndSave()
    {
        _saving = true;
        bool wasVisible = mainUiCanvas != null && mainUiCanvas.activeSelf;
        if (mainUiCanvas != null) mainUiCanvas.SetActive(false);
        yield return new WaitForEndOfFrame();
        Texture2D full = null, thumbnail = null;
        RenderTexture target = null;
        RenderTexture previous = RenderTexture.active;
        try
        {
            var wrapper = Capture();
            var loader = GetComponent<LoadManager>();
            wrapper.sessionId = loader != null ? loader.SessionId : "";
            full = ScreenCapture.CaptureScreenshotAsTexture();
            int width = Mathf.Min(384, full.width);
            int height = Mathf.Max(1, Mathf.RoundToInt(full.height * (width / (float)full.width)));
            target = RenderTexture.GetTemporary(width, height, 0);
            Graphics.Blit(full, target);
            RenderTexture.active = target;
            thumbnail = new Texture2D(width, height, TextureFormat.RGB24, false);
            thumbnail.ReadPixels(new Rect(0, 0, width, height), 0, 0);
            thumbnail.Apply();
            wrapper.imageBase64 = Convert.ToBase64String(thumbnail.EncodeToJPG(65));
            SendToFlutter.Send(JsonUtility.ToJson(wrapper));
        }
        catch (Exception error)
        {
            Debug.LogException(error);
            SendToFlutter.Send("{\"messageType\":\"ERROR\",\"message\":\"Could not capture this build. Try saving again.\"}");
        }
        finally
        {
            RenderTexture.active = previous;
            if (target != null) RenderTexture.ReleaseTemporary(target);
            if (full != null) Destroy(full);
            if (thumbnail != null) Destroy(thumbnail);
            if (mainUiCanvas != null) mainUiCanvas.SetActive(wasVisible);
            _saving = false;
        }
    }
}
