using UnityEngine;
using UnityEngine.UI;
using TMPro;
using UnityEngine.EventSystems;

// Runtime world-axis handles drawn on the existing Canvas, never stored as blocks.
public class MoveGizmo : MonoBehaviour
{
    public SelectionManager selection;
    public SandboxUIController ui;
    public RectTransform root;
    public Button[] handles;
    public TMP_Text status;
    private readonly Vector2[] _directions=new Vector2[3];
    private BlockData _block;
    private Vector3 _start;
    private Vector2 _pointerStart,_direction;
    private float _unitsPerPixel;
    private int _axis=-1;
    private bool _changed;
    private bool _wasDirty;
    private int _startRevision,_ownEdits;
    private WorkspaceSnapshotCommand _snapshot;
    public bool IsManipulating => _axis>=0;
    public bool Visible => root!=null && root.gameObject.activeSelf;
    public Vector2 ScreenDeltaForUnits(int axis,float units) {
        var center=BlockPlacement.BoundsOf(selection.SelectedBlock).center;
        var a=Camera.main.WorldToScreenPoint(center);var b=Camera.main.WorldToScreenPoint(center+Axis(axis));
        float projected=Vector2.Distance(a,b);
        if(projected<15)projected=Screen.height/(2*Mathf.Max(.1f,a.z)*Mathf.Tan(Camera.main.fieldOfView*Mathf.Deg2Rad*.5f));
        return _directions[axis]*projected*units;
    }
    static Vector3 Axis(int axis) => axis==0?Vector3.right:axis==1?Vector3.up:Vector3.forward;
    void LateUpdate() {
        if(IsManipulating && Input.touchCount>1)Cancel();
        bool visible=selection.SelectedBlock!=null && (ui.MoveMode || IsManipulating) && !SelectionManager.UiBlocked;
        root.gameObject.SetActive(visible);
        if(!visible){if(IsManipulating)Cancel();return;}
        var block=selection.SelectedBlock;var camera=Camera.main;
        var center=BlockPlacement.BoundsOf(block).center;
        var screen=camera.WorldToScreenPoint(center);
        if(screen.z<=camera.nearClipPlane){root.gameObject.SetActive(false);return;}
        RectTransformUtility.ScreenPointToLocalPointInRectangle(root,screen,null,out var origin);
        float scale=ui.canvas.scaleFactor;
        for(int axis=0;axis<3;axis++) {
            var projected=camera.WorldToScreenPoint(center+Axis(axis));
            Vector2 direction=(Vector2)(projected-screen);
            if(direction.magnitude<15)direction=axis==1?Vector2.up:axis==0?Vector2.right:new Vector2(-.7f,-.7f);
            direction.Normalize();_directions[axis]=direction;
            var rect=handles[axis].GetComponent<RectTransform>();
            var endpoint=origin+direction*96;
            endpoint.x=Mathf.Clamp(endpoint.x,root.rect.xMin+24,root.rect.xMax-24);
            endpoint.y=Mathf.Clamp(endpoint.y,root.rect.yMin+24,root.rect.yMax-24);
            rect.anchoredPosition=endpoint;
        }
        var lines=root.GetComponent<GizmoLines>();
        lines.origin=origin;lines.handles=handles;lines.SetVerticesDirty();
    }
    public void Begin(int axis,Vector2 pointer) {
        if(IsManipulating)Cancel();
        if(Input.touchCount>1)return;
        if(selection.SelectedBlock==null || SelectionManager.UiBlocked)return;
        _block=selection.SelectedBlock;_start=_block.transform.position;_snapshot=new WorkspaceSnapshotCommand();
        _axis=axis;_changed=false;_pointerStart=pointer;_direction=_directions[axis];
        _wasDirty=WorkspaceState.Dirty;_startRevision=WorkspaceState.Revision;_ownEdits=0;
        var camera=Camera.main;var center=BlockPlacement.BoundsOf(_block).center;
        var a=camera.WorldToScreenPoint(center);var b=camera.WorldToScreenPoint(center+Axis(axis));
        float projected=Vector2.Distance(a,b);
        float fallback=Screen.height/(2*Mathf.Max(.1f,a.z)*Mathf.Tan(camera.fieldOfView*Mathf.Deg2Rad*.5f));
        _unitsPerPixel=1/(projected<15?fallback:projected);
        CameraHandler.IsCameraLocked=true;SelectionManager.isDraggingBlock=true;
        status.text="Move "+("XYZ"[axis])+" · 1 unit snap";
    }
    public void Drag(Vector2 pointer) {
        if(_axis<0 || _block==null)return;
        if(Vector2.Distance(pointer,_pointerStart)>8*ui.canvas.scaleFactor && ui.properties.gameObject.activeSelf)
            selection.SelectWithoutProperties(_block);
        float delta=Mathf.Round(Vector2.Dot(pointer-_pointerStart,_direction)*_unitsPerPixel);
        var target=_start+Axis(_axis)*delta;
        var from=_block.transform.position;
        int steps=Mathf.Min(1000,Mathf.RoundToInt(Vector3.Distance(from,target)));bool blocked=false;
        var direction=(target-from).normalized;
        for(int unit=0;unit<steps;unit++) {
            var unitStart=_block.transform.position;
            for(int sample=1;sample<=10;sample++) {
                if(!BlockPlacement.TryMove(_block,unitStart+direction*(sample*.1f))) {
                    _block.transform.position=unitStart;Physics.SyncTransforms();blocked=true;break;
                }
            }
            if(blocked)break;
        }
        if(_block.transform.position!=from){_changed=true;WorkspaceState.Edit();_ownEdits++;}
        if(blocked){status.text="Movement blocked";ui.ShowHint("No room along this axis.");}
        else status.text="Move "+("XYZ"[_axis])+" · "+delta.ToString("0")+" units";
    }
    public void End() {
        if(_axis<0)return;
        if(_changed && _block!=null && _block.transform.position!=_start)UndoManager.Instance?.RecordCommand(_snapshot);
        Release();
    }
    public void Cancel() {
        if(_axis<0)return;
        if(_block!=null){_block.transform.position=_start;Physics.SyncTransforms();}
        if(!_wasDirty && WorkspaceState.Revision==_startRevision+_ownEdits)WorkspaceState.Saved(WorkspaceState.Revision);
        Release();
    }
    void Release() { _axis=-1;_block=null;_snapshot=null;CameraHandler.IsCameraLocked=false;SelectionManager.isDraggingBlock=false;if(status!=null)status.text="Drag X, Y, or Z to move. Use Y to lift a block."; }
    void OnDisable(){Cancel();}
}
