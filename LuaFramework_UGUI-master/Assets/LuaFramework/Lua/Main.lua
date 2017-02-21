--主入口函数。从这里开始lua逻辑
require "Logic/TestLua"
require "Logic/TestLuaClass"
function Main()					
	 LuaFramework.Util.Log("HelloWorld1111111112223333");
	 local go = UnityEngine.GameObject ('go')
	 go.transform.position = Vector3.one
	 LuaFramework.Util.Log("HelloWorld11111111122233444");
	 LuaHelper = LuaFramework.LuaHelper;
     local resMgr = LuaHelper.GetResManager();
     local networkMgr = LuaHelper.GetNetManager()
	local nRandomNum = math.floor(100/10001)
     LuaFramework.Util.Log(nRandomNum.."what's fxxk");
	 resMgr:LoadPrefab('tank', { 'Panel1' }, OnLoadFinish);
	 LuaFramework.Util.Log("HelloWorld11111111122233666");
	 UpdateBeat:Add(Update, self)

    local AppConst = LuaFramework.AppConst
    AppConst.SocketPort = 1234;
    AppConst.SocketAddress = "127.0.0.1";
    networkMgr:SendConnect();
	-- TestLuaClass.ctor(20)
	local tlc = TestLuaClass:new()
	tlc:Out(123)
	local tlc = TestLuaClass:new()
	tlc:Out(234)
	local TestLuaA = TestLua.TestLuaLog("aaa")
	-- local TestLuaB = TestLua.TestLuaLog("bbb")
	-- TestLuaB.CoutVariable()
	-- TestLuaA.CoutVariable()

end
function Update()
	 -- LuaFramework.Util.Log("每帧执行一次");
end
--加载完成后的回调--
function OnLoadFinish(objs)
        local go = UnityEngine.GameObject.Instantiate(objs[0]);
		if go == nil then
				LuaFramework.Util.Log("Finish 11 ");
		else
			LuaFramework.Util.Log("Finish 22 ");
			local canvas = UnityEngine.GameObject.Find("Canvas")
			go.transform:SetParent(canvas.transform)
			go.transform.localScale = Vector3.one;
			go.transform.localPosition = Vector3.zero;
		end
        LuaFramework.Util.Log("Finish");
end

--场景切换通知
function OnLevelWasLoaded(level)
	collectgarbage("collect")
	Time.timeSinceLevelLoad = 0
end