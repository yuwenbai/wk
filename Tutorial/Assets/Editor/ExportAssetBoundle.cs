using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class ExportAssetBoundle {
    //在Unity编辑器中添加菜单  
    [MenuItem("Assets/Build AssetBundle From Selection")]
    static void ExportResourceRGB2()
    {
        // 打开保存面板，获得用户选择的路径  
        //string path = EditorUtility.SaveFilePanel("Save Resource", "", "New Resource", "assetbundle");

        //if (path.Length != 0)
        //{
        //    // 选择的要保存的对象  
        //    //Object[] selection = Selection.GetFiltered(typeof(Object), SelectionMode.DeepAssets);
        //    //打包  
        //    //BuildPipeline.BuildAssetBundle(Selection.activeObject, selection, path, BuildAssetBundleOptions.CollectDependencies | BuildAssetBundleOptions.CompleteAssets, BuildTarget.StandaloneWindows);
        //    //BuildPipeline.BuildAssetBundles("Assets/AssetBundles");
        //    BuildPipeline.BuildAssetBundles("Assets/AssetBundles", BuildAssetBundleOptions.None, BuildTarget.StandaloneWindows);
        //}
        Debug.Log("rextest 111");
        BuildPipeline.BuildAssetBundles("Assets/AssetBundles", BuildAssetBundleOptions.ChunkBasedCompression, BuildTarget.StandaloneWindows);
    }
}
