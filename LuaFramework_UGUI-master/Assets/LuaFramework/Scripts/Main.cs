using UnityEngine;
using System.Collections;

namespace LuaFramework {

    /// <summary>
    /// </summary>
    public class Main : MonoBehaviour {

        void Start() {
            Debug.Log("string 111 " + "string 222");
            AppFacade.Instance.StartUp();   //启动游戏
        }
    }
}