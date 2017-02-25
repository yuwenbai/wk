using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Google.Protobuf;
using System.IO;
public class ButtonEvent : MonoBehaviour {
    public InputField mInputField;
    public Text mText;
    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}


    public void OnButtonClick()
    {
        Debug.Log("OnButtonClick "+ mInputField.text);
       // mText.text = mInputField.text;
        TheMsg msg = new TheMsg();
        msg.Name = mInputField.text;
        msg.Num = 32;
        //Debug.Log(string.Format("The Msg is ( Name:{0},Num:{1} )", msg.Name, msg.Num));
        byte[] bmsg;
        using (MemoryStream ms = new MemoryStream())
        {
            msg.WriteTo(ms);
            bmsg = ms.ToArray();
        }


        TheMsg msg2 = TheMsg.Parser.ParseFrom(bmsg);
        mText.text = msg2.Name;
    }
}
