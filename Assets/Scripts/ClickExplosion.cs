using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class ClickExplosion : MonoBehaviour, IPointerClickHandler
{

    protected SpriteRenderer spriteRenderer;
    protected Material material;
    protected static Shader shader;

    [SerializeField] float explodeSpeed = 2.0f;
    [SerializeField] float tessFactor = 5.0f;

    private bool canClick = true;

    void Start()
    {
        spriteRenderer = GetComponent<SpriteRenderer>();
        material = new Material(spriteRenderer.material);
        spriteRenderer.material = material;
        if (shader == null)
        {
            shader = Shader.Find("Custom/ExplosionShader");
        }
    }

    void Update()
    {
        
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        if (!canClick) return;

        material.shader = shader;
        material.SetFloat("_StartTime", Time.timeSinceLevelLoad);
        material.SetVector("_Center", transform.position);
        material.SetFloat("_Speed", explodeSpeed);
        material.SetFloat("_TessFactor", tessFactor);

        canClick = false;
    }
}
