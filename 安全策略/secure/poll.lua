--require("app/secure/init")

local poll = class("poll")

local _instance = nil
function poll:getInstance()
	if not _instance then
		_instance = require("app/secure/poll"):new()
	end
	return _instance
end

function poll:ctor(...)
	self.polls = secure.polls
	self.pollIdx = 1
end

function poll:init(params)
	self.uuid = params.uuid
	self.succeedCall = params.succeedCall
	self.failedCall = params.failedCall
end

function poll:request()
	self:reset()
	self:nextState()
end

function poll:getCurIPState()
	return self.curIPState
end

function poll:nextState()
	if #self.polls <= 0 then
		secure.log("secure error: not config")
		return
	end

	if self.pollIdx > #self.polls then
		self.pollIdx = 1
	end

	local statename = self.polls[self.pollIdx]
	if statename == "ips" then
		self.curIPState = require("app/secure/ips").new(handler(self, self.onRespSucceed), handler(self, self.onRespFailed), self.uuid)
	elseif statename == "oss" then
		self.curIPState = require("app/secure/oss").new(handler(self, self.onRespSucceed), handler(self, self.onRespFailed), self.uuid)
	elseif statename == "gaofang" then
		self.curIPState = require("app/secure/gaofang").new(handler(self, self.onRespSucceed), handler(self, self.onRespFailed))
	end

	self.pollIdx = self.pollIdx + 1

	if self.curIPState then
		self.curIPState:request()
	end
end

function poll:reset()
	self.curIPState = nil
	self.pollIdx = 1
end

function poll:getIP()
	if self.curIPState then
		return self.curIPState:getIP()
	end
	return nil
end

function poll:savePlayCount(count)
	require("app/secure/oss").savePlayCount(count)
end

function poll:onRespSucceed(ipstate)
	if self.succeedCall then
		self.succeedCall(ipstate)
	end
end

function poll:onRespFailed(ipstate)
	secure.log(ipstate:getName() .. " request failed")
	self:nextState()
	if self.failedCall then
		self.failedCall(ipstate)
	end
end

return poll