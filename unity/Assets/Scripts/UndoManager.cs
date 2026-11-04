using System.Collections.Generic;
using UnityEngine;

public interface ICommand
{
    void Undo();
}

public class MoveCommand : ICommand
{
    private Transform _blockTransform;
    private Vector3 _previousPosition;

    public MoveCommand(Transform blockTransform, Vector3 previousPosition)
    {
        _blockTransform = blockTransform;
        _previousPosition = previousPosition;
    }

    public void Undo()
    {
        if (_blockTransform != null) _blockTransform.position = _previousPosition;
    }
}

// --- NEW COMMANDS BELOW ---

public class DeleteCommand : ICommand
{
    private GameObject _blockObj;
    private HierarchyManager _hierarchyManager;

    public DeleteCommand(GameObject blockObj, HierarchyManager hierarchyManager)
    {
        _blockObj = blockObj;
        _hierarchyManager = hierarchyManager;
    }

    public void Undo()
    {
        if (_blockObj != null)
        {
            // 1. Turn the block back on!
            _blockObj.SetActive(true);
            
            // 2. Put it back in the UI list
            if (_hierarchyManager != null)
            {
                _hierarchyManager.AddBlockToList(_blockObj);
            }
        }
    }
}

public class ColorCommand : ICommand
{
    private BlockData _block;
    private Color _previousColor;

    public ColorCommand(BlockData block, Color previousColor)
    {
        _block = block;
        _previousColor = previousColor;
    }

    public void Undo()
    {
        if (_block != null)
        {
            _block.SetColor(_previousColor);
            
            // If the UI is currently open for this block, update the panel!
            PropertiesUIManager uiManager = Object.FindObjectOfType<PropertiesUIManager>();
            if (uiManager != null) uiManager.ForceRefreshColorUI(_previousColor);
        }
    }
}

public class SizeCommand : ICommand
{
    private BlockData _block;
    private float _prevW, _prevH, _prevL;

    public SizeCommand(BlockData block, float prevW, float prevH, float prevL)
    {
        _block = block;
        _prevW = prevW;
        _prevH = prevH;
        _prevL = prevL;
    }

    public void Undo()
    {
        if (_block != null)
        {
            _block.widthOrRadius = _prevW;
            _block.height = _prevH;
            _block.length = _prevL;
            _block.ApplyDimensions();

            // If the UI is open for this block, update the sliders!
            PropertiesUIManager uiManager = Object.FindObjectOfType<PropertiesUIManager>();
            if (uiManager != null) uiManager.ForceRefreshSizeUI(_prevW, _prevH, _prevL);
        }
    }
}

// --- MANAGER ---
public class UndoManager : MonoBehaviour
{
    public static UndoManager Instance; 
    private Stack<ICommand> _undoStack = new Stack<ICommand>();

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);
    }

    public void RecordCommand(ICommand command)
    {
        _undoStack.Push(command);
    }

    public void ClickUndo()
    {
        if (_undoStack.Count > 0)
        {
            ICommand lastAction = _undoStack.Pop();
            lastAction.Undo();
        }
        else
        {
            Debug.Log("Nothing to undo!");
        }
    }

    public class AddCommand : ICommand
{
    private GameObject _blockObj;
    private HierarchyManager _hierarchyManager;

    public AddCommand(GameObject blockObj, HierarchyManager hierarchyManager)
    {
        _blockObj = blockObj;
        _hierarchyManager = hierarchyManager;
    }

    public void Undo()
    {
        if (_blockObj != null)
        {
            _blockObj.SetActive(false);
            if (_hierarchyManager != null)
            {
                _hierarchyManager.RemoveBlockFromList(_blockObj);
            }


            PropertiesUIManager uiManager = Object.FindObjectOfType<PropertiesUIManager>();
            if (uiManager != null)
            {

                uiManager.propertiesPanel.SetActive(false);
                if (uiManager.colorPickerContainer != null) uiManager.colorPickerContainer.SetActive(false);
            }
        }
    }
}
}