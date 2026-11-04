using UnityEngine;
using UnityEngine.EventSystems;

public class UIDragItem : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler
{
    public GameObject blockPrefab;
    public HierarchyManager hierarchyManager;
    
    [Header("Selection Reference")]
    public SelectionManager selectionManager; 
    
    [Header("Stacking Settings")]
    public float floorHeight = 0f;
    public float yOffset = 0f; 

    private GameObject _currentTempBlock;
    private Camera _mainCam;
    private Material _originalMaterial;
    private static int _blockCount = 0; 

    void Start() => _mainCam = Camera.main;

    public void OnBeginDrag(PointerEventData eventData)
    {
        CameraHandler.IsCameraLocked = true;
        _currentTempBlock = Instantiate(blockPrefab);
        
        if(_currentTempBlock.TryGetComponent<Collider>(out Collider col)) {
            col.enabled = false;
        }

        _blockCount++;
        _currentTempBlock.name = blockPrefab.name + " " + _blockCount;

        Renderer renderer = _currentTempBlock.GetComponentInChildren<Renderer>();
        if (renderer != null)
        {
            _originalMaterial = renderer.material; 
            Material ghostMat = new Material(_originalMaterial);
            Color ghostColor = ghostMat.color;
            ghostColor.a = 0.5f; 
            ghostMat.color = ghostColor;
            renderer.material = ghostMat;
        }
    }

    public void OnDrag(PointerEventData eventData)
    {
        if (_currentTempBlock == null) return;

        Ray ray = _mainCam.ScreenPointToRay(eventData.position);
        
        // Use the floorHeight variable so we aren't hardcoded to 0
        Plane groundPlane = new Plane(Vector3.up, new Vector3(0, floorHeight, 0));
        
        if (groundPlane.Raycast(ray, out float rayDistance))
        {
            // 1. Get the raw point on the ground plane where the finger is pointing
            Vector3 rawPoint = ray.GetPoint(rayDistance);
            
            // 2. Snap X and Z to the grid
            float snappedX = Mathf.Round(rawPoint.x);
            float snappedZ = Mathf.Round(rawPoint.z);

            // 3. Default the Y height to the floor + offset
            float targetY = floorHeight + yOffset;


            Vector3 skyPosition = new Vector3(snappedX, 100f, snappedZ);
            
            if (Physics.Raycast(skyPosition, Vector3.down, out RaycastHit hit))
            {
                // We hit something! Set our Y to rest on the top of its bounding box
                targetY = Mathf.Round(hit.collider.bounds.max.y) + yOffset;
            }

            // 4. Update the ghost block's position!
            _currentTempBlock.transform.position = new Vector3(snappedX, targetY, snappedZ);
        }
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        CameraHandler.IsCameraLocked = false;
        if (_currentTempBlock == null) return;

        if(_currentTempBlock.TryGetComponent<Collider>(out Collider col)) {
            col.enabled = true;
        }
        Renderer renderer = _currentTempBlock.GetComponentInChildren<Renderer>();
        if (renderer != null) {
            renderer.material = _originalMaterial;
        }

        if (hierarchyManager != null)
        {
            hierarchyManager.AddBlockToList(_currentTempBlock);
        }

        // --- NEW: Automatically select the block we just dropped! ---
        if (selectionManager != null && _currentTempBlock.TryGetComponent<BlockData>(out BlockData newBlockData))
        {
            selectionManager.ForceSelectBlock(newBlockData);
        }

        _currentTempBlock = null;
    }
}