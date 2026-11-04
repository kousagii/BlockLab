using UnityEngine;

public class UISlidePanel : MonoBehaviour
{
    [Header("Hierarchy Panel")]
    public RectTransform hierarchyPanel;
    public float visiblePosX = 0f;       
    public float hiddenPosX = 350f;    
    public float slideSpeed = 10f;       

    [Header("Properties Panel")]
    public RectTransform propertiesPanel;
    public float rightMarginOpen = 350f;  
    public float rightMarginClosed = 0f;  

    private bool _isOpen = true;
    private Vector2 _targetPosition;
    private float _targetRightMargin;

    void Start()
    {
        // Start open
        _targetPosition = new Vector2(visiblePosX, hierarchyPanel.anchoredPosition.y);
        _targetRightMargin = rightMarginOpen;
    }

    void Update()
    {
        // Slide the Hierarchy Panel
        hierarchyPanel.anchoredPosition = Vector2.Lerp(
            hierarchyPanel.anchoredPosition, 
            _targetPosition, 
            Time.deltaTime * slideSpeed
        );

        // Stretch/Shrink the Properties Panel
        if (propertiesPanel != null)
        {
            Vector2 currentOffset = propertiesPanel.offsetMax;
            currentOffset.x = Mathf.Lerp(
                currentOffset.x, 
                -_targetRightMargin, 
                Time.deltaTime * slideSpeed
            );
            propertiesPanel.offsetMax = currentOffset;
        }
    }
    public void TogglePanel()
    {
        _isOpen = !_isOpen;
   
        float newX = _isOpen ? visiblePosX : hiddenPosX;
        _targetPosition = new Vector2(newX, hierarchyPanel.anchoredPosition.y);

        _targetRightMargin = _isOpen ? rightMarginOpen : rightMarginClosed;
    }
}