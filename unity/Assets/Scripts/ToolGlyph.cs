using UnityEngine;
using UnityEngine.UI;
[RequireComponent(typeof(CanvasRenderer))]
public class ToolGlyph : MaskableGraphic
{
    public bool collapse;
    protected override void OnPopulateMesh(VertexHelper mesh) {
        mesh.Clear();
        if(collapse) { Line(mesh,new Vector2(.65f,.25f),new Vector2(.35f,.5f));Line(mesh,new Vector2(.35f,.5f),new Vector2(.65f,.75f)); }
        else for(int i=0;i<3;i++) {
            float y=.25f+i*.25f;
            Line(mesh,new Vector2(.16f,y),new Vector2(.24f,y));
            Line(mesh,new Vector2(.4f,y),new Vector2(.88f,y));
        }
    }
    void Line(VertexHelper mesh,Vector2 a,Vector2 b) {
        var r=rectTransform.rect;
        a=new Vector2(r.x+a.x*r.width,r.y+a.y*r.height);b=new Vector2(r.x+b.x*r.width,r.y+b.y*r.height);
        var normal=(b-a).normalized;normal=new Vector2(-normal.y,normal.x)*1.1f;
        int i=mesh.currentVertCount;
        foreach(var p in new[]{a-normal,a+normal,b+normal,b-normal})mesh.AddVert(p,color,Vector2.zero);
        mesh.AddTriangle(i,i+1,i+2);mesh.AddTriangle(i,i+2,i+3);
    }
}
