using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class ZombunnyMove : MonoBehaviour {
    private NavMeshAgent navMesh;
    public GameObject targetPlayer;
    // Use this for initialization
    void Start () {
        navMesh = GetComponent<NavMeshAgent>();
        
    }
	
	// Update is called once per frame
	void Update () {
        navMesh.SetDestination(targetPlayer.transform.position);
    }
}
