using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections; 

public class PropertiesUIManager : MonoBehaviour
{
    public GameObject propertiesPanel;
    public TMP_Text blockNameLabel;
    private BlockData _currentBlock;

    [Header("Dimension Rows")]
    public GameObject rowWidthRadius;
    public GameObject rowHeight;
    public GameObject rowLength;

    [Header("Dimension Labels")]
    public TMP_Text widthRadiusLabel;   

    [Header("Dimension Sliders")]
    public Slider sliderWidthRadius;
    public Slider sliderHeight;
    public Slider sliderLength;

    [Header("Dimension Value Texts")]
    public TMP_Text valWidthRadius;
    public TMP_Text valHeight;
    public TMP_Text valLength;

    [Header("Color System")]
    public Image colorPreviewButton; 
    public GameObject colorPickerContainer; 
    public FlexibleColorPicker fcp; 

    [Header("Managers")]
    public HierarchyManager hierarchyManager;

    private bool _recordedGesture;
    void LateUpdate()
    {
        if (Input.GetMouseButtonUp(0)) _recordedGesture = false;
    }
    private void RecordEdit()
    {
        if (!_recordedGesture && UndoManager.Instance != null)
        {
            UndoManager.Instance.RecordCommand(new WorkspaceSnapshotCommand());
            _recordedGesture = Input.GetMouseButton(0);
        }
    }

    void Start()
    {
        if (propertiesPanel != null && _currentBlock == null) propertiesPanel.SetActive(false);
        if (colorPickerContainer != null) colorPickerContainer.SetActive(false);
        if (fcp != null) fcp.onColorChange.RemoveListener(OnFCPColorChanged);
    }

    public void OpenPanel(BlockData block)
    {
        bool newSelection = _currentBlock != block;
        _recordedGesture = false;
        _currentBlock = block;
        if (blockNameLabel != null) blockNameLabel.text = block.name;
        propertiesPanel.SetActive(true);
        FindObjectOfType<SandboxUIController>()?.ShowProperties(newSelection);


        if (colorPickerContainer != null) 
        {
            if (fcp != null) fcp.onColorChange.RemoveListener(OnFCPColorChanged);
            colorPickerContainer.SetActive(false);
        }

        if (colorPreviewButton != null) colorPreviewButton.color = _currentBlock.blockColor;
        
        rowWidthRadius.SetActive(true);
        rowHeight.SetActive(true);
        rowLength.SetActive(true);

        switch (block.shapeType)
        {
            case BlockShapeType.Cube:
                widthRadiusLabel.text = "Width:";
                break;
            case BlockShapeType.Cylinder:
                widthRadiusLabel.text = "Width:";
                rowLength.SetActive(false);   
                break;
            case BlockShapeType.TriangularPrism:
            case BlockShapeType.Trapezoid:
                widthRadiusLabel.text = "Base Width:"; 
                break;
            case BlockShapeType.HalfCylinder:
                widthRadiusLabel.text = "Width:";
                break;
        }

        sliderWidthRadius.SetValueWithoutNotify(block.widthOrRadius);
        sliderHeight.SetValueWithoutNotify(block.height);
        sliderLength.SetValueWithoutNotify(block.length);

        if(valWidthRadius != null) valWidthRadius.text = block.widthOrRadius.ToString("0.##");
        if(valHeight != null) valHeight.text = block.height.ToString("0.##");
        if(valLength != null) valLength.text = block.length.ToString("0.##");
    }

