using UnityEngine;
using UnityEngine.EventSystems;

public class CameraHandler : MonoBehaviour
{
    private Camera _cam;
    
    [Header("Orbit Settings")]
    public Transform orbitTarget; 
    public float rotationSpeed = 0.1f;

    [Header("Zoom Settings")]
    public float zoomSpeed = 0.1f;
    public float minFOV = 15f;
    public float maxFOV = 90f;

    [Header("Pan Settings")]
    public float panSpeed = 0.01f;

    public static bool IsCameraLocked = false;

    void Start()
    {
        _cam = GetComponent<Camera>();
        if (orbitTarget == null)
        {
            GameObject fallbackCenter = new GameObject("FallbackOrbitCenter");
            fallbackCenter.transform.position = Vector3.zero;
            orbitTarget = fallbackCenter.transform;
        }
    }

    void Update()
    {
        if (IsCameraLocked) return;
        if (SelectionManager.isDraggingBlock == true)
        {
            return;
        }

        // Prevent camera movement when touching UI 
        if (Input.touchCount > 0 && EventSystem.current.IsPointerOverGameObject(Input.GetTouch(0).fingerId))
        {
            return;
        }

        if (Input.touchCount == 2)
        {
            HandleTwoFingerGestures();
        }
        else if (Input.touchCount == 1)
        {
            HandleOrbitRotation();
        }
    }

    private void HandleOrbitRotation()
    {
        Touch touch = Input.GetTouch(0);
        if (touch.phase == TouchPhase.Moved)
        {
            transform.RotateAround(orbitTarget.position, Vector3.up, touch.deltaPosition.x * rotationSpeed);
            transform.RotateAround(orbitTarget.position, transform.right, -touch.deltaPosition.y * rotationSpeed);
        }
    }

    private void HandleTwoFingerGestures()
    {
        Touch touchZero = Input.GetTouch(0);
        Touch touchOne = Input.GetTouch(1);

        // Pinch to zoom logic
        Vector2 touchZeroPrevPos = touchZero.position - touchZero.deltaPosition;
        Vector2 touchOnePrevPos = touchOne.position - touchOne.deltaPosition;

        float prevTouchDeltaMag = (touchZeroPrevPos - touchOnePrevPos).magnitude;
        float touchDeltaMag = (touchZero.position - touchOne.position).magnitude;
        float deltaMagnitudeDiff = prevTouchDeltaMag - touchDeltaMag;

        _cam.fieldOfView += deltaMagnitudeDiff * zoomSpeed;
        _cam.fieldOfView = Mathf.Clamp(_cam.fieldOfView, minFOV, maxFOV);

        // Two-finger pan swipe
        Vector2 prevMidPoint = (touchZeroPrevPos + touchOnePrevPos) / 2;
        Vector2 currentMidPoint = (touchZero.position + touchOne.position) / 2;
        Vector2 midPointDelta = currentMidPoint - prevMidPoint;

        if (midPointDelta.magnitude > 0.01f)
        {
            Vector3 moveDir = (transform.right * -midPointDelta.x + transform.up * -midPointDelta.y) * panSpeed;

            transform.position += moveDir;
            orbitTarget.position += moveDir;
        }
    }
}