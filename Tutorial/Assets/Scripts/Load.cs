using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
public class Load : MonoBehaviour {

    private string BundleURL = "file:///D:/AssetBundles/AssetBundles";
    private string SceneURL = "file:///D:/AssetBundles/111.unity3d";

    void Start()
    {
        //BundleURL = "file//"+Application.dataPath+"/cube.assetbundle";  

        string streamingAssetsPath = Application.streamingAssetsPath;
        Debug.Log(streamingAssetsPath);
        StartCoroutine(DownloadAssetAndScene());
    }

    IEnumerator DownloadAssetAndScene()
    {
        //下载assetbundle，加载Cube  
        using (WWW asset = new WWW(BundleURL))
        {
            AssetBundle mainAB = asset.assetBundle;
            AssetBundleManifest abm = (AssetBundleManifest)mainAB.LoadAsset("AssetBundleManifest");
            mainAB.Unload(false);
            if (abm == null)
            {
                Debug.Log("abm is null");
                yield return null;
            }
            else
            {
                string[] depNames = abm.GetAllAssetBundles();
                foreach (var name in depNames)
                    Debug.Log("AssetBundle: " + name);
                string[] dps = abm.GetAllDependencies("ball.hd");
                Debug.Log("dps length = " + dps.Length.ToString());
            }
        }
        //下载场景，加载场景  
        using (WWW scene = new WWW(SceneURL))
        {
            yield return scene;
            AssetBundle bundle = scene.assetBundle;
           SceneManager.LoadScene("GameScene");
        }

    }
}
