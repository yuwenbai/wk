using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ButtonEvent : MonoBehaviour {
    // Use this for initialization
    void Start () {
        
    }
	
	// Update is called once per frame
	void Update () {
		
	}

    public void initBtnClick()
    {
        Debug.Log("rextest initBtnClick");
        Debug.Log("rextest initBtnClick111222");
       SdkMgr.Instance(). init();
        Debug.Log("rextest initBtnClick111");
    }
    public void loginBtnClick()
    {
        Debug.Log("rextest loginBtnClick");
    }
    public void logoutBtnClick()
    {
        Debug.Log("rextest logoutBtnClick");
    }


}
