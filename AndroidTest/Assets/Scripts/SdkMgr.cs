using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SdkMgr : MonoBehaviour {
    private SdkBase mSdkApi;
    private static SdkMgr mInstance;

    public static SdkMgr Instance() { return mInstance; }
    private void Awake()
    {
        mInstance = this;
        Debug.Log("rextest 111");
#if UNITY_EDITOR
        Debug.Log("rextest 222");
        mSdkApi = new SdkForAndroid();
#elif UNITY_ANDROID
        Debug.Log("rextest 333");
        mSdkApi = new SdkForAndroid();
#endif
    }
    // Use this for initialization
    void Start () {
		
	}

    public void init()
    {
        Debug.Log("rextest 222222");
        if(mSdkApi == null)
        {
            Debug.Log("rextest 2222222222");
        }
        mSdkApi.init();
        Debug.Log("rextest 122211");
    }
    public void login()
    {
        mSdkApi.login();
    }
   public void logout()
    {
        mSdkApi.logout();
    }

    // Update is called once per frame
    void Update () {
		
	}
}
