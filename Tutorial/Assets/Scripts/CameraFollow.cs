using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraFollow : MonoBehaviour {
    public GameObject Targetplayer;
    public int nDistance;
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void FixedUpdate () {
        Vector3 targetPos = Targetplayer.transform.position + new Vector3(0, 3, -6);
        gameObject.transform.position = Vector3.Lerp(gameObject.transform.position, targetPos, nDistance * Time.deltaTime);

    }
}
