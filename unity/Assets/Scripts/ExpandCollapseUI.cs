using UnityEngine;
using System.Collections;

public class ExpandCollapseUI : MonoBehaviour
{
    public RectTransform panel;   
    public RectTransform arrow;  

    public float expandedHeight = 300f;
    public float collapsedHeight = 0f;
    public float animationSpeed = 5f;

    private bool expanded = true;
    private Coroutine currentAnimation;

    public void Toggle()
    {
        expanded = !expanded;

        if (currentAnimation != null)
            StopCoroutine(currentAnimation);

        float targetHeight = expanded ? expandedHeight : collapsedHeight;
        currentAnimation = StartCoroutine(AnimateHeight(targetHeight));

        if (arrow != null)
        {
            arrow.rotation = expanded ?
                Quaternion.Euler(0,0,180) :
                Quaternion.Euler(0,0,0);
        }
    }

    IEnumerator AnimateHeight(float targetHeight)
    {
        float startHeight = panel.sizeDelta.y;
        float time = 0f;

        while (Mathf.Abs(panel.sizeDelta.y - targetHeight) > 0.1f)
        {
            time += Time.deltaTime * animationSpeed;
            float newHeight = Mathf.Lerp(startHeight, targetHeight, time);

            panel.sizeDelta = new Vector2(panel.sizeDelta.x, newHeight);

            yield return null;
        }

        panel.sizeDelta = new Vector2(panel.sizeDelta.x, targetHeight);
    }
}