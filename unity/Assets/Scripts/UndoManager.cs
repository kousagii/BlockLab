using System.Collections.Generic;
using UnityEngine;

public interface ICommand
{
    void Undo();
    void Redo();
}

public class MoveCommand : ICommand
{
    private readonly Transform _block;
    private readonly Vector3 _before;
    private Vector3 _after;
    public MoveCommand(Transform block, Vector3 before) { _block=block; _before=before; }
    public void Undo() { if (_block==null) return; _after=_block.position; _block.position=_before; Physics.SyncTransforms(); }
    public void Redo() { if (_block==null) return; _block.position=_after; Physics.SyncTransforms(); }
}

public class DeleteCommand : ICommand
{
    private readonly GameObject _block;
    private readonly HierarchyManager _hierarchy;
    public DeleteCommand(GameObject block, HierarchyManager hierarchy) { _block=block; _hierarchy=hierarchy; }
    public void Undo() { if (_block==null) return; _block.SetActive(true); _hierarchy?.AddBlockToList(_block); }
    public void Redo() { if (_block==null) return; _hierarchy?.RemoveBlockFromList(_block); _block.SetActive(false); }
}

public class ColorCommand : ICommand
{
    private readonly BlockData _block;
    private readonly Color _before;
    private Color _after;
    public ColorCommand(BlockData block, Color before) { _block=block; _before=before; }
    public void Undo() { if (_block==null) return; _after=_block.blockColor; _block.SetColor(_before); }
    public void Redo() { if (_block!=null) _block.SetColor(_after); }
}

public class SizeCommand : ICommand
{
    private readonly BlockData _block;
    private readonly Vector3 _before;
    private Vector3 _after, _beforePosition, _afterPosition;
    public SizeCommand(BlockData block, float width, float height, float length)
    { _block=block; _before=new Vector3(width,height,length); _beforePosition=block.transform.position; }
    public void Undo() {
        if (_block==null) return;
        _after=new Vector3(_block.widthOrRadius,_block.height,_block.length); _afterPosition=_block.transform.position;
        _block.RestoreDimensions(_before.x,_before.y,_before.z); _block.transform.position=_beforePosition;
        Physics.SyncTransforms();
    }
    public void Redo() {
        if (_block==null) return;
        _block.RestoreDimensions(_after.x,_after.y,_after.z); _block.transform.position=_afterPosition;
        Physics.SyncTransforms();
    }
}

public class UndoManager : MonoBehaviour
{
    public static UndoManager Instance;
    private readonly Stack<ICommand> _undoStack=new Stack<ICommand>();
    private readonly Stack<ICommand> _redoStack=new Stack<ICommand>();
    public bool CanUndo => _undoStack.Count>0;
    public bool CanRedo => _redoStack.Count>0;
    void Awake() { if (Instance==null || Instance==this) Instance=this; else Destroy(this); }
    void OnDestroy() { if (Instance==this) Instance=null; }
    public void ClearHistory() { _undoStack.Clear(); _redoStack.Clear(); WorkspaceState.Reset(); }
    public void RecordCommand(ICommand command) {
        if (command==null) return;
        _undoStack.Push(command); _redoStack.Clear(); WorkspaceState.Edit();
    }
    public void RequestUndo(string unused) { ClickUndo(); }
    public void RequestRedo(string unused) { ClickRedo(); }
    public void ClickUndo() {
        if (!CanUndo) return;
        var command=_undoStack.Pop(); command.Undo(); _redoStack.Push(command); Refresh();
    }
    public void ClickRedo() {
        if (!CanRedo) return;
        var command=_redoStack.Pop(); command.Redo(); _undoStack.Push(command); Refresh();
    }
    private void Refresh() {
        FindObjectOfType<SelectionManager>()?.RefreshSelection();
        WorkspaceState.Edit();
    }
    public class AddCommand : ICommand
    {
        private readonly GameObject _block;
        private readonly HierarchyManager _hierarchy;
        public AddCommand(GameObject block, HierarchyManager hierarchy) { _block=block; _hierarchy=hierarchy; }
        public void Undo() { if (_block==null) return; _hierarchy?.RemoveBlockFromList(_block); _block.SetActive(false); }
        public void Redo() { if (_block==null) return; _block.SetActive(true); _hierarchy?.AddBlockToList(_block); }
    }
}
