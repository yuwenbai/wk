using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerHealth : MonoBehaviour {
    private float hp_max = 100;
    private Animator anim;
    private ShooterMove shootermove;
    private SkinnedMeshRenderer bodymeshrander;
    // Use this for initialization
    void Awake()
    {
        bodymeshrander = transform.Find("Player").GetComponent<Renderer>() as SkinnedMeshRenderer;
    }
    void Start () {
        anim = transform.GetComponent<Animator>();
        shootermove = transform.GetComponent<ShooterMove>();
    }
	
	// Update is called once per frame
	void Update () {
        if (Input.GetMouseButtonDown(1))
        {
            takeDamage(30);
        }
        bodymeshrander.material.color = Color.Lerp(bodymeshrander.material.color, Color.white, 5.0f*Time.deltaTime);

    }

    void takeDamage(float hp)
    {
        if (hp_max <= 0)
            return;
        bodymeshrander.material.color = Color.red;
        hp_max -= hp;
        if(hp_max <= 0)
        {
            hp_max = 0;
            anim.SetBool("Died", true);
            Death();
        }
    }
    void Death()
    {
        shootermove.enabled = false;
    }
}
