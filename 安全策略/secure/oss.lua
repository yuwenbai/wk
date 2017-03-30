local oss = class("oss")

oss.name_s = "d8dbfeeaf12"
oss.name_e = "25f1fd508b1"

function oss:ctor(...)
	local args = {...}
	self.succeedCall = args[1]
	self.failedCall = args[2]
	self.unionid = args[3]
	self.chu_wan = 5
	self.zhong_wan = 6
	self.gao_wan = 7
	self.gu_wan = 8
end

function oss:getName()
	return "oss"
end

function oss:request()
	secure.log("oss request")
	self:reset()

	local playCount = tonumber(self:getPlayCount())
	if playCount ~= nil then
		local filename = nil
		local num = 0
		if playCount < 21 then
			num = self.chu_wan
		elseif playCount < 51 then
			num = self.zhong_wan
		elseif playCount < 101 then
			num = self.gao_wan
		else
			num = self.gu_wan
		end
		secure.log("oss playCount = " .. num)
		if num > 0 and num < 9 then
			filename = self:getFileByNum(num)
			if filename then
				secure.log("oss filename = " .. filename)
				self:getYoYoFile(filename)
				return true
			end
		end
	else
		if self.failedCall then
			self.failedCall(self)
		end
	end
end

function oss:getPlayCount()
	local playCount = cc.UserDefault:getInstance():getStringForKey("yoyo_name")
	if playCount ~= "" then
		local s = string.find(playCount, oss.name_s)
		local e = string.find(playCount, oss.name_e)
		if s and e then
			return string.sub(playCount, s + string.len(oss.name_s), e - 1)
		end
	end
	return 0
end

function oss.savePlayCount(count)
	local name = oss.name_s .. count .. oss.name_e
	cc.UserDefault:getInstance():setStringForKey("yoyo_name", name)
end

function oss:getAscii(uuid)
	if not uuid then
		return 1
	end
	local ascii = string.byte(string.sub(uuid, #uuid - 1))
	return (ascii % 4) + 1
end

function oss:getFileByNum(num)
	local filename = "s_1_3_1_4_" .. num .. "_2_4_3"
	local md5 = cc.UtilityExtension:generateMD5(filename, string.len(filename))
	local url = "http://allgame.ixianlai.com/" .. secure.ips.servername .. "_" .. md5 .. "_" .. num .. "_.txt"
	return url
end

function oss:getYoYoFile(filename)
	if self.xhr == nil then
        self.xhr = cc.XMLHttpRequest:new()
        self.xhr:retain()
        self.xhr.timeout = 10 -- 设置超时时间
    end
    self.xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    local refreshTokenURL = filename
    self.xhr:open("GET", refreshTokenURL)
    self.xhr:registerScriptHandler(handler(self, self.onYoYoResp))
    self.xhr:send()
end

function oss:onYoYoResp()
	-- 默认高防
    if self.xhr.readyState == 4 and (self.xhr.status >= 200 and self.xhr.status < 207) then
        self.dataRecv = self.xhr.response -- 获取到数据
        local data = tostring(self.xhr.response)
        if data then
        	secure.log("oss response:" .. data)
			local ipTab = string.split(data, ".")
			if #ipTab == 4 then -- 正确的ip地址
				self.ip = data
				self.xhr:unregisterScriptHandler()
				if self.succeedCall then
					self.succeedCall(self)
				end
			else
				if self.failedCall then
					self.failedCall(self)
				end
			end
        end
    elseif self.xhr.readyState == 1 and self.xhr.status == 0 then
        -- 网络问题,异常断开
        if self.failedCall then
			self.failedCall(self)
		end
    end
    self.xhr:unregisterScriptHandler()
end

function oss:getIP()
	secure.log("oss getIP:" .. self.ip)
	return self.ip
end

function oss:reset()
	self.ip = nil
end

return oss