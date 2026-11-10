using UnityEngine;
using TMPro;
using UnityEngine.UI;
using System.Collections.Generic; 

public class HierarchyManager : MonoBehaviour
{
    public int Count => _blockUIItems.Count;
    public GameObject itemPrefab;
    public Transform contentPanel; 

    public SelectionManager selectionManager;

    private Dictionary<GameObject, GameObject> _blockUIItems = new Dictionary<GameObject, GameObject>();
    private Dictionary<BlockShapeType, int> _shapeCounts = new Dictionary<BlockShapeType, int>();

    public void AddBlockToList(GameObject block)
    {
        if (block == null || itemPrefab == null || contentPanel == null || _blockUIItems.ContainsKey(block)) return;

        BlockData blockData = block.GetComponent<BlockData>();

        if (blockData != null && (string.IsNullOrEmpty(block.name) || block.name.Contains("(Clone)")))
        {
            if (!_shapeCounts.ContainsKey(blockData.shapeType))
            {
                _shapeCounts[blockData.shapeType] = 0;
            }
            
            _shapeCounts[blockData.shapeType]++;

            string shapeName = blockData.shapeType.ToString();

            if (blockData.shapeType == BlockShapeType.HalfCylinder)
            {
                shapeName = "Half Cylinder";
            }
            else if (blockData.shapeType == BlockShapeType.Trapezoid)
            {
                shapeName = "Trapezoid";
            }
            else if (blockData.shapeType == BlockShapeType.TriangularPrism)
            {
                shapeName = "Triangular Prism";
            }

            block.name = $"{shapeName} {_shapeCounts[blockData.shapeType]}";
        }

        GameObject newItem = Instantiate(itemPrefab, contentPanel);
        newItem.transform.localScale = Vector3.one;
        
        TMP_Text textComponent = newItem.GetComponentInChildren<TMP_Text>();
        if (textComponent != null) {
            textComponent.text = block.name;
        }

        Button button = newItem.GetComponent<Button>();
        if (button == null) button = newItem.AddComponent<Button>();

        button.onClick.AddListener(() => {
            if (selectionManager != null && blockData != null)
            {
                selectionManager.ForceSelectBlock(blockData);
            }
        });

        _blockUIItems.Add(block, newItem);
        FindObjectOfType<SandboxUIController>()?.StyleHierarchyItem(newItem);
        LayoutRebuilder.ForceRebuildLayoutImmediate(contentPanel.GetComponent<RectTransform>());
    }

    public void RemoveBlockFromList(GameObject block)
    {
        if (_blockUIItems.ContainsKey(block))
        {
            Destroy(_blockUIItems[block]);
            _blockUIItems.Remove(block);
        }
    }

    public void ClearHierarchyUI()
    {
        if (contentPanel != null)
        {
            foreach (Transform child in contentPanel) Destroy(child.gameObject);
        }
        _blockUIItems.Clear(); 
        _shapeCounts.Clear(); 
    }
}
