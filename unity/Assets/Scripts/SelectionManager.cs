using UnityEngine;
using UnityEngine.EventSystems;

public class SelectionManager : MonoBehaviour
{
    [Header("UI Reference")]
    public PropertiesUIManager uiManager; 

    [Header("Grid & Movement Settings")]
    public float floorHeight = 0f; 

    public static bool isDraggingBlock = false;

    private Transform _grabbedObject;
    private BlockData _grabbedBlockData; 
    private float _zDistanceToCamera;
    private Vector3 _dragOffset;

    private BlockData _selectedBlock; 
    private Vector3 _startDragPosition;

   void Update()
    {
        // --- NEW: MULTI-TOUCH GUARD ---
        // If there are two or more fingers on the screen, abort selection and dragging
        // so the CameraHandler can safely take over for zooming/panning!
        if (Input.touchCount > 1)
        {
            if (isDraggingBlock && _grabbedObject != null)
            {
                // Snap the block back to where it was before we accidentally grabbed it
                _grabbedObject.position = _startDragPosition; 
                
                // Let go of the block
                _grabbedObject = null; 
                _grabbedBlockData = null; 
                isDraggingBlock = false; 
            }
            return; // Skip the rest of the update so we don't process clicks
        }

        // 1. START GRABBING OR DESELECTING
        if (Input.GetMouseButtonDown(0))
        {
            if (IsPointerOverUI()) return; 

            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;

            if (Physics.Raycast(ray, out hit))
            {
                BlockData clickedBlock = hit.collider.GetComponentInParent<BlockData>();
                
                if (clickedBlock != null)
                {
                    if (_selectedBlock != null && _selectedBlock != clickedBlock)
                    {
                        Outline oldOutline = _selectedBlock.GetComponent<Outline>();
                        if (oldOutline != null) oldOutline.enabled = false;
                    }

                    Outline newOutline = clickedBlock.GetComponent<Outline>();
                    if (newOutline != null) newOutline.enabled = true;

                    _selectedBlock = clickedBlock;

                    if (uiManager != null) uiManager.OpenPanel(clickedBlock);

                    _grabbedObject = clickedBlock.transform;
                    _grabbedBlockData = clickedBlock; 
                    isDraggingBlock = true; 

                    _startDragPosition = _grabbedObject.position;
                    
                    _zDistanceToCamera = Camera.main.WorldToScreenPoint(_grabbedObject.position).z;
                    Vector3 screenPosition = new Vector3(Input.mousePosition.x, Input.mousePosition.y, _zDistanceToCamera);
                    _dragOffset = _grabbedObject.position - Camera.main.ScreenToWorldPoint(screenPosition);
                }
            }
        }

        // 2. DRAGGING
        if (Input.GetMouseButton(0) && _grabbedObject != null && _grabbedBlockData != null)
        {
            Vector3 currentScreenPos = new Vector3(Input.mousePosition.x, Input.mousePosition.y, _zDistanceToCamera);
            Vector3 rawWorldPos = Camera.main.ScreenToWorldPoint(currentScreenPos) + _dragOffset;

            float w = _grabbedBlockData.widthOrRadius;
            float l = _grabbedBlockData.length;

            if (_grabbedBlockData.shapeType == BlockShapeType.Cylinder) 
            {
                l = w;
            } 
            
            float offsetX = (w / 2f) - 0.5f;
            float offsetZ = (l / 2f) - 0.5f;

            float snappedX = Mathf.Round(rawWorldPos.x - offsetX) + offsetX;
            float snappedZ = Mathf.Round(rawWorldPos.z - offsetZ) + offsetZ;

            float targetY = floorHeight;

            Collider[] allColliders = _grabbedObject.GetComponentsInChildren<Collider>();
            foreach (Collider col in allColliders) col.enabled = false;

            Vector3 skyPosition = new Vector3(snappedX, 100f, snappedZ);
            RaycastHit[] hits = Physics.RaycastAll(skyPosition, Vector3.down, 200f);

            float bestY = floorHeight;
            float mouseHeightLimit = rawWorldPos.y + 1.5f; 

            foreach (RaycastHit hitItem in hits)
            {
                float surfaceHeight = hitItem.collider.bounds.max.y;

                if (hitItem.normal.y > 0.99f && surfaceHeight <= mouseHeightLimit && surfaceHeight > bestY)
                {
                    bestY = surfaceHeight; 
                }
            }

            targetY = bestY;

            foreach (Collider col in allColliders) col.enabled = true;

            _grabbedObject.position = new Vector3(snappedX, targetY, snappedZ);
        }

        // 3. DROP BLOCK
        if (Input.GetMouseButtonUp(0))
        {
            if (_grabbedObject != null && _grabbedObject.position != _startDragPosition)
            {
                 if (UndoManager.Instance != null)
                     UndoManager.Instance.RecordCommand(new MoveCommand(_grabbedObject, _startDragPosition));
            }

            _grabbedObject = null; 
            _grabbedBlockData = null; 
            isDraggingBlock = false; 
        }
    }

    public void ForceSelectBlock(BlockData blockToSelect)
    {
        if (blockToSelect == null) return;

        if (_selectedBlock != null && _selectedBlock != blockToSelect)
        {
            Outline oldOutline = _selectedBlock.GetComponent<Outline>();
            if (oldOutline != null) oldOutline.enabled = false;
        }
        Outline newOutline = blockToSelect.GetComponent<Outline>();
        if (newOutline != null) newOutline.enabled = true;

        _selectedBlock = blockToSelect;

        if (uiManager != null) uiManager.OpenPanel(blockToSelect);
    }

    public void DeselectCurrent()
    {
        _grabbedObject = null; _grabbedBlockData = null; isDraggingBlock = false;
        if (_selectedBlock != null)
        {
            Outline oldOutline = _selectedBlock.GetComponent<Outline>();
            if (oldOutline != null) oldOutline.enabled = false;
            _selectedBlock = null;
        }

        if (uiManager != null) 
        {
            uiManager.ClosePanel(); 
        }
    }

    private bool IsPointerOverUI()
    {
        if (EventSystem.current == null) return false;

        if (Input.touchCount > 0)
        {
            for (int i = 0; i < Input.touchCount; i++)
            {
                // If any finger is currently touching a UI element, return true
                if (EventSystem.current.IsPointerOverGameObject(Input.GetTouch(i).fingerId))
                {
                    return true;
                }
            }
        }
        
        if (EventSystem.current.IsPointerOverGameObject())
        {
            return true;
        }

        return false;
    }
}
