using System;
using System.Linq;
using UnityEngine;

public static class BlockLabGeometryChecks
{
    static void Require(bool condition,string message){if(!condition)throw new Exception(message);}
    public static void Clear() {
        UnityEngine.Object.FindObjectOfType<SelectionManager>()?.DeselectCurrent();
        foreach(var block in UnityEngine.Object.FindObjectsOfType<BlockData>(true))UnityEngine.Object.DestroyImmediate(block.gameObject);
        UnityEngine.Object.FindObjectOfType<HierarchyManager>(true)?.ClearHierarchyUI();
        UndoManager.Instance.ClearHistory();Physics.SyncTransforms();
    }
    static BlockData Make(LoadManager loader,int shape,Vector3 center,float bottom,Vector3 size,Quaternion? rotation=null) {
        var block=UnityEngine.Object.Instantiate(loader.blockPrefabs[shape]).GetComponent<BlockData>();
        block.EnsureIdentity();block.RestoreDimensions(size.x,size.y,size.z);
        if(rotation.HasValue)block.transform.rotation=rotation.Value;
        Physics.SyncTransforms();
        var bounds=BlockPlacement.BoundsOf(block);
        block.transform.position+=new Vector3(center.x-bounds.center.x,bottom-bounds.min.y,center.z-bounds.center.z);
        Physics.SyncTransforms();return block;
    }
    public static void Run() {
        var loader=UnityEngine.Object.FindObjectOfType<LoadManager>();Clear();
        for(int shape=0;shape<5;shape++) {
            var block=Make(loader,shape,Vector3.zero,-2,Vector3.one,
                Quaternion.Euler(20,37,13)*loader.blockPrefabs[shape].transform.rotation);
            var before=BlockPlacement.BoundsOf(block).center;
            Require(block.TryResize(2,3,4),"Rotated resize failed for shape "+shape);
            var bounds=BlockPlacement.BoundsOf(block);
            Require(bounds.min.y>=-BlockPlacement.Tolerance,"Resizing buried shape "+shape);
            Require(Mathf.Abs(bounds.center.x-before.x)<.002f && Mathf.Abs(bounds.center.z-before.z)<.002f,"Resizing shifted footprint");
            Require(BlockPlacement.TryPlace(block,new Vector3(4,0,3),1),"Rotated placement failed for shape "+shape);
            Require(Mathf.Abs(BlockPlacement.BoundsOf(block).min.y)<.005f,"Placement ignored mesh pivot");
            Clear();
        }
        var a=Make(loader,0,Vector3.zero,0,new Vector3(4,1,.2f),Quaternion.Euler(0,45,0));
        var b=Make(loader,0,new Vector3(.4f,0,.4f),0,new Vector3(4,1,.2f),Quaternion.Euler(0,45,0));
        Require(BlockPlacement.BoundsOf(a).Intersects(BlockPlacement.BoundsOf(b)),"Test setup did not overlap AABBs");
        Require(!BlockPlacement.Intersects(a,b),"AABB overlap falsely rejected disjoint rotated meshes");
        Clear();
        var bottom=Make(loader,0,Vector3.zero,0,new Vector3(2,2,2));
        var child=Make(loader,0,Vector3.zero,2,Vector3.one);
        var grandchild=Make(loader,0,Vector3.zero,3,Vector3.one);
        Require(BlockPlacement.IsSupportedBy(child,bottom),"Support detection failed");
        Require(bottom.TryResize(2,4,2),"Stack resize rejected");
        Require(Mathf.Abs(BlockPlacement.BoundsOf(child).min.y-4)<.005f && Mathf.Abs(BlockPlacement.BoundsOf(grandchild).min.y-5)<.005f,"Stack was not carried as one edit");
        var neighbor=Make(loader,0,new Vector3(3,0,0),0,Vector3.one);
        var positions=BlockPlacement.Blocks().ToDictionary(x=>x,x=>x.transform.position);
        Require(!bottom.TryResize(8,4,2),"Resize passed through a fixed neighbor");
        Require(bottom.widthOrRadius==2,"Rejected resize retained dimensions");
        foreach(var pair in positions)Require(pair.Key.transform.position==pair.Value,"Rejected resize moved a block");
        var obstacle=Make(loader,0,Vector3.zero,8,Vector3.one);
        Require(!bottom.TryResize(2,7,2),"Carried stack passed through an obstacle");
        Require(Mathf.Abs(BlockPlacement.BoundsOf(child).min.y-4)<.005f,"Rejected stack edit did not roll back");
        Clear();
        var subject=Make(loader,0,Vector3.zero,0,Vector3.one);
        var camera=Camera.main;
        var cameraPosition=camera.transform.position;var cameraRotation=camera.transform.rotation;
        foreach(var position in new[]{new Vector3(5,3,-5),new Vector3(-4,8,3),new Vector3(0,2,-8)}) {
            camera.transform.position=position;camera.transform.LookAt(Vector3.zero);
            var ray=camera.ScreenPointToRay(camera.WorldToScreenPoint(Vector3.zero));
            Require(new Plane(Vector3.up,Vector3.zero).Raycast(ray,out float distance),"Camera plane test failed");
            Require(BlockPlacement.TryPlace(subject,ray.GetPoint(distance),1),"Camera-angle placement failed");
            Require(Mathf.Abs(BlockPlacement.BoundsOf(subject).min.y)<.005f,"Camera angle buried shape");
        }
        camera.transform.SetPositionAndRotation(cameraPosition,cameraRotation);
        var selection=UnityEngine.Object.FindObjectOfType<SelectionManager>();selection.ForceSelectBlock(subject);
        UnityEngine.Object.FindObjectOfType<SandboxUIController>().ShowMove();
        Debug.Log("BLOCKLAB_GEOMETRY_CHECKS_PASSED: five rotated shapes, mesh pivots, narrow-phase collision, fixed neighbors, carried stacks, rollback, camera angles.");
    }
    public static void CheckGizmo() {
        var ui=UnityEngine.Object.FindObjectOfType<SandboxUIController>();
        var gizmo=ui.GetComponent<MoveGizmo>();
        var block=UnityEngine.Object.FindObjectOfType<SelectionManager>().SelectedBlock;
        Require(gizmo.Visible,"Move handles did not appear");
        UndoManager.Instance.ClearHistory();
        var start=block.transform.position;
        gizmo.Begin(0,Vector2.zero);gizmo.Drag(gizmo.ScreenDeltaForUnits(0,2));gizmo.End();
        Require(Vector3.Distance(block.transform.position,start+Vector3.right*2)<.005f,"Gizmo did not constrain movement to X");
        Require(!CameraHandler.IsCameraLocked && !SelectionManager.isDraggingBlock,"Gizmo retained gesture locks");
        UndoManager.Instance.ClickUndo();Require(Vector3.Distance(block.transform.position,start)<.005f && !UndoManager.Instance.CanUndo,"Gizmo gesture did not make one undo entry");
        UndoManager.Instance.ClickRedo();Require(Vector3.Distance(block.transform.position,start+Vector3.right*2)<.005f,"Gizmo redo failed");
        var before=block.transform.position;
        gizmo.Begin(2,Vector2.zero);gizmo.Drag(gizmo.ScreenDeltaForUnits(2,2));gizmo.Cancel();
        Require(Vector3.Distance(block.transform.position,before)<.005f,"Canceled gizmo move changed geometry");
        gizmo.Begin(1,Vector2.zero);gizmo.Drag(gizmo.ScreenDeltaForUnits(1,-2));gizmo.End();
        Require(BlockPlacement.BoundsOf(block).min.y>=-BlockPlacement.Tolerance,"Y gizmo buried a block");
        Require(SaveManager.Capture().blocks.Count==1,"Gizmo leaked into portable scene data");
        Clear();
        Debug.Log("BLOCKLAB_GIZMO_CHECKS_PASSED: constrained movement, cancellation, floor limits, single undo, redo and save exclusion.");
    }
}
