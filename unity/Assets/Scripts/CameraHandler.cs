using UnityEngine;
using UnityEngine.EventSystems;

public class CameraHandler : MonoBehaviour
{
    private Camera _cam;
    private Vector3 _initialPosition, _initialTarget;
    private Quaternion _initialRotation;
    private float _initialFov;
    
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
        _initialPosition=transform.position; _initialRotation=transform.rotation;
        _initialTarget=orbitTarget.position; _initialFov=_cam.fieldOfView;
    }
    public void ResetView() {
        transform.SetPositionAndRotation(_initialPosition,_initialRotation);
        orbitTarget.position=_initialTarget; _cam.fieldOfView=_initialFov;
    }

    void Update()
    {
        if (IsCameraLocked || SelectionManager.UiBlocked) return;
        if (SelectionManager.isDraggingBlock == true)
        {
            return;
        }

        // Prevent camera movement when touching UI 
        if (Input.touchCount > 0 && EventSystem.current != null && EventSystem.current.IsPointerOverGameObject(Input.GetTouch(0).fingerId))
        {
            return;
        }

        if (Input.touchCount == 0)
        {
            if (EventSystem.current != null && EventSystem.current.IsPointerOverGameObject()) return;
            _cam.fieldOfView = Mathf.Clamp(_cam.fieldOfView - Input.mouseScrollDelta.y * 3f, minFOV, maxFOV);
            if (Input.GetMouseButton(1) || (SelectionManager.PictureMode && Input.GetMouseButton(0)))
            {
                transform.RotateAround(orbitTarget.position, Vector3.up, Input.GetAxis("Mouse X") * 3f);
                transform.RotateAround(orbitTarget.position, transform.right, -Input.GetAxis("Mouse Y") * 3f);
            }
            if (Input.GetMouseButton(2))
            {
                var movement = (-transform.right * Input.GetAxis("Mouse X") - transform.up * Input.GetAxis("Mouse Y")) * .2f;
                transform.position += movement; orbitTarget.position += movement;
            }
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
