using UnityEngine;
using UnityEngine.UI;

// Small code-native shape illustrations: no extra font/icon family or texture downloads.
[RequireComponent(typeof(CanvasRenderer))]
public class ShapeGlyph : MaskableGraphic
{
    public BlockShapeType shape;
    private VertexHelper _mesh;
    protected override void OnPopulateMesh(VertexHelper mesh)
    {
        mesh.Clear(); _mesh = mesh;
        switch (shape)
        {
            case BlockShapeType.Cube:
                Path(new[]{ P(.15f,.3f), P(.5f,.12f), P(.85f,.3f), P(.85f,.72f), P(.5f,.9f), P(.15f,.72f)}, true);
                Line(P(.15f,.72f),P(.5f,.52f)); Line(P(.85f,.72f),P(.5f,.52f)); Line(P(.5f,.52f),P(.5f,.12f)); break;
            case BlockShapeType.TriangularPrism:
                Path(new[]{P(.12f,.15f),P(.38f,.78f),P(.64f,.15f)},true);
                Path(new[]{P(.38f,.78f),P(.65f,.9f),P(.91f,.3f),P(.64f,.15f)},false);
                Line(P(.12f,.15f),P(.39f,.3f)); Line(P(.39f,.3f),P(.91f,.3f)); break;
            case BlockShapeType.Cylinder:
                Ellipse(.5f,.75f,.35f,.13f); Line(P(.15f,.75f),P(.15f,.25f)); Line(P(.85f,.75f),P(.85f,.25f));
                Arc(.5f,.25f,.35f,.13f,Mathf.PI,Mathf.PI*2); break;
            case BlockShapeType.Trapezoid:
                Path(new[]{P(.1f,.18f),P(.3f,.76f),P(.67f,.76f),P(.87f,.18f)},true);
                Path(new[]{P(.3f,.76f),P(.43f,.9f),P(.8f,.9f),P(.67f,.76f)},false);
                Path(new[]{P(.8f,.9f),P(.97f,.33f),P(.87f,.18f)},false); break;
            case BlockShapeType.HalfCylinder:
                Arc(.39f,.2f,.29f,.52f,0,Mathf.PI); Line(P(.1f,.2f),P(.68f,.2f));
                Arc(.61f,.35f,.29f,.52f,0,Mathf.PI); Line(P(.68f,.2f),P(.9f,.35f)); break;
        }
    }
    private Vector2 P(float x,float y) { var r=rectTransform.rect; return new Vector2(r.x+x*r.width,r.y+y*r.height); }
    private void Path(Vector2[] points,bool close) { for(int i=1;i<points.Length;i++) Line(points[i-1],points[i]); if(close) Line(points[points.Length-1],points[0]); }
    private void Ellipse(float x,float y,float w,float h) { Arc(x,y,w,h,0,Mathf.PI*2); }
    private void Arc(float x,float y,float w,float h,float start,float end)
    {
        Vector2 previous=P(x+Mathf.Cos(start)*w,y+Mathf.Sin(start)*h);
        for(int i=1;i<=24;i++) { float a=Mathf.Lerp(start,end,i/24f); var next=P(x+Mathf.Cos(a)*w,y+Mathf.Sin(a)*h); Line(previous,next); previous=next; }
    }
    private void Line(Vector2 from,Vector2 to)
    {
        var normal=(to-from).normalized; normal=new Vector2(-normal.y,normal.x)*1.1f;
        int i=_mesh.currentVertCount;
        foreach(var p in new[]{from-normal,from+normal,to+normal,to-normal}) _mesh.AddVert(p,color,Vector2.zero);
        _mesh.AddTriangle(i,i+1,i+2); _mesh.AddTriangle(i,i+2,i+3);
    }
}
