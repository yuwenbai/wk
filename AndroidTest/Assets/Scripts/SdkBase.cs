using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SdkBase{
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    virtual public void init()
    {
        Debug.Log("rextest SdkBase ");
    }
    virtual public void login()
    {

    }
    virtual public void logout()
    {

    }
}
