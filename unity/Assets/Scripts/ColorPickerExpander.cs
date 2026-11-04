using UnityEngine;
using UnityEngine.UI;

public class ColorPickerExpander : MonoBehaviour
{
    [Header("UI References")]
    public RectTransform panelRect; 
    public Button toggleButton;     

    [Header("Dimensions")]
    public float collapsedHeight = 60f;
    public float expandedHeight = 350f; 
    public float animationSpeed = 12f;

    private bool _isExpanded = false;
    private float _targetHeight;

    void Start()
    {
        _targetHeight = collapsedHeight;
        panelRect.sizeDelta = new Vector2(panelRect.sizeDelta.x, collapsedHeight);

        if (toggleButton != null)
        {
            toggleButton.onClick.AddListener(TogglePanel);
        }
    }

    void Update()
    {
        float currentHeight = panelRect.sizeDelta.y;
        if (Mathf.Abs(currentHeight - _targetHeight) > 0.5f)
        {
            float newHeight = Mathf.Lerp(currentHeight, _targetHeight, Time.deltaTime * animationSpeed);
            panelRect.sizeDelta = new Vector2(panelRect.sizeDelta.x, newHeight);
        }
    }

    public void TogglePanel()
    {
        _isExpanded = !_isExpanded;
        _targetHeight = _isExpanded ? expandedHeight : collapsedHeight;
    }
}