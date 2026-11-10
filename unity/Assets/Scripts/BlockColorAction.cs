using UnityEngine;
public class BlockColorAction : MonoBehaviour {
    public PropertiesUIManager manager;
    public Color color=Color.white;
    public void Apply() { manager.OnFCPColorChanged(color); }
}
