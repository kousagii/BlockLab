using UnityEngine;

public enum BlockShapeType { Cube, TriangularPrism, Cylinder, Trapezoid, HalfCylinder }

public class BlockData : MonoBehaviour
{
    public string blockId;
    [System.NonSerialized] public bool IsPreview;
    public void EnsureIdentity()
    {
        if (string.IsNullOrEmpty(blockId)) blockId = System.Guid.NewGuid().ToString("N");
    }

    public void RestoreDimensions(float width, float newHeight, float newLength)
    {
        widthOrRadius = width; height = newHeight; length = newLength;
        transform.localScale = shapeType == BlockShapeType.Cylinder
            ? new Vector3(width, newHeight, width)
            : shapeType == BlockShapeType.HalfCylinder
                ? new Vector3(width, newLength, newHeight) : new Vector3(width, newHeight, newLength);
        _lastWidth = width; _lastHeight = newHeight;
        _lastLength = shapeType == BlockShapeType.Cylinder ? width : newLength;
    }
    public BlockShapeType shapeType;
    public Transform meshChild; 

    [Header("Universal Dimensions")]
    public float height = 1f;
    public float length = 1f;

    [Header("Shape Specific Dimensions")]
    public float widthOrRadius = 1f; 

    [Header("Color Settings")]
    public Color blockColor = Color.white; 

    private float _lastWidth = 1f;
    private float _lastHeight = 1f; 
    private float _lastLength = 1f;

    public void SetColor(Color newColor)
    {
        blockColor = newColor;
        
        Renderer[] renderers = GetComponentsInChildren<Renderer>();
        foreach (Renderer ren in renderers)
        {
            ren.material.color = blockColor; 
        }
    }

    public void ApplyDimensions()
    {
        float w = Mathf.Max(0.1f, widthOrRadius);
        float h = Mathf.Max(0.1f, height);
        float l = Mathf.Max(0.1f, (shapeType == BlockShapeType.Cylinder) ? widthOrRadius : length);

        float differenceX = w - _lastWidth;
        float differenceY = h - _lastHeight; 
        float differenceZ = l - _lastLength; 

        Collider myCollider = GetComponentInChildren<Collider>();
        
        // --- NEW: Record the ENTIRE old bounding box before we change anything ---
        Bounds oldBounds = (myCollider != null) ? myCollider.bounds : new Bounds(transform.position, Vector3.one);
        float oldMaxY = oldBounds.max.y;

        switch (shapeType)
        {
            case BlockShapeType.Cube:
            case BlockShapeType.TriangularPrism:
            case BlockShapeType.Trapezoid:
                transform.localScale = new Vector3(w, h, l);
                break;
            case BlockShapeType.Cylinder:
                transform.localScale = new Vector3(w, h, w);
                break;
            case BlockShapeType.HalfCylinder:
                transform.localScale = new Vector3(w, l, h);
                break;
        }

        Vector3 depthDirection = transform.forward;
        if (shapeType == BlockShapeType.HalfCylinder)
        {
            depthDirection = transform.up; 
        }

        transform.position += transform.right * (differenceX / 2f) + depthDirection * (differenceZ / 2f);

        Physics.SyncTransforms();

        float newMaxY = (myCollider != null) ? myCollider.bounds.max.y : transform.position.y + h;
        float topSurfaceDifference = newMaxY - oldMaxY; 

        _lastWidth = w;
        _lastHeight = h;
        _lastLength = l;

        ResolveOverlaps(differenceX, differenceY, differenceZ, depthDirection, topSurfaceDifference, oldBounds); 
    }

    private void ResolveOverlaps(float diffX, float diffY, float diffZ, Vector3 depthDir, float topSurfaceDiff, Bounds oldBounds)
    {
        Collider myCollider = GetComponentInChildren<Collider>();
        if (myCollider == null) return;

        Physics.SyncTransforms();

        if (topSurfaceDiff < -0.01f)
        {
            Vector3 topBoxCenter = oldBounds.center;
            topBoxCenter.y = oldBounds.max.y + 0.1f; 
            
            Vector3 topBoxExtents = oldBounds.extents * 0.95f; 
            topBoxExtents.y = 0.2f; 

            Collider[] restingBlocks = Physics.OverlapBox(topBoxCenter, topBoxExtents, myCollider.transform.rotation);

            foreach (Collider other in restingBlocks)
            {
                if (other == myCollider || other.isTrigger) continue;

                BlockData otherBlock = other.GetComponentInParent<BlockData>();
                if (otherBlock != null)
                {
                    otherBlock.transform.position += Vector3.up * topSurfaceDiff; 
                }
            }
        }


        Vector3 halfExtents = myCollider.bounds.extents * 0.95f;
        Collider[] overlaps = Physics.OverlapBox(myCollider.bounds.center, halfExtents, myCollider.transform.rotation);

        foreach (Collider other in overlaps)
        {
            if (other == myCollider || other.isTrigger) continue;

            BlockData otherBlock = other.GetComponentInParent<BlockData>();
            
            if (otherBlock != null)
            {
                Vector3 dir = other.bounds.center - myCollider.bounds.center;
                Vector3 localDir = transform.InverseTransformDirection(dir);

                if (shapeType == BlockShapeType.HalfCylinder)
                {
                    float temp = localDir.y;
                    localDir.y = localDir.z; 
                    localDir.z = temp;       
                }

                float absX = Mathf.Abs(localDir.x);
                float absY = Mathf.Abs(localDir.y);
                float absZ = Mathf.Abs(localDir.z);

                Vector3 pushDir = Vector3.zero;

                if (absY >= absX && absY >= absZ && localDir.y > 0 && diffY > 0)
                {
                    pushDir = Vector3.up; 
                }
                else if (absX >= absY && absX >= absZ && localDir.x > 0 && diffX > 0)
                {
                    pushDir = transform.right;
                }
                else if (absZ >= absX && absZ >= absY && localDir.z > 0 && diffZ > 0)
                {
                    pushDir = depthDir;
                }

                if (pushDir != Vector3.zero)
                {
                    float pushDist = 0f;

                    if (Mathf.Abs(pushDir.y) > 0.5f) 
                        pushDist = myCollider.bounds.max.y - other.bounds.min.y;
                    else if (pushDir.x > 0.5f) 
                        pushDist = myCollider.bounds.max.x - other.bounds.min.x;
                    else if (pushDir.x < -0.5f) 
                        pushDist = other.bounds.max.x - myCollider.bounds.min.x;
                    else if (pushDir.z > 0.5f) 
                        pushDist = myCollider.bounds.max.z - other.bounds.min.z;
                    else if (pushDir.z < -0.5f) 
                        pushDist = other.bounds.max.z - myCollider.bounds.min.z;

                    if (pushDist > 0)
                    {
                        otherBlock.transform.position += pushDir * pushDist;
                    }
                }
            }
        }
    }
}
