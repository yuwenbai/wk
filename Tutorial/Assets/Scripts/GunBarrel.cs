using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GunBarrel : MonoBehaviour {

    // Use this for initialization
    public float shootRate = 2;
    private float timer = 0;
    private ParticleSystem particlesystem;
    private LineRenderer lineRender;
	void Start () {
        timer = 0;
        particlesystem = GetComponentInChildren<ParticleSystem>();
        lineRender = GetComponent<Renderer>() as  LineRenderer;
    }
	
	// Update is called once per frame
	void Update () {
        timer += Time.deltaTime;
        if(timer> 1 / shootRate)
        {
            timer -= shootRate;
            ShootAction();
        }
	}
    void ShootAction()
    {
        Debug.Log("ShootAction");
        //transform.GetComponent<Light>().enabled = true;
        lineRender.enabled = true;
        lineRender.SetPosition(0, transform.position);
        Ray ray = new Ray(transform.position, transform.forward);
        RaycastHit hitInfo;
        if (Physics.Raycast(ray,out hitInfo))
        {
            lineRender.SetPosition(1, hitInfo.point);
        }
        else
        {
            lineRender.SetPosition(1, transform.position + transform.forward * 100);
        }
        //particlesystem.Play();
        Invoke("ClearEffect", 0.05f);
    }
    void ClearEffect()
    {
        Debug.Log("ClearEffect");
        lineRender.enabled = false;
        
        //transform.GetComponent<Light>().enabled = false;
    }

}
