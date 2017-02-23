using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player : MonoBehaviour {

    private bool bIsLand = true;

    protected float jump_speed = 5.0f;
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
        if (Input.GetMouseButtonUp(0))
        {
            bIsLand = false;
            GetComponent<Rigidbody>().velocity = Vector3.up * jump_speed;
        }
	}

    void OnCollisionEnter(Collision collision)
    {
        Debug.Log("rextest onCollisionEnter!!!" + collision.gameObject.tag);
        bIsLand = true;
       // Debug.Break();
    }
}
