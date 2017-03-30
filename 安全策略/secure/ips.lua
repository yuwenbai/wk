
local ips = class("ips")

function ips:ctor(...)
	local args = {...}
	self.succeedCall = args[1]
	self.failedCall = args[2]
	self.uuid = args[3]
end

function ips:request()
	secure.log("ips request")
	self:reset()

	local srcSign = string.format("%s%s", self.uuid, secure.ips.servername)
	local sign = cc.UtilityExtension:generateMD5(srcSign, string.len(srcSign))
	local xhr = cc.XMLHttpRequest:new()
	xhr.timeout = 5
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local refreshTokenURL = string.format("http://secureapi.ixianlai.com/security/server/getIPbyZoneUid")
	xhr:open("POST", refreshTokenURL)
	local function onResp()
		secure.log("xhr.readyState = " .. xhr.readyState .. ", xhr.status = " .. xhr.status)
		secure.log("xhr.statusText = " .. xhr.statusText)
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			secure.log("ips response:" .. xhr.response)
			require("json")
			local respJson = json.decode(xhr.response)
			if respJson.errorCode == 0 then -- 服务器现在是 字符"0",应该修改为 数字0
				self.ip = respJson.ip
				if self.succeedCall then
					self.succeedCall(self)
				end
			else
				if self.failedCall then
					self.failedCall(self)
				end
			end
		elseif xhr.readyState == 1 and xhr.status == 0 then
			if self.failedCall then
				self:failedCall(self)
			end
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send(string.format("uuid=%s&servername=%s&sign=%s", self.uuid, secure.ips.servername, sign))
end

function ips:getIP()
	secure.log("ips getIP:" .. self.ip)
	return self.ip
end

function ips:getName()
	return "ips"
end

function ips:reset()
	self.ip = nil
end

return ips