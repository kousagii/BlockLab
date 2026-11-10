using System.Collections.Generic;
using System.Linq;
using UnityEngine;

// Editing-time geometry rules. Loading deliberately uses RestoreDimensions instead.
public static class BlockPlacement
{
    public const float Tolerance=.003f;
    public static Bounds BoundsOf(BlockData block) {
        var renderers=block.MeshRenderers;
        var bounds=new Bounds(block.transform.position,Vector3.zero);
        bool first=true;
        foreach(var renderer in renderers) {
            if(first){bounds=renderer.bounds;first=false;}else bounds.Encapsulate(renderer.bounds);
        }
        return bounds;
    }
    public static BlockData[] Blocks() => Object.FindObjectsOfType<BlockData>().Where(b=>!b.IsPreview).OrderBy(b=>b.GetInstanceID()).ToArray();
    public static bool Intersects(BlockData a,BlockData b) {
        if(!BoundsOf(a).Intersects(BoundsOf(b)))return false; // Broad phase only.
        foreach(var ca in a.GeometryColliders)
            foreach(var cb in b.GeometryColliders)
                if(!ca.isTrigger && !cb.isTrigger &&
                    Physics.ComputePenetration(ca,ca.transform.position,ca.transform.rotation,
                        cb,cb.transform.position,cb.transform.rotation,out var direction,out float distance) && distance>Tolerance)
                    return true;
        return false;
    }
    public static bool IsSupportedBy(BlockData top,BlockData bottom) {
        var upper=BoundsOf(top);var lower=BoundsOf(bottom);
        if(Mathf.Abs(upper.min.y-lower.max.y)>.025f)return false;
        foreach(var point in Samples(upper)) {
            var ray=new Ray(new Vector3(point.x,upper.min.y+.04f,point.z),Vector3.down);
            foreach(var collider in bottom.GeometryColliders)
                if(collider.Raycast(ray,out var hit,.08f) && hit.normal.y>.98f)return true;
        }
        return false;
    }
    static IEnumerable<Vector3> Samples(Bounds bounds) {
        yield return bounds.center;
        float x=bounds.extents.x*.8f,z=bounds.extents.z*.8f;
        foreach(int a in new[]{-1,1})foreach(int b in new[]{-1,1})
            yield return bounds.center+new Vector3(a*x,0,b*z);
    }
    static bool Valid(IEnumerable<BlockData> changed,float floor) {
        var moved=new HashSet<BlockData>(changed);
        foreach(var block in moved) {
            var bounds=BoundsOf(block);
            if(bounds.min.y<floor-Tolerance)return false;
            var nearby=Physics.OverlapBox(bounds.center,bounds.extents,Quaternion.identity,~0,QueryTriggerInteraction.Ignore)
                .Select(c=>c.GetComponentInParent<BlockData>()).Where(b=>b!=null && !b.IsPreview).Distinct();
            foreach(var other in nearby)
                if(other!=block && Intersects(block,other))return false;
        }
        return true;
    }
    public static bool TryResize(BlockData block,float width,float height,float length,float floor=0) {
        var all=Blocks();
        var affected=new List<BlockData>{block};
        var edges=new List<KeyValuePair<BlockData,BlockData>>();
        // Collect the support chain before scaling. Side neighbors are never pushed.
        for(int i=0;i<affected.Count;i++)
            foreach(var other in all)
                if(!affected.Contains(other) && IsSupportedBy(other,affected[i])) {
                    affected.Add(other);edges.Add(new KeyValuePair<BlockData,BlockData>(other,affected[i]));
                }
        var positions=affected.ToDictionary(b=>b,b=>b.transform.position);
        float oldWidth=block.widthOrRadius,oldHeight=block.height,oldLength=block.length;
        var before=BoundsOf(block);
        block.RestoreDimensions(width,height,length);
        Physics.SyncTransforms();
        var after=BoundsOf(block);
        block.transform.position+=new Vector3(before.center.x-after.center.x,
            Mathf.Max(floor,before.min.y)-after.min.y,before.center.z-after.center.z);
        Physics.SyncTransforms();
        float rise=BoundsOf(block).max.y-before.max.y;
        foreach(var child in affected.Skip(1))child.transform.position+=Vector3.up*rise;
        Physics.SyncTransforms();
        bool valid=Valid(affected,floor) && edges.All(edge=>IsSupportedBy(edge.Key,edge.Value));
        if(valid)return true;
        block.RestoreDimensions(oldWidth,oldHeight,oldLength);
        foreach(var pair in positions)pair.Key.transform.position=pair.Value;
        Physics.SyncTransforms();
        return false;
    }
    public static bool TryMove(BlockData block,Vector3 position,float floor=0) {
        if(!Finite(position) || Mathf.Abs(position.x)>10000 || Mathf.Abs(position.y)>10000 || Mathf.Abs(position.z)>10000)return false;
        var before=block.transform.position;
        block.transform.position=position;Physics.SyncTransforms();
        if(Valid(new[]{block},floor))return true;
        block.transform.position=before;Physics.SyncTransforms();return false;
    }
    static bool Finite(Vector3 v) => !float.IsNaN(v.x)&&!float.IsNaN(v.y)&&!float.IsNaN(v.z)&&!float.IsInfinity(v.x)&&!float.IsInfinity(v.y)&&!float.IsInfinity(v.z);
    public static bool TryPlace(BlockData block,Vector3 desired,float maxSupportHeight,float floor=0) {
        var previous=block.transform.position;
        var bounds=BoundsOf(block);
        Vector3 relativeMin=bounds.min-previous;
        desired.x=Mathf.Round(desired.x+relativeMin.x)-relativeMin.x;
        desired.z=Mathf.Round(desired.z+relativeMin.z)-relativeMin.z;
        block.transform.position=new Vector3(desired.x,previous.y,desired.z);
        Physics.SyncTransforms();bounds=BoundsOf(block);
        float support=floor;
        foreach(var point in Samples(bounds)) {
            var hits=Physics.RaycastAll(new Vector3(point.x,maxSupportHeight+.05f,point.z),Vector3.down,
                Mathf.Max(.1f,maxSupportHeight-floor+.1f),~0,QueryTriggerInteraction.Ignore);
            foreach(var hit in hits) {
                var other=hit.collider.GetComponentInParent<BlockData>();
                if(other==block || (other!=null && other.IsPreview))continue;
                if(hit.normal.y>.98f && hit.point.y<=maxSupportHeight+.01f)support=Mathf.Max(support,hit.point.y);
            }
        }
        block.transform.position+=Vector3.up*(support-bounds.min.y);
        Physics.SyncTransforms();
        if(Valid(new[]{block},floor))return true;
        block.transform.position=previous;Physics.SyncTransforms();return false;
    }
}
