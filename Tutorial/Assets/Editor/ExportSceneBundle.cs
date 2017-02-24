using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class ExportSceneBundle  {

    [MenuItem("Assets/Save Scene")]
    static void ExportScene()
    {
        // 打开保存面板，获得用户选择的路径  
        string path = EditorUtility.SaveFilePanel("Save Resource", "", "New Resource", "unity3d");

        if (path.Length != 0)
        {
            // 选择的要保存的对象  
            Object[] selection = Selection.GetFiltered(typeof(Object), SelectionMode.DeepAssets);
            string[] scenes = { "Assets/Scenes/GameScene.unity" };
            //打包  
            BuildPipeline.BuildPlayer(scenes, path, BuildTarget.StandaloneWindows, BuildOptions.BuildAdditionalStreamedScenes);
        }
    }
}
