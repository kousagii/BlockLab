using UnityEngine;
using UnityEngine.EventSystems;

public class SelectionManager : MonoBehaviour
{
    public PropertiesUIManager uiManager;
    public float floorHeight;
    public static bool isDraggingBlock;
    public BlockData SelectedBlock => _selectedBlock;
    private BlockData _selectedBlock,_grabbed;
    private Vector3 _startPosition,_offset;
    private Plane _dragPlane;
    private Vector2 _press;
    private float _tapSlop;
    private bool _dragMoved,_wasDirty;
    private int _startRevision,_ownEdits;
    public static bool UiBlocked;
    public static bool PictureMode;

    void Update() {
        if(UiBlocked || PictureMode || CameraHandler.IsCameraLocked)return;
        if(Input.touchCount>1){CancelDrag();return;}
        if(Input.GetMouseButtonDown(0) && !OverUI()) {
            if(Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition),out var hit) &&
                hit.collider.GetComponentInParent<BlockData>() is BlockData block && !block.IsPreview)
                BeginPointerBlock(block,hit.point,Input.mousePosition);
        }
        if(Input.GetMouseButton(0))UpdatePointerBlock(Input.mousePosition);
        if(Input.GetMouseButtonUp(0))EndPointerBlock(OverUI());
    }
    public void BeginPointerBlock(BlockData block,Vector3 hitPoint,Vector2 pointer) {
        if(block==null || block.IsPreview || UiBlocked || PictureMode)return;
        _grabbed=block;_startPosition=block.transform.position;
        _dragPlane=new Plane(Vector3.up,hitPoint);_offset=block.transform.position-hitPoint;
        _press=pointer;_dragMoved=false;isDraggingBlock=true;
        var canvas=FindObjectOfType<SandboxUIController>()?.canvas;
        _tapSlop=8*(canvas!=null?canvas.scaleFactor:1);
        _wasDirty=WorkspaceState.Dirty;_startRevision=WorkspaceState.Revision;_ownEdits=0;
        // Defer opening the inspector until release distinguishes a tap from a drag.
    }
    public void UpdatePointerBlock(Vector2 pointer) {
        if(_grabbed==null)return;
        if(!_dragMoved && Vector2.Distance(_press,pointer)>_tapSlop) {
            _dragMoved=true;SelectWithoutProperties(_grabbed);
        }
        if(!_dragMoved)return;
        var ray=Camera.main.ScreenPointToRay(pointer);
        if(!_dragPlane.Raycast(ray,out float distance))return;
        var point=ray.GetPoint(distance)+_offset;
        var before=_grabbed.transform.position;
        if(BlockPlacement.TryPlace(_grabbed,point,Mathf.Max(floorHeight,-_dragPlane.distance)+1.5f,floorHeight)) {
            if(before!=_grabbed.transform.position){WorkspaceState.Edit();_ownEdits++;}
        } else FindObjectOfType<SandboxUIController>()?.ShowHint("No room here. Choose a flat surface or use Move.");
    }
    public void EndPointerBlock(bool releasedOverUI=false) {
        if(_grabbed==null)return;
        if(releasedOverUI){CancelDrag();return;}
        var tapped=_dragMoved?null:_grabbed;
        FinishDrag();
        if(tapped!=null)ForceSelectBlock(tapped);
    }
    // Used by Save/Undo as well as pointer release: it never opens properties.
    public void FinishDrag() {
        if(_grabbed!=null && _grabbed.transform.position!=_startPosition)
            UndoManager.Instance?.RecordCommand(new MoveCommand(_grabbed.transform,_startPosition));
        _grabbed=null;isDraggingBlock=false;_dragMoved=false;
    }
    public void CancelDrag() {
        if(_grabbed!=null) {
            _grabbed.transform.position=_startPosition;Physics.SyncTransforms();
            if(!_wasDirty && WorkspaceState.Revision==_startRevision+_ownEdits)WorkspaceState.Saved(WorkspaceState.Revision);
        }
        _grabbed=null;isDraggingBlock=false;_dragMoved=false;
    }
    public void ForceSelectBlock(BlockData block) { Select(block,true); }
    public void SelectWithoutProperties(BlockData block) { Select(block,false); }
    void Select(BlockData block,bool openProperties) {
        if(block==null)return;
        if(_selectedBlock!=null && _selectedBlock!=block)SetOutline(_selectedBlock,false);
        if(!openProperties)uiManager?.ClosePanel();
        _selectedBlock=block;SetOutline(block,true);
        if(openProperties)uiManager?.OpenPanel(block);
    }
    static void SetOutline(BlockData block,bool enabled) {
        var outline=block.GetComponent<Outline>();if(outline!=null)outline.enabled=enabled;
    }
    public void DeselectCurrent() {
        CancelDrag();FindObjectOfType<MoveGizmo>()?.Cancel();
        if(_selectedBlock!=null)SetOutline(_selectedBlock,false);
        _selectedBlock=null;uiManager?.ClosePanel();
    }
    public void RefreshSelection() {
        CancelDrag();
        if(_selectedBlock==null || !_selectedBlock.gameObject.activeInHierarchy)DeselectCurrent();
        else if(uiManager!=null && uiManager.propertiesPanel.activeSelf)uiManager.OpenPanel(_selectedBlock);
    }
    static bool OverUI() {
        if(EventSystem.current==null)return false;
        for(int i=0;i<Input.touchCount;i++)
            if(EventSystem.current.IsPointerOverGameObject(Input.GetTouch(i).fingerId))return true;
        return EventSystem.current.IsPointerOverGameObject();
    }
}
