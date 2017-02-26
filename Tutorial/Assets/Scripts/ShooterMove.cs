using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShooterMove : MonoBehaviour {
    public float speed = 5.0f;
    public Animator anim;
	// Use this for initialization
	void Start () {
        anim = gameObject.GetComponent<Animator>();

    }
	
	// Update is called once per frame
	void Update () {
        float h = Input.GetAxis("Horizontal");
        float w = Input.GetAxis("Vertical");
        //gameObject.transform.Translate(new Vector3(h, 0, w)*Time.deltaTime);
        gameObject.GetComponent<Rigidbody>().MovePosition(gameObject.transform.position + new Vector3(h, 0, w) * Time.deltaTime);
        if(w!=0 || h != 0)
        {
            anim.SetBool("Move", true);
            bool bMove = anim.GetBool("Move");
            //Debug.Log("move state is " + bMove);
        }else
        {
            anim.SetBool("Move", false);
            bool bMove = anim.GetBool("Move");
            //Debug.Log("move state is " + bMove);
        }
    }
}
