using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SdkForAndroid : SdkBase {
    private AndroidJavaClass jc;
    public SdkForAndroid():base(){
        Debug.Log("rextest SdkForAndroid ");
        jc = new AndroidJavaClass("com.sdk.api");
    }
    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    public override void init()
    {
        Debug.Log("rextest SdkForAndroid initBtnClick");
        jc.CallStatic("init");
    }
    public override void login()
    {


    }

    public override void logout()
    {

    }
}
