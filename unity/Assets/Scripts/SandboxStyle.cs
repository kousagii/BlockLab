using UnityEngine;
using UnityEngine.UI;
using TMPro;

public enum SandboxColorRole { Surface, Background, Text, Muted, Accent, Border, Danger }
public class SandboxStyle : MonoBehaviour
{
    public SandboxColorRole role;
    public float textSize;
    public void Apply(bool dark, float textScale)
    {
        Color color;
        switch (role)
        {
            case SandboxColorRole.Background: color = Hex(dark ? "101A2B" : "F6F8FC"); break;
            case SandboxColorRole.Text: color = Hex(dark ? "E8EEF8" : "18243A"); break;
            case SandboxColorRole.Muted: color = Hex(dark ? "B7C4D9" : "52617A"); break;
            case SandboxColorRole.Accent: color = Hex(dark ? "AAC7FF" : "2858C6"); break;
            case SandboxColorRole.Border: color = Hex(dark ? "34445E" : "D9E1EF"); break;
            case SandboxColorRole.Danger: color = Hex(dark ? "FFB4AB" : "A52222"); break;
            default: color = Hex(dark ? "172338" : "FFFFFF"); break;
        }
        var graphic = GetComponent<Graphic>();
        if (graphic != null) graphic.color = color;
        var text = GetComponent<TMP_Text>();
        if (text != null && textSize > 0) text.fontSize = textSize * textScale;
    }
    public static Color Hex(string value) { ColorUtility.TryParseHtmlString("#" + value, out var color); return color; }
}
