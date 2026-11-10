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
    private bool _dragMoved;
    public static bool UiBlocked;
    void Update() {
        if(UiBlocked || CameraHandler.IsCameraLocked)return;
        if(Input.touchCount>1){CancelDrag();return;}
        if(Input.GetMouseButtonDown(0) && !OverUI()) {
            if(Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition),out var hit) &&
                hit.collider.GetComponentInParent<BlockData>() is BlockData block && !block.IsPreview) {
                ForceSelectBlock(block);_grabbed=block;_startPosition=block.transform.position;
                _dragPlane=new Plane(Vector3.up,hit.point);_offset=block.transform.position-hit.point;
                _press=Input.mousePosition;_dragMoved=false;isDraggingBlock=true;
            }
        }
        if(Input.GetMouseButton(0) && _grabbed!=null) {
            if(Vector2.Distance(_press,Input.mousePosition)>8)_dragMoved=true;
            if(_dragMoved && _dragPlane.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition),out float distance)) {
                var point=Camera.main.ScreenPointToRay(Input.mousePosition).GetPoint(distance)+_offset;
                var old=_grabbed.transform.position;
                if(BlockPlacement.TryPlace(_grabbed,point,Mathf.Max(floorHeight,_dragPlane.distance*-1)+1.5f,floorHeight)) {
                    if(old!=_grabbed.transform.position)WorkspaceState.Edit();
                } else FindObjectOfType<SandboxUIController>()?.ShowHint("No room here. Choose a flat surface or use Move.");
            }
        }
        if(Input.GetMouseButtonUp(0))FinishDrag();
    }
    public void FinishDrag() {
        if(_grabbed!=null && _grabbed.transform.position!=_startPosition)
            UndoManager.Instance?.RecordCommand(new MoveCommand(_grabbed.transform,_startPosition));
        _grabbed=null;isDraggingBlock=false;_dragMoved=false;
    }
    public void CancelDrag() {
        if(_grabbed!=null){_grabbed.transform.position=_startPosition;Physics.SyncTransforms();}
        _grabbed=null;isDraggingBlock=false;_dragMoved=false;
    }
    public void ForceSelectBlock(BlockData block) {
        if(block==null)return;
        if(_selectedBlock!=null && _selectedBlock!=block)SetOutline(_selectedBlock,false);
        _selectedBlock=block;SetOutline(block,true);uiManager?.OpenPanel(block);
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
        else uiManager?.OpenPanel(_selectedBlock);
    }
    static bool OverUI() {
        if(EventSystem.current==null)return false;
        for(int i=0;i<Input.touchCount;i++)
            if(EventSystem.current.IsPointerOverGameObject(Input.GetTouch(i).fingerId))return true;
        return EventSystem.current.IsPointerOverGameObject();
    }
}
