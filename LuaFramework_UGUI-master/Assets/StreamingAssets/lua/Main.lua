--主入口函数。从这里开始lua逻辑
function Main()					
	 LuaFramework.Util.Log("HelloWorld1111111112223333");
	 local go = UnityEngine.GameObject ('go')
	 go.transform.position = Vector3.one
	 LuaFramework.Util.Log("HelloWorld11111111122233444");
	 LuaHelper = LuaFramework.LuaHelper;
     resMgr = LuaHelper.GetResManager();
     LuaFramework.Util.Log("HelloWorld11111111122233555");
	 resMgr:LoadPrefab('tank', { 'Tank' }, OnLoadFinish);
	 LuaFramework.Util.Log("HelloWorld11111111122233666");
	 UpdateBeat:Add(Update, self)
end
function Update()
	 LuaFramework.Util.Log("每帧执行一次");
end
--加载完成后的回调--
function OnLoadFinish(objs)
        local go = UnityEngine.GameObject.Instantiate(objs[0]);
        LuaFramework.Util.Log("Finish");        
end

--场景切换通知
function OnLevelWasLoaded(level)
	collectgarbage("collect")
	Time.timeSinceLevelLoad = 0
end