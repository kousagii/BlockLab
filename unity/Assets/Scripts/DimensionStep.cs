using UnityEngine;
using UnityEngine.UI;
public class DimensionStep : MonoBehaviour {
    public Slider slider;
    public int step;
    public void Apply() { slider.value+=step; }
}
