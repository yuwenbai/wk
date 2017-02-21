
TestLuaClass = {}
function TestLuaClass.ctor(x)
	LuaFramework.Util.Log("aaa");
end
function TestLuaClass:new ()
	o = {} -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	self.root = nil;
	return o
end
function TestLuaClass:Out(aaa)
	LuaFramework.Util.Log(aaa);
end