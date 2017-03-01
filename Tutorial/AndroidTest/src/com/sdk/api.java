package com.sdk;

import android.util.Log;
import com.rex.test.*;
/**
 * Created by rex on 2017/3/1.
 */

public class api {
    public  static void init(int flag){
        Log.i("Rextest", "init: ");
        MainActivity.myHandler.sendEmptyMessage(utils.sdkmsgtype.INIT.ordinal());
    }
    public  static void login(){
        Log.i("Rextest", "login: ");
        MainActivity.myHandler.sendEmptyMessage(utils.sdkmsgtype.LOGIN.ordinal());
    }
    public  static void logout(){
        Log.i("Rextest", "logout: ");
        MainActivity.myHandler.sendEmptyMessage(utils.sdkmsgtype.LOGOUT.ordinal());
    }
}
