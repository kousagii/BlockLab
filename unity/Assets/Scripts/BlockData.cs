using UnityEngine;

public enum BlockShapeType { Cube, TriangularPrism, Cylinder, Trapezoid, HalfCylinder }

public class BlockData : MonoBehaviour
{
    public string blockId;
    [System.NonSerialized] public bool IsPreview;
    public BlockShapeType shapeType;
    public Transform meshChild;
    public float height=1, length=1, widthOrRadius=1;
    public Color blockColor=Color.white;
    public Material presentationMaterial;
    private MeshRenderer[] _renderers;
    private Collider[] _colliders;
    public MeshRenderer[] MeshRenderers { get { if(_renderers==null)_renderers=GetComponentsInChildren<MeshRenderer>(true);return _renderers; } }
    public Collider[] GeometryColliders { get { if(_colliders==null)_colliders=GetComponentsInChildren<Collider>(true);return _colliders; } }
    private float _lastWidth=1,_lastHeight=1,_lastLength=1;
    void Awake() { SetColor(blockColor); }
    public void EnsureIdentity() {
        if(string.IsNullOrEmpty(blockId))blockId=System.Guid.NewGuid().ToString("N");
    }
    public void RestoreDimensions(float width,float newHeight,float newLength) {
        widthOrRadius=width;height=newHeight;length=newLength;
        transform.localScale=shapeType==BlockShapeType.Cylinder ? new Vector3(width,newHeight,width) :
            shapeType==BlockShapeType.HalfCylinder ? new Vector3(width,newLength,newHeight) : new Vector3(width,newHeight,newLength);
        _lastWidth=width;_lastHeight=newHeight;_lastLength=newLength;
    }
    public bool TryResize(float width,float newHeight,float newLength) {
        foreach(var value in new[]{width,newHeight,newLength})
            if(float.IsNaN(value)||float.IsInfinity(value)||value<.1f||value>100)return false;
        return BlockPlacement.TryResize(this,width,newHeight,newLength);
    }
    // Compatibility entry point for older callers; failed edits restore the prior values.
    public void ApplyDimensions() {
        float w=widthOrRadius,h=height,l=length;
        RestoreDimensions(_lastWidth,_lastHeight,_lastLength);
        TryResize(w,h,l);
    }
    public void SetColor(Color newColor) {
        blockColor=newColor;
        foreach(var renderer in MeshRenderers) {
            if(presentationMaterial!=null)renderer.sharedMaterial=presentationMaterial;
            var properties=new MaterialPropertyBlock();renderer.GetPropertyBlock(properties);
            properties.SetColor("_Color",newColor);properties.SetColor("_BaseColor",newColor);
            renderer.SetPropertyBlock(properties);
        }
    }
}
