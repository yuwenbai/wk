TestLua = {}
local this = TestLua;
function TestLua.ctor(aaa)
	self.m_aaa = aaa
end
function TestLua.Init(aaa)
	--logWarn("CtrlManager.Init----->>>");
	self.m_aaa = aaa
	return this;
end
function TestLua.TestLuaLog(aaa)
	LuaFramework.Util.Log(aaa);
end
function TestLua.CoutVariable()
	LuaFramework.Util.Log(self.m_aaa);
end