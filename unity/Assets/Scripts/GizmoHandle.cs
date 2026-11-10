using UnityEngine;
using UnityEngine.EventSystems;
public class GizmoHandle : MonoBehaviour, IPointerDownHandler, IBeginDragHandler, IDragHandler, IEndDragHandler, IPointerUpHandler
{
    public MoveGizmo gizmo;
    public int axis;
    public void OnPointerDown(PointerEventData data){gizmo.Begin(axis,data.position);}
    public void OnBeginDrag(PointerEventData data){}
    public void OnDrag(PointerEventData data){gizmo.Drag(data.position);}
    public void OnEndDrag(PointerEventData data){gizmo.End();}
    public void OnPointerUp(PointerEventData data){gizmo.End();}
}
