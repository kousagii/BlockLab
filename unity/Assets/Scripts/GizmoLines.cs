using UnityEngine;
using UnityEngine.UI;
[RequireComponent(typeof(CanvasRenderer))]
public class GizmoLines : MaskableGraphic
{
    public Vector2 origin;
    public Button[] handles;
    protected override void OnPopulateMesh(VertexHelper mesh) {
        mesh.Clear();if(handles==null)return;
        for(int axis=0;axis<handles.Length;axis++) {
            Vector2 end=handles[axis].GetComponent<RectTransform>().anchoredPosition;
            var delta=(end-origin).normalized;var normal=new Vector2(-delta.y,delta.x)*1.8f;
            int index=mesh.currentVertCount;Color tint=handles[axis].image.color;
            foreach(var p in new[]{origin-normal,origin+normal,end+normal,end-normal})mesh.AddVert(p,tint,Vector2.zero);
            mesh.AddTriangle(index,index+1,index+2);mesh.AddTriangle(index,index+2,index+3);
        }
    }
}
