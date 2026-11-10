using UnityEngine;
using UnityEngine.UI;
public class SandboxRowSize : MonoBehaviour
{
    public float baseHeight=64;
    public void Apply(float scale) { GetComponent<LayoutElement>().preferredHeight=baseHeight*Mathf.Max(1,scale); }
}
