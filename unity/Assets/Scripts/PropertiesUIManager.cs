using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections; 

public class PropertiesUIManager : MonoBehaviour
{
    public GameObject propertiesPanel;
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

    private bool _hasRecordedSizeUndoThisSession = false;
    private bool _hasRecordedColorUndoThisSession = false;
    private Color _colorBeforeEdit;
    private float _wBefore, _hBefore, _lBefore;

    void Start()
    {
        if (propertiesPanel != null) propertiesPanel.SetActive(false);
        if (colorPickerContainer != null) colorPickerContainer.SetActive(false);
        if (fcp != null) fcp.onColorChange.RemoveListener(OnFCPColorChanged);
    }

    public void OpenPanel(BlockData block)
    {
        _currentBlock = block;
        propertiesPanel.SetActive(true);

        _hasRecordedSizeUndoThisSession = false;
        _wBefore = block.widthOrRadius;
        _hBefore = block.height;
        _lBefore = block.length;

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
                widthRadiusLabel.text = "Radius:";
                rowLength.SetActive(false);   
                break;
            case BlockShapeType.TriangularPrism:
            case BlockShapeType.Trapezoid:
                widthRadiusLabel.text = "Base Width:"; 
                break;
            case BlockShapeType.HalfCylinder:
                widthRadiusLabel.text = "Radius:";
                break;
        }

        sliderWidthRadius.SetValueWithoutNotify(block.widthOrRadius);
        sliderHeight.SetValueWithoutNotify(block.height);
        sliderLength.SetValueWithoutNotify(block.length);

        if(valWidthRadius != null) valWidthRadius.text = block.widthOrRadius.ToString("F0");
        if(valHeight != null) valHeight.text = block.height.ToString("F0");
        if(valLength != null) valLength.text = block.length.ToString("F0");
    }

    private void TryRecordSizeUndo()
    {
        if (!_hasRecordedSizeUndoThisSession && _currentBlock != null)
        {
            UndoManager.Instance.RecordCommand(new SizeCommand(_currentBlock, _wBefore, _hBefore, _lBefore));
            _hasRecordedSizeUndoThisSession = true; 
        }
    }

    public void OnWidthRadiusChanged(float val) 
    { 
        if(_currentBlock != null) { 
            TryRecordSizeUndo(); 
            _currentBlock.widthOrRadius = val; 
            _currentBlock.ApplyDimensions(); 
            if(valWidthRadius != null) valWidthRadius.text = val.ToString("F0"); 
        } 
    }
    
    public void OnHeightChanged(float val) 
    { 
        if(_currentBlock != null) { 
            TryRecordSizeUndo(); 
            _currentBlock.height = val; // <--- NO MORE SWAPPING!
            _currentBlock.ApplyDimensions(); 
            if(valHeight != null) valHeight.text = val.ToString("F0"); 
        } 
    }
    
    public void OnLengthChanged(float val) 
    { 
        if(_currentBlock != null) { 
            TryRecordSizeUndo(); 
            _currentBlock.length = val; // <--- NO MORE SWAPPING!
            _currentBlock.ApplyDimensions(); 
            if(valLength != null) valLength.text = val.ToString("F0"); 
        } 
    }

    public void ToggleColorPicker()
    {
        if (colorPickerContainer != null)
        {
            StopAllCoroutines();
            bool isTurningOn = !colorPickerContainer.activeSelf;
            
            if (isTurningOn)
            {
                _hasRecordedColorUndoThisSession = false;
                _colorBeforeEdit = _currentBlock.blockColor;

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
        if (_currentBlock != null)
        {
            if (!_hasRecordedColorUndoThisSession)
            {
                UndoManager.Instance.RecordCommand(new ColorCommand(_currentBlock, _colorBeforeEdit));
                _hasRecordedColorUndoThisSession = true;
            }
            _currentBlock.SetColor(newColor); 
            if (colorPreviewButton != null) colorPreviewButton.color = newColor; 
        }
    }

    public void DeleteBlock()
    {
        if (_currentBlock != null)
        {
            UndoManager.Instance.RecordCommand(new DeleteCommand(_currentBlock.gameObject, hierarchyManager));
            if (hierarchyManager != null) {
                hierarchyManager.RemoveBlockFromList(_currentBlock.gameObject);
            }
            _currentBlock.gameObject.SetActive(false);
            _currentBlock = null;
            propertiesPanel.SetActive(false);
            if (colorPickerContainer != null) colorPickerContainer.SetActive(false);
        }
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

        if(valWidthRadius != null) valWidthRadius.text = w.ToString("F0");
        if(valHeight != null) valHeight.text = h.ToString("F0");
        if(valLength != null) valLength.text = l.ToString("F0");
    }

    public void ClosePanel()
    {
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