    private void Resize(float width,float height,float length) {
        if(_currentBlock==null)return;
        if(Mathf.Approximately(width,_currentBlock.widthOrRadius) && Mathf.Approximately(height,_currentBlock.height) && Mathf.Approximately(length,_currentBlock.length))return;
        var before=_recordedGesture ? null : new WorkspaceSnapshotCommand();
        if(_currentBlock.TryResize(width,height,length)) {
            if(before!=null) { UndoManager.Instance?.RecordCommand(before);_recordedGesture=Input.GetMouseButton(0); }
            WorkspaceState.Edit();
        } else FindObjectOfType<SandboxUIController>()?.ShowHint("Not enough space. Move nearby blocks or keep the current size.");
        ForceRefreshSizeUI(_currentBlock.widthOrRadius,_currentBlock.height,_currentBlock.length);
    }
    public void OnWidthRadiusChanged(float value) { if(_currentBlock!=null)Resize(value,_currentBlock.height,_currentBlock.length); }
    public void OnHeightChanged(float value) { if(_currentBlock!=null)Resize(_currentBlock.widthOrRadius,value,_currentBlock.length); }
    public void OnLengthChanged(float value) { if(_currentBlock!=null)Resize(_currentBlock.widthOrRadius,_currentBlock.height,value); }

    public void ToggleColorPicker()
    {
        if (colorPickerContainer != null)
        {
            StopAllCoroutines();
            if (_currentBlock == null) return;
            bool isTurningOn = !colorPickerContainer.activeSelf;
            
            if (isTurningOn)
            {

                if (fcp != null) fcp.onColorChange.RemoveListener(OnFCPColorChanged);
                colorPickerContainer.SetActive(true);
                if (fcp != null && _currentBlock != null) StartCoroutine(WakeUpFCP(_currentBlock.blockColor));
            }
            else
            {
                if (fcp != null) fcp.onColorChange.RemoveListener(OnFCPColorChanged);
                colorPickerContainer.SetActive(false);
            }
        }
    }

    private IEnumerator WakeUpFCP(Color targetColor)
    {
        yield return null; 
        if (fcp != null)
        {
            fcp.color = targetColor;
            yield return null; 
            fcp.onColorChange.AddListener(OnFCPColorChanged);
        }
    }

    public void OnFCPColorChanged(Color newColor)
    {
        if (_currentBlock != null && _currentBlock.blockColor != newColor)
        {
            RecordEdit();
            _currentBlock.SetColor(newColor); 
            WorkspaceState.Edit();
            if (colorPreviewButton != null) colorPreviewButton.color = newColor; 
        }
    }

    public void DeleteBlock()
    {
        if (_currentBlock != null)
        {
            var command = new DeleteCommand(_currentBlock.gameObject, hierarchyManager);
            UndoManager.Instance?.RecordCommand(command);
            FindObjectOfType<SelectionManager>()?.DeselectCurrent();
            command.Redo();
        }
    }

    public void HideColorPicker()
    {
        StopAllCoroutines();
        if (fcp != null) fcp.onColorChange.RemoveListener(OnFCPColorChanged);
        if (colorPickerContainer != null) colorPickerContainer.SetActive(false);
    }

    public void ForceRefreshColorUI(Color undoneColor)
    {
        if (colorPreviewButton != null) colorPreviewButton.color = undoneColor;

        if (colorPickerContainer != null && colorPickerContainer.activeSelf && fcp != null)
        {
            fcp.onColorChange.RemoveListener(OnFCPColorChanged);
            fcp.color = undoneColor;
            fcp.onColorChange.AddListener(OnFCPColorChanged);
        }
    }

    public void ForceRefreshSizeUI(float w, float h, float l)
    {
        sliderWidthRadius.SetValueWithoutNotify(w);
        sliderHeight.SetValueWithoutNotify(h);
        sliderLength.SetValueWithoutNotify(l);

        if(valWidthRadius != null) valWidthRadius.text = w.ToString("0.##");
        if(valHeight != null) valHeight.text = h.ToString("0.##");
        if(valLength != null) valLength.text = l.ToString("0.##");
    }

    public void ClosePanel()
    {
        StopAllCoroutines();
        if (_currentBlock != null)
        {
            Outline outline = _currentBlock.GetComponent<Outline>();
            if (outline != null) outline.enabled = false;
            _currentBlock = null;
        }

        if (propertiesPanel != null) propertiesPanel.SetActive(false);
        
        if (colorPickerContainer != null) 
        {
            if (fcp != null) fcp.onColorChange.RemoveListener(OnFCPColorChanged);
            colorPickerContainer.SetActive(false);
        }
    }
}
