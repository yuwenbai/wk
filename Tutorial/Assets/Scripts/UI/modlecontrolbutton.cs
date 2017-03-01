using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class modlecontrolbutton : MonoBehaviour {
    public GameObject player;
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    public void onDeathBtnClick()
    {
        Debug.Log("rextest onDeathBtnClick");
        Animator anim = player.GetComponent<Animator>();
        anim.SetBool("Died", true);
    }
}
