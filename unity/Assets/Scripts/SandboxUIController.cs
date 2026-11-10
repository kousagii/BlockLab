using System;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class SandboxUIController : MonoBehaviour
{
    public Canvas canvas;
    public RectTransform safeRoot, rail, drawer, properties;
    public CanvasGroup drawerGroup;
    public GameObject shapesContent, objectsContent;
    public TMP_Text drawerTitle;
    public Button shapesButton, objectsButton;
    public GameObject emptyObjects;
    public PropertiesUIManager propertiesManager;
    private bool _dark, _drawerOpen, _objects, _statePending, _toolsCollapsed;
    private float _textScale=1, _pixelRatio;
    private int _width, _height;
    public bool IsDark => _dark;
    public bool DrawerOpen => _drawerOpen;
    public float TextScale => _textScale;
    [Serializable] private class Appearance { public string mode; public float textScale=1; public float pixelRatio; }
    [Serializable] private class State { public string messageType="WORKSPACE_STATE"; public string sessionId; public bool dirty; public bool canUndo; public int revision; }
    void OnEnable() { WorkspaceState.Changed += QueueState; }
    void OnDisable() { WorkspaceState.Changed -= QueueState; }
    void Start() { ApplyTheme(); Layout(); }
    void LateUpdate()
    {
        if (_width!=Screen.width || _height!=Screen.height) Layout();
        if (_statePending) { _statePending=false; PublishState(); }
    }
    private void QueueState() { _statePending=true; }
    public void SetAppearance(string json)
    {
        var appearance=JsonUtility.FromJson<Appearance>(json);
        if (appearance==null) return;
        _dark=appearance.mode=="dark";
        _textScale=Mathf.Clamp(appearance.textScale,1,2.5f);
        _pixelRatio=Mathf.Clamp(appearance.pixelRatio,.5f,6);
        ApplyTheme(); Layout();
    }
    private void ApplyTheme()
    {
        var plane=GameObject.Find("Plane");
        if(plane!=null) {
            var material=plane.GetComponent<Renderer>().material;
            if(material.HasProperty("_Background"))material.SetColor("_Background",SandboxStyle.Hex(_dark ? "101A2B" : "E8EEF8"));
            if(material.HasProperty("_Line"))material.SetColor("_Line",SandboxStyle.Hex(_dark ? "405572" : "9FAEC4"));
        }
        if(Camera.main!=null)Camera.main.backgroundColor=SandboxStyle.Hex(_dark ? "101A2B" : "E8EEF8");
        foreach(var style in canvas.GetComponentsInChildren<SandboxStyle>(true)) style.Apply(_dark,_textScale);
        foreach(var drag in canvas.GetComponentsInChildren<UIDragItem>(true))
        {
            var layout=drag.GetComponent<LayoutElement>();
            if(layout!=null) layout.preferredHeight=64*Mathf.Max(1,_textScale*.8f);
        }
        foreach(var item in objectsContent.GetComponentsInChildren<Button>(true)) StyleHierarchyItem(item.gameObject);
        UpdateRail();
    }
    public void Layout()
    {
        _width=Screen.width; _height=Screen.height;
        var scaler=canvas.GetComponent<CanvasScaler>();
        scaler.uiScaleMode=CanvasScaler.ScaleMode.ConstantPixelSize;
        scaler.scaleFactor=_pixelRatio>0 ? _pixelRatio : Mathf.Max(.5f,Screen.width/390f);
        Canvas.ForceUpdateCanvases();
        float width=((RectTransform)canvas.transform).rect.width;
        float height=((RectTransform)canvas.transform).rect.height;
        float railWidth=80+52*(Mathf.Min(_textScale,2.5f)-1);
        SetRect(rail,new Vector2(0,1),new Vector2(0,1),new Vector2(8,-244),new Vector2(8+railWidth,-12));
        foreach(var button in rail.GetComponentsInChildren<Button>(true)) {
            var element=button.GetComponent<LayoutElement>();
            if(element!=null)element.preferredHeight=68+32*(_textScale-1);
        }
        rail.offsetMin=new Vector2(8,-(244+96*(_textScale-1)));
        float drawerWidth=Mathf.Min(224, width-railWidth-32);
        bool largeText=width<450 && _textScale>1.4f;
        if(largeText) drawerWidth=width-16;
        float left=largeText ? 8 : railWidth+16;
        SetRect(drawer,Vector2.zero,Vector2.one,new Vector2(left,12),new Vector2(-(width-left-drawerWidth),-12));
        float header=60*_textScale;
        drawerTitle.rectTransform.offsetMin=new Vector2(16,-header);
        drawerTitle.rectTransform.offsetMax=new Vector2(-64,-8);
        foreach(var scroll in drawer.GetComponentsInChildren<ScrollRect>(true))
            ((RectTransform)scroll.transform).offsetMax=new Vector2(-12,-(header+8));
        var close=drawer.Find("CloseDrawer").GetComponent<RectTransform>();
        close.offsetMin=new Vector2(-60,-header);close.offsetMax=new Vector2(-8,-8);
        bool wide=width>650 && width>height;
        if(wide) SetRect(properties,new Vector2(1,0),Vector2.one,new Vector2(-360,12),new Vector2(-12,-12));
        else SetRect(properties,Vector2.zero,new Vector2(1,0),new Vector2(8,12),new Vector2(-8,12+Mathf.Min(350,height*.52f)));
        propertiesManager.blockNameLabel.rectTransform.offsetMin=new Vector2(16,-header);
        var propertyScroll=properties.GetComponentInChildren<ScrollRect>(true);
        ((RectTransform)propertyScroll.transform).offsetMax=new Vector2(-12,-(header+4));
        rail.gameObject.SetActive(!_toolsCollapsed && !(largeText && _drawerOpen));
        foreach(var element in canvas.GetComponentsInChildren<SandboxRowSize>(true)) {
            element.Apply(_textScale);
            var labels=element.GetComponentsInChildren<TMP_Text>();
            if(labels.Length==2) {
                labels[0].rectTransform.offsetMin=new Vector2(0,-40*_textScale);
                labels[0].rectTransform.offsetMax=new Vector2(-56*_textScale,0);
                labels[1].rectTransform.offsetMin=new Vector2(-56*_textScale,-40*_textScale);
            }
        }
        Canvas.ForceUpdateCanvases();
    }
    private static void SetRect(RectTransform rect,Vector2 min,Vector2 max,Vector2 offsetMin,Vector2 offsetMax)
    { rect.anchorMin=min;rect.anchorMax=max;rect.offsetMin=offsetMin;rect.offsetMax=offsetMax; }
    public void ToggleShapes() { ToggleDrawer(false); }
    public void ToggleObjects() { ToggleDrawer(true); }
    private void ToggleDrawer(bool objects)
    {
        _drawerOpen=!(_drawerOpen && _objects==objects); _objects=objects;
        if(_drawerOpen) properties.gameObject.SetActive(false);
        drawer.gameObject.SetActive(_drawerOpen);
        shapesContent.transform.parent.gameObject.SetActive(!objects);
        objectsContent.transform.parent.gameObject.SetActive(objects);
        drawerTitle.text=objects ? "Objects" : "Shapes";
        emptyObjects.SetActive(_drawerOpen && objects && GetComponent<HierarchyManager>().Count==0);
        UpdateRail(); Layout();
    }
    public void CloseDrawer() { _drawerOpen=false; drawer.gameObject.SetActive(false); UpdateRail(); Layout(); }
    public void CollapseTools() { _toolsCollapsed=true; FindButton("OpenTools").gameObject.SetActive(true); CloseDrawer(); }
    public void ExpandTools() { _toolsCollapsed=false; FindButton("OpenTools").gameObject.SetActive(false); Layout(); }
    private Button FindButton(string name) { foreach(var b in canvas.GetComponentsInChildren<Button>(true)) if(b.name==name)return b; return null; }
    public void ShowProperties() { CloseDrawer(); properties.gameObject.SetActive(true); }
    public void CloseProperties() { FindObjectOfType<SelectionManager>()?.DeselectCurrent(); }
    public void RequestUndo(string unused) { UndoManager.Instance?.ClickUndo(); }
    public void ResetView(string unused) { Camera.main?.GetComponent<CameraHandler>()?.ResetView(); }
    public void BeginPaletteDrag() { drawerGroup.alpha=.12f;drawerGroup.blocksRaycasts=false; }
    public void EndPaletteDrag() { drawerGroup.alpha=1;drawerGroup.blocksRaycasts=true; }
    private void UpdateRail()
    {
        Color idle=SandboxStyle.Hex(_dark ? "172338" : "FFFFFF");
        Color selected=SandboxStyle.Hex(_dark ? "29436B" : "E0EAFF");
        shapesButton.image.color=_drawerOpen&&!_objects ? selected : idle;
        objectsButton.image.color=_drawerOpen&&_objects ? selected : idle;
    }
    public void StyleHierarchyItem(GameObject item)
    {
        foreach(var style in item.GetComponentsInChildren<SandboxStyle>(true)) style.Apply(_dark,_textScale);
        var element=item.GetComponent<LayoutElement>(); if(element!=null)element.preferredHeight=64*_textScale;
    }
    public void PublishState()
    {
        if(emptyObjects!=null) emptyObjects.SetActive(_drawerOpen && _objects && GetComponent<HierarchyManager>().Count==0);
        var loader=GetComponent<LoadManager>();
        if(loader==null || string.IsNullOrEmpty(loader.SessionId)) return;
        SendToFlutter.Send(JsonUtility.ToJson(new State{sessionId=loader.SessionId,dirty=WorkspaceState.Dirty,
            canUndo=UndoManager.Instance!=null&&UndoManager.Instance.CanUndo,revision=WorkspaceState.Revision}));
    }
}
