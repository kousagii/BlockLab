using UnityEngine;
using System.Collections.Generic;

// Capture all affected blocks: resizing can displace neighbors as well.
public class WorkspaceSnapshotCommand : ICommand
{
    private class State
    {
        public BlockData block;
        public Vector3 position;
        public Quaternion rotation;
        public Color color;
        public float width, height, length;
        public State(BlockData value) {
            block=value; position=value.transform.position; rotation=value.transform.rotation;
            color=value.blockColor; width=value.widthOrRadius; height=value.height; length=value.length;
        }
        public void Restore() {
            if (block==null) return;
            block.RestoreDimensions(width,height,length);
            block.transform.SetPositionAndRotation(position,rotation); block.SetColor(color);
        }
    }
    private readonly List<State> _before=new List<State>();
    private List<State> _after;
    public WorkspaceSnapshotCommand() {
        foreach (var block in Object.FindObjectsOfType<BlockData>())
            if (!block.IsPreview) _before.Add(new State(block));
    }
    public void Undo() {
        _after=new List<State>();
        foreach (var state in _before) if (state.block!=null) _after.Add(new State(state.block));
        Restore(_before);
    }
    public void Redo() { if (_after!=null) Restore(_after); }
    private static void Restore(List<State> states) {
        foreach (var state in states) state.Restore();
        Physics.SyncTransforms();
    }
}
