using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class UIDragItem : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
{
    public GameObject blockPrefab;
    public HierarchyManager hierarchyManager;
    public SelectionManager selectionManager;
    public ScrollRect scrollParent;
    public float floorHeight, yOffset;
    private GameObject _preview;
    private Camera _camera;
    private Material _original, _ghost;
    private bool _valid, _scrolling;
    private static int _count;
    void Start() { _camera=Camera.main; }
    public void OnBeginDrag(PointerEventData data)
    {
        var delta=data.position-data.pressPosition;
        if(scrollParent!=null && Mathf.Abs(delta.y)>Mathf.Abs(delta.x))
        { CameraHandler.IsCameraLocked=true;_scrolling=true;scrollParent.OnBeginDrag(data);return; }
        if(_camera==null || blockPrefab==null || FindObjectsOfType<BlockData>().Length>=2000)return;
        CameraHandler.IsCameraLocked=true;_valid=false;
        _preview=Instantiate(blockPrefab);
        var identity=_preview.GetComponent<BlockData>();
        if(identity!=null){identity.blockId=null;identity.EnsureIdentity();identity.IsPreview=true;}
        foreach(var col in _preview.GetComponentsInChildren<Collider>()) col.enabled=false;
        _preview.name=blockPrefab.name+" "+(++_count);
        var renderer=_preview.GetComponentInChildren<Renderer>();
        if(renderer!=null){
            _original=renderer.material;_ghost=new Material(_original);
            var color=_ghost.color;color.a=.5f;_ghost.color=color;renderer.material=_ghost;
        }
        FindObjectOfType<SandboxUIController>()?.BeginPaletteDrag();
    }
    public void OnDrag(PointerEventData data)
    {
        if(_scrolling){scrollParent.OnDrag(data);return;}
        if(_preview==null)return;
        _valid=false;
        if(data.position.x<0 || data.position.y<0 || data.position.x>Screen.width || data.position.y>Screen.height)return;
        var plane=new Plane(Vector3.up,new Vector3(0,floorHeight,0));
        if(!plane.Raycast(_camera.ScreenPointToRay(data.position),out float distance))return;
        var point=_camera.ScreenPointToRay(data.position).GetPoint(distance);
        float x=Mathf.Round(point.x),z=Mathf.Round(point.z),y=floorHeight+yOffset;
        _valid=true;
        if(Physics.Raycast(new Vector3(x,100,z),Vector3.down,out var hit)){
            _valid=hit.normal.y>.99f;y=hit.point.y+yOffset;
        }
        _preview.transform.position=new Vector3(x,y,z);
    }
    public void OnEndDrag(PointerEventData data)
    {
        if(_scrolling){scrollParent.OnEndDrag(data);_scrolling=false;CameraHandler.IsCameraLocked=false;return;}
        CameraHandler.IsCameraLocked=false;
        var ui=FindObjectOfType<SandboxUIController>();
        if(_preview==null){ui?.EndPaletteDrag();return;}
        var hits=new List<RaycastResult>();
        if(EventSystem.current!=null)EventSystem.current.RaycastAll(data,hits);
        if(!_valid || hits.Count>0){Cancel();return;}
        var placed=_preview;_preview=null; // Opening properties can disable this palette item.
        foreach(var col in placed.GetComponentsInChildren<Collider>())col.enabled=true;
        var renderer=placed.GetComponentInChildren<Renderer>();if(renderer!=null)renderer.material=_original;
        var block=placed.GetComponent<BlockData>();if(block!=null)block.IsPreview=false;
        if(_ghost!=null)Destroy(_ghost);
        hierarchyManager?.AddBlockToList(placed);
        UndoManager.Instance?.RecordCommand(new UndoManager.AddCommand(placed,hierarchyManager));
        ui?.EndPaletteDrag();
        if(block!=null)selectionManager?.ForceSelectBlock(block);
    }
    private void Cancel()
    {
        CameraHandler.IsCameraLocked=false;
        if(_preview!=null)Destroy(_preview);
        if(_ghost!=null)Destroy(_ghost);
        _preview=null;_scrolling=false;
        FindObjectOfType<SandboxUIController>()?.EndPaletteDrag();
    }
    void OnDisable(){Cancel();}
}
