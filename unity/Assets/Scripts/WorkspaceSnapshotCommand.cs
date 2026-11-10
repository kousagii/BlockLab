using UnityEngine;
using System.Collections.Generic;

// Capture every affected block: a resize can also displace neighboring blocks.
public class WorkspaceSnapshotCommand : ICommand
{
    private class State
    {
        public BlockData block;
        public Vector3 position;
        public Quaternion rotation;
        public Color color;
        public float width, height, length;
    }
    private readonly List<State> _states = new List<State>();
    public WorkspaceSnapshotCommand()
    {
        foreach (var b in Object.FindObjectsOfType<BlockData>())
            _states.Add(new State { block = b, position = b.transform.position, rotation = b.transform.rotation,
                color = b.blockColor, width = b.widthOrRadius, height = b.height, length = b.length });
    }
    public void Undo()
    {
        foreach (var s in _states)
        {
            if (s.block == null) continue;
            s.block.RestoreDimensions(s.width, s.height, s.length);
            s.block.transform.SetPositionAndRotation(s.position, s.rotation);
            s.block.SetColor(s.color);
        }
        Physics.SyncTransforms();
    }
}
