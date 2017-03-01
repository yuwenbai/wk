using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShooterMove : MonoBehaviour {
    public float speed = 5.0f;
    public Animator anim;
    private int nGroundIndex = -1;
	// Use this for initialization
	void Start () {
        anim = gameObject.GetComponent<Animator>();
        nGroundIndex = LayerMask.GetMask("ground");
    }
	
	// Update is called once per frame
	void Update () {
        float h = Input.GetAxis("Horizontal");
        float w = Input.GetAxis("Vertical");
        if (Camera.main)
        {

        }
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
        RaycastHit hitInfo;
        if (Physics.Raycast(ray, out hitInfo, 1000, nGroundIndex))
        {
            Vector3 target = hitInfo.point;
            target.y = transform.position.y;
            transform.LookAt(target);
        }

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
