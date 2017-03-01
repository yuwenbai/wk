package com.rex.test;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import com.sdk.*;

/**
 * Created by rex on 2017/3/1.
 */

public class MainActivity extends UnityPlayerActivity{
    public static  Activity mcurrentActivity;
    @Override protected void onCreate (Bundle savedInstanceState)
    {
        Log.w("Unity", "UnityPlayerNativeActivity has been deprecated, please update your AndroidManifest to use UnityPlayerActivity instead");

        super.onCreate(savedInstanceState);

        mcurrentActivity = this;

    }

    public static Handler myHandler = new Handler(){
        public void handleMessage(Message msg) {
            Log.w("Unity","fffffff");
            if(msg.what == utils.sdkmsgtype.INIT.ordinal()){
                Log.w("Unity","INIT");
            }
            if(msg.what == utils.sdkmsgtype.INIT.ordinal()){
                Log.w("Unity","LOGIN");
            }
            if(msg.what == utils.sdkmsgtype.INIT.ordinal()){
                Log.w("Unity","LOGOUT");
            }
        }
    };
}
