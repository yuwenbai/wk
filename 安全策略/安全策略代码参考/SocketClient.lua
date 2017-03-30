-- Creator ArthurSong
-- Create Time 2016/1/29

local gt = cc.exports.gt

local bit = require("app/libs/bit")

require("app/protocols/MessageInit")
require("socket")

local SocketClient = class("SocketClient")

function SocketClient:ctor()
	-- 加载消息打包库
	local msgPackLib = require("app/libs/MessagePack")
	msgPackLib.set_number("integer")
	msgPackLib.set_string("string")
	msgPackLib.set_array("without_hole")
	self.msgPackLib = msgPackLib

	self:initSocketBuffer()

	-- 断线重连超时时间, 同时用做后台唤醒后重连检测时间, 不要随意修改
	gt.resume_time = 8

	-- 发送消息缓冲
	self.sendMsgCache = {}

	-- 注册消息逻辑处理函数回调
	self.rcvMsgListeners = {}

	-- 收发消息超时
	self.isCheckTimeout = false
	self.timeDuration = 0

	-- 是否已经弹出网络错误提示
	self.isPopupNetErrorTips = false

	-- 登录到服务器标识
	self.isStartGame = false

	-- 心跳消息重连时间
	self.heatTime = 4
	-- 发送心跳时间
	self.heartbeatCD = self.heatTime

	-- 检测是否有网络最大时间(秒)
	self.checkInternetMaxTime = 0.5
	-- 检测是否有网络时间
	self.checkInternetTime = self.checkInternetMaxTime
	-- 上次网络状态, 当前网络状态
	self.internetLastStatus = ""
	self.internetCurStatus = ""


	-- 心跳回复时间间隔
	-- 上一次时间间隔
	self.lastReplayInterval = 0
	-- 当前时间间隔
	self.curReplayInterval = 0

	-- 游戏中如果重连了3次,那么直接重连高防ip
	self.totalReconnectTime = 0

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	-- 检测是否为1.0.17以上的版本
	self.isVersion1017 = self:checkVersion(1, 0, 17)

	-- 登录状态,有三次自动重连的机会
	self.loginReconnectNum = 0
	self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)
	gt.registerEventListener(gt.EventType.NETWORK_ERROR, self, self.networkErrorEvt)

	-- 给下级代理变成vip
	self:registerMsgListener(gt.GC_PLAYER_TYPE, self, self.onPlayerTypeCallback)
	self:registerMsgListener(gt.GC_LUCKY_DRAW_NUM, self, self.onLuckyDrawNumCallback)
end

function SocketClient:initSocketBuffer()
	-- 发送消息缓冲
	self.sendMsgCache = {}
	self.sendingBuffer = ""
	self.remainSendSize = 0
	
	self.msgHeadSize = 12
	-- 接收消息
	self.recvingBuffer = ""
	self.remainRecvSize = self.msgHeadSize --剩余多少数据没有接受完毕,2:头部字节数
	self.recvState = "Head"
end

-- start --
--------------------------------
-- @class function
-- @description 和指定的ip/port服务器建立socket链接
-- @param serverIp 服务器ip地址
-- @param serverPort 服务器端口号
-- @param isBlock 是否阻塞
-- @return socket链接创建是否成功
-- end --
function SocketClient:connect(serverIp, serverPort, isBlock)
	if not serverIp or not serverPort then
		gt.log("serverIp or serverPort = nil")
		return
	end

	self:initSocketBuffer()

	self.serverIp = serverIp
	self.serverPort = serverPort
	self.isBlock = isBlock

	-- tcp 协议 socket
	-- local tcpConnection, errorInfo = socket.tcp()
	gt.log("SocketClient:connect serverIp = " .. serverIp .. ", serverPort = " .. serverPort)
	local tcpConnection, errorInfo = self:getTcp(serverIp)
 	if not tcpConnection then
		gt.log(string.format("Connect failed when creating socket | %s", errorInfo))
		gt.dispatchEvent(gt.EventType.NETWORK_ERROR, errorInfo)
		return false
	end
	self.tcpConnection = tcpConnection
	-- disables the Nagle's algorithm
	tcpConnection:setoption("tcp-nodelay", true)
	-- 和服务器建立tcp链接
	tcpConnection:settimeout(isBlock and 8 or 0)
	local connectCode, errorInfo = tcpConnection:connect(serverIp, serverPort)
	-- print("=======新的ip，端口2",self.serverIp, self.serverPort,connectCode, errorInfo)
	if connectCode == 1 then
		self.isConnectSucc = true
		gt.log("Socket connect success!")
	else
		gt.log(string.format("Socket %s Connect failed | %s", (isBlock and "Blocked" or ""), errorInfo))
		gt.dispatchEvent(gt.EventType.NETWORK_ERROR, errorInfo)
		return false
	end
	self.tcpConnection:settimeout(0)
	-- if not self.scheduleHandler then
	-- 	self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)
	-- end
	return true
end

function SocketClient:checkVersion(_bai, _shi, _ge)
	local ok, appVersion = nil
	if gt.isIOSPlatform() then
		ok, appVersion = self.luaBridge.callStaticMethod("AppController", "getVersionName")
	elseif gt.isAndroidPlatform() then
		ok, appVersion = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
	end
	local versionNumber = string.split(appVersion, '.')
	if tonumber(versionNumber[1]) > _bai
		or tonumber(versionNumber[2]) > _shi
		or tonumber(versionNumber[3]) > _ge then
		return true
	end
	return false
end

function SocketClient:connectResume()
	if gt.isDebugPackage and gt.debugInfo and not gt.debugInfo.YunDun and not gt.isSimulateLogin then
		self.serverIp = gt.debugInfo.ip
		self.serverPort = gt.debugInfo.port
		self:connect(self.serverIp, self.serverPort, self.isBlock)
		self:reLogin()
	else
		if not self.isResumeFlag then
			self.isResumeFlag = true
			secure.poll:request()
		else
			secure.poll:nextState()
		end
	end
	return true
end

-- start --
--------------------------------
-- @class function
-- @description 关闭socket链接
-- end --
function SocketClient:close()
	if self.tcpConnection then
		self.tcpConnection:close()
	end
	self.tcpConnection = nil
	self.isConnectSucc = false
	self.sendMsgCache = {}

	self.isCheckTimeout = false
	self.isPopupNetErrorTips = false

	gt.log("Socket close connect!")
end

-- 进行一些必须的善后处理,更包的时候,再把清理定时器等拿到这个函数内
function SocketClient:clearSocket()
	-- 游戏中如果重连了3次,那么直接重连高防ip
	self.totalReconnectTime = 0
	-- 登录状态,有三次自动重连的机会
	self.loginReconnectNum = 0
end

-- start --
--------------------------------
-- @class function
-- @description 发送消息放入到缓冲,非真正的发送
-- @param msgTbl 消息体
-- end --
function SocketClient:sendMessage(msgTbl)
	-- if msgTbl.m_msgId ~= 15 and msgTbl.m_msgId ~= 16 then
	-- 	dump(msgTbl)
	-- end

	-- 打包成messagepack格式
	local msgPackData = self.msgPackLib.pack(msgTbl)
	local msgLength = string.len(msgPackData)
	local len = self:luaToCByShort(msgLength)

	local curTime = os.time()
	local time = self:luaToCByInt(curTime)
	local msgId = self:luaToCByInt(msgTbl.m_msgId * ((curTime % 10000) + 1))
	local checksum = self:getCheckSum(time .. msgId, msgLength, msgPackData)
	local msgToSend = len .. checksum .. time .. msgId .. msgPackData

	
	-- 放入到消息缓冲
	table.insert(self.sendMsgCache, msgToSend)
end

function SocketClient:getCheckSum(time, msgLength, msgPackData)
	local crc = ""
	local len = string.len(time) + msgLength
	if len < 8 then
		crc = self:CRC(time .. msgPackData, len)
	else
		crc = self:CRC(time .. msgPackData, 8)
	end
	return self:luaToCByShort(crc)
end

function SocketClient:luaToCByShort(value)
	return string.char(value % 256) .. string.char(math.floor(value / 256))
end

function SocketClient:luaToCByInt(value)
	local lowByte1 = string.char(math.floor(value / (256 * 256 * 256)))
	local lowByte2 = string.char(math.floor(value / (256 * 256)) % 256)
	local lowByte3 = string.char(math.floor(value / 256) % 256)
	local lowByte4 = string.char(value % 256)
	return lowByte4 .. lowByte3 .. lowByte2 .. lowByte1
end

function SocketClient:CRC(data, length)
    local sum = 65535
    for i = 1, length do
        local d = string.byte(data, i)    -- get i-th element, like data[i] in C
        sum = self:ByteCRC(sum, d)
    end
    return sum
end

function SocketClient:ByteCRC(sum, data)
    -- sum = sum ~ data
    local sum = bit:_xor(sum, data)
    for i = 0, 3 do     -- lua for loop includes upper bound, so 7, not 8
        -- if ((sum & 1) == 0) then
        if (bit:_and(sum, 1) == 0) then
            sum = sum / 2
        else
            -- sum = (sum >> 1) ~ 0xA001  -- it is integer, no need for string func
            sum = bit:_xor((sum / 2), 0x70B1)
        end
    end
    return sum
end

function SocketClient:send()
	if not self.isConnectSucc or not self.tcpConnection then
		-- 链接未建立
		return false
	end

	if #self.sendMsgCache <= 0 then
		return true
	end

	-- dump(self.sendMsgCache)
	
	local sendSize = 0
	local errorInfo = ""
	local sendSizeWhenError = 0
	if self.remainSendSize > 0 then --还有剩余的数据没有发送完毕，接着发送
		local totalSize = string.len(self.sendingBuffer)
		local beginPos = totalSize - self.remainSendSize + 1
		sendSize, errorInfo, sendSizeWhenError = self.tcpConnection:send(self.sendingBuffer, beginPos)
	else
		self.sendingBuffer = self.sendMsgCache[1]
		self.remainSendSize = string.len(self.sendingBuffer)
		sendSize, errorInfo, sendSizeWhenError = self.tcpConnection:send(self.sendingBuffer)
	end
	
	if errorInfo == nil then
		self.remainSendSize = self.remainSendSize - sendSize
		if self.remainSendSize == 0 then  --说明已经发送完毕
			table.remove(self.sendMsgCache, 1)  --移除第一个
			self.sendingBuffer = ""
			-- gt.log("sendSize = " .. sendSize)
			
			-- self.isCheckTimeout = true
			-- self.timeDuration = 0
		end
	else
		if errorInfo == "timeout" then --由于是异步socket，并且timeout为0，luasocket则会立即返回不会继续等待socket可写事件
			if sendSizeWhenError ~= nil and sendSizeWhenError > 0 then
				self.remainSendSize = self.remainSendSize - sendSizeWhenError

				gt.log("Send time out. Had sent size:" .. sendSizeWhenError)
			end
		else
			gt.log("Send failed errorInfo:" .. errorInfo)
			return false
		end
	end
		
	return true
end

-- start --
--------------------------------
-- @class function
-- @description 接收消息并且分发到注册的消息回调
-- end --
-- function SocketClient:receive()
-- 	if not self.isConnectSucc or not self.tcpConnection then
-- 		-- 链接未建立
-- 		return false
-- 	end

-- 	-- local rcvContent, errorInfo = self.tcpConnection:receive(8)
-- 	local rcvContent, errorInfo = self.tcpConnection:receive(2)
-- 	if not rcvContent then
-- 		-- gt.log("SocketClient receive nothing!")
-- 		return
-- 	end
-- 	local needRcvSize = string.byte(rcvContent, 2) * 256 + string.byte(rcvContent, 1)
-- 	gt.log("Need receive message size: " .. needRcvSize)
-- 	local rcvBuffer = ""
-- 	rcvBuffer = self:receiveBuffer(needRcvSize, rcvBuffer)
-- 	-- 解包成lua表结构
-- 	local rcvMsgData = self.msgPackLib.unpack(rcvBuffer)
-- 	dump(rcvMsgData)
-- 	-- 终止检测网络超时
-- 	self.isCheckTimeout = false
-- 	-- 分发消息
-- 	self:dispatchMessage(rcvMsgData)
-- end
function SocketClient:receive()
	if not self.isConnectSucc or not self.tcpConnection then
		-- 链接未建立
		return
	end
	
	local messageQueue = {}
	-- self:receiveMessage(messageQueue)
	self.tcpConnection:settimeout(0)
	if not self:receiveMessage(messageQueue) then
		self:reloginServer()
		return
	end
	
	if #messageQueue <= 0 then
		return
	end

	-- gt.log("Recv meesage package:" .. #messageQueue)
	
	for i,v in ipairs(messageQueue) do
		-- if v.m_msgId ~= 15 and v.m_msgId ~= 16 then
		-- 	dump(v)
		-- end
		self:dispatchMessage(v)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 接收消息内容
-- @param sizeLeft 剩余字节数
-- @param buffer 缓冲区
-- @return 接收的消息体
-- end --
-- function SocketClient:receiveBuffer(sizeLeft, buffer)
-- 	if sizeLeft <= 0 then
-- 		return buffer
-- 	end
-- 	local rcvContent, errorInfo, partialContent = self.tcpConnection:receive(sizeLeft)
-- 	if errorInfo == "closed" then
-- 		gt.log("Socket closed!")
-- 		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR, errorInfo)
-- 		return nil
-- 	elseif errorInfo == "timeout" then
-- 		gt.log("Socket receive timeout!")
-- 		-- buffer = buffer .. partialContent
-- 		-- return self:receiveBuffer(sizeLeft - #partialContent, buffer)
-- 		-- gt.dispatchEvent(gt.EventType.NETWORK_ERROR)
-- 		return nil
-- 	else
-- 		gt.log("Success receive size: " .. #rcvContent)
-- 		buffer = buffer .. rcvContent
-- 		return self:receiveBuffer(sizeLeft - #rcvContent, buffer)
-- 	end
-- end

function SocketClient:receiveMessage(messageQueue)
	if self.remainRecvSize <= 0 then
		return true
	end

	local recvContent,errorInfo,otherContent = self.tcpConnection:receive(self.remainRecvSize)
	if errorInfo ~= nil then
		if errorInfo == "timeout" then --由于timeout为0并且为异步socket，不能认为socket出错
			if otherContent ~= nil and #otherContent > 0 then
				self.recvingBuffer = self.recvingBuffer .. otherContent
				self.remainRecvSize = self.remainRecvSize - #otherContent

				gt.log("recv timeout, but had other content. size:" .. #otherContent)
			end
			
			return true
		else	--发生错误，这个点可以考虑重连了，不用等待heartbeat
			gt.log("Recv failed errorinfo:" .. errorInfo)
			return false
		end
	end
	
	local contentSize = #recvContent
	self.recvingBuffer = self.recvingBuffer .. recvContent
	self.remainRecvSize = self.remainRecvSize - contentSize

	-- gt.log("success recv size:" .. contentSize ..  "   remainRecvSize is:" .. self.remainRecvSize)
	
	if self.remainRecvSize > 0 then	--等待下次接收
		return true
	end
	
	if self.recvState == "Head" then
		self.remainRecvSize = string.byte(self.recvingBuffer, 2) * 256 + string.byte(self.recvingBuffer, 1)
		self.recvingBuffer = ""
		self.recvState = "Body"
	elseif self.recvState == "Body" then
		local messageData = self.msgPackLib.unpack(self.recvingBuffer)
		table.insert(messageQueue, messageData)
		self.remainRecvSize = self.msgHeadSize  --下个包头
		self.recvingBuffer = ""
		self.recvState = "Head"
	end

	--继续接数据包
	--如果有大量网络包发送给客户端可能会有掉帧现象，但目前不需要考虑，解决方案可以1.设定总接收时间2.收完body包就不在继续接收了
	return self:receiveMessage(messageQueue)
end

-- start --
--------------------------------
-- @class function
-- @description 注册msgId消息回调
-- @param msgId 消息号
-- @param msgTarget
-- @param msgFunc 回调函数
-- end --
function SocketClient:registerMsgListener(msgId, msgTarget, msgFunc)
	-- if not msgTarget or not msgFunc then
	-- 	return
	-- end
	self.rcvMsgListeners[msgId] = {msgTarget, msgFunc}
end

-- start --
--------------------------------
-- @class function
-- @description 注销msgId消息回调
-- @param msgId 消息号
-- end --
function SocketClient:unregisterMsgListener(msgId)
	self.rcvMsgListeners[msgId] = nil
end

-- start --
--------------------------------
-- @class function
-- @description 分发消息
-- @param msgTbl 消息表结构
-- end --
function SocketClient:dispatchMessage(msgTbl)
	local rcvMsgListener = self.rcvMsgListeners[msgTbl.m_msgId]
	-- if msgTbl.m_msgId == gt.GC_PLAYER_TYPE then
		-- dump(rcvMsgListener)
	-- end
	if rcvMsgListener then
		rcvMsgListener[2](rcvMsgListener[1], msgTbl)
	else
		gt.log("Could not handle Message " .. tostring(msgTbl.m_msgId))
	end
end

function SocketClient:setIsStartGame(isStartGame)
	self.isStartGame = isStartGame

	self.loginReconnectNum = 10

	-- 心跳消息回复
	self:registerMsgListener(gt.GC_HEARTBEAT, self, self.onRcvHeartbeat)
end

-- start --
--------------------------------
-- @class function
-- @description 向服务器发送心跳
-- @param isCheckNet 检测和服务器的网络连接
-- end --
function SocketClient:sendHeartbeat(isCheckNet)
	if not self.isStartGame then
		return
	end

	local msgTbl = {}
	msgTbl.m_msgId = gt.CG_HEARTBEAT
	self:sendMessage(msgTbl)

	self.curReplayInterval = 0

	self.isCheckNet = isCheckNet
	if isCheckNet then
		-- 防止重复发送心跳,直接进入等待回复状态
		self.heartbeatCD = -1
	end
	-- print("========发送心跳时间",os.time())
end

-- start --
--------------------------------
-- @class function
-- @description 服务器回复心跳
-- @param msgTbl
-- end --
function SocketClient:onRcvHeartbeat(msgTbl)
	self.heartbeatCD = self.heatTime
	self.lastReplayInterval = self.curReplayInterval
	-- print("========发送回复时间",os.time())
end

-- start --
--------------------------------
-- @class function
-- @description 获取上一次心跳回复时间间隔用来判断网络信号强弱
-- @return 上一次心跳回复时间间隔
-- end --
function SocketClient:getLastReplayInterval()
	return self.lastReplayInterval
end

function SocketClient:checkIsInternet(delta)
	if not self.isVersion1017 then
		return true
	end

	if not self.isStartGame then
		return true
	end

	self.checkInternetTime = self.checkInternetTime - delta
	if self.checkInternetTime < 0 then
		self.checkInternetTime = self.checkInternetMaxTime
		local ok = false
		-- 保存上一次状态
		self.internetLastStatus = self.internetCurStatus
		if gt.isIOSPlatform() then
			-- 获取新的状态
			ok, self.internetCurStatus = self.luaBridge.callStaticMethod(
				"AppController", "getInternetStatus", nil)
		elseif gt.isAndroidPlatform() then
			ok, self.internetCurStatus = self.luaBridge.callStaticMethod(
				"org/cocos2dx/lua/AppActivity", "getCurrentNetworkType", nil, "()Ljava/lang/String;")
		end
		if self.internetLastStatus == "Not" and self.internetCurStatus ~= "Not" then
			self.curReplayInterval = gt.resume_time
			gt.removeLoadingTips()
			gt.log("已获取网络,重新登录!")
		end
		if self.internetCurStatus == "Not" and self.internetLastStatus ~= "Not" then
			gt.removeLoadingTips()
			gt.showLoadingTips(gt.getLocationString("LTKey_0001"))
			gt.log("请检查网络!")
			return false
		end
	end
	-- 当上一次状态为空, 则保留上一次状态
	if self.internetCurStatus == "Not" then
		return false
	end
	return true
end

function SocketClient:update(delta)
	local isInternet = self:checkIsInternet(delta)
	if not isInternet then
		return false
	end

	self:receive()
	self:send()

	if self.isStartGame then
		if self.heartbeatCD >= 0 then
			-- 登录服务器后开始发送心跳消息
			self.heartbeatCD = self.heartbeatCD - delta
			if self.heartbeatCD < 0 then
				-- 发送心跳
				self:sendHeartbeat(true)
			end
		else
			-- 心跳回复时间间隔
			self.curReplayInterval = self.curReplayInterval + delta
			if self.isCheckNet and self.curReplayInterval >= gt.resume_time then
				gt.log("断线重连开始 self.curReplayInterval = " .. self.curReplayInterval .. ", gt.resume_time = " .. gt.resume_time)
				gt.resume_time = 8
				self.isCheckNet = false
				-- 心跳时间稍微长一些,等待重新登录消息返回
				self.heartbeatCD = self.heatTime
				-- 监测网络状况下,心跳回复超时发送重新登录消息
				self:reloginServer()
			end
		end
	end
end

function SocketClient:reloginServer()
	gt.removeLoadingTips()
	gt.showLoadingTips(gt.getLocationString("LTKey_0001"))

	-- 链接关闭重连
	self:close()
	self.serverPort = gt.LoginServer.port
	return self:connectResume()
end

function SocketClient:reLogin()
	local runningScene = display.getRunningScene()
	if runningScene and runningScene["reLogin"] then
		runningScene:reLogin()
	end
end

function SocketClient:networkErrorEvt(eventType, errorInfo)
	gt.log("networkErrorEvt errorInfo:" .. errorInfo)
	if self.isPopupNetErrorTips then
		return
	end

	if self.isStartGame then
		return
	end

	local tipInfoKey = "LTKey_0047"
	if errorInfo == "connection refused" then
		-- 连接被拒提示服务器维护中
		tipInfoKey = "LTKey_0002"
	end

	if self.loginReconnectNum < 3 and self.isStartGame == false then
		self.loginReconnectNum = self.loginReconnectNum + 1
		self:connectResume()
		return
	end

	self.isPopupNetErrorTips = true

	require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString(tipInfoKey),
		function()
			self.isPopupNetErrorTips = false
			gt.removeLoadingTips()

			if errorInfo == "timeout" then
				-- 检测网络连接
				self:sendHeartbeat(true)
			end
		end, nil, true)
end

function SocketClient:getTcp(host)
	if not gt.isInReview then
		return socket.tcp()
	end
	local isipv6_only = false
	local addrinfo, err = socket.dns.getaddrinfo(host);
	if addrinfo then
		for i,v in ipairs(addrinfo) do
			if v.family == "inet6" then
				isipv6_only = true;
				break
			end
		end
	end
	print("isipv6_only", isipv6_only)
	if isipv6_only then
		return socket.tcp6()
	else
		return socket.tcp()
	end
end

function SocketClient:onPlayerTypeCallback(msgTbl)
	gt.log("服务器推送玩家类型了========socketClient")
	if msgTbl then
		gt.playerData.playerType = msgTbl.m_playerType
		gt.log("服务器推送的玩家类型", gt.playerData.playerType, msgTbl.m_playerType)
		gt.dispatchEvent(gt.EventType.GC_ON_PLAYER_TYPE)
	end
	dump(msgTbl)	
end

function SocketClient:onLuckyDrawNumCallback(msgTbl)
	gt.log("推送抽奖次数")
	gt.playerData.luckyDrawNum = msgTbl.m_drawNum
end

function SocketClient:setReconnectSucceed()
	self.curIpState = nil
	self.curReplayInterval = 0
	gt.resume_time = 8
	self.isCheckNet = false
end

function SocketClient:onGetIPSucceed(ipstate)
	if self.isStartGame then
		self.serverIp = secure.poll:getIP()
		self:connect(self.serverIp, self.serverPort, self.isBlock)
		self:reLogin()
	else -- LoginScene里面自己处理登录
		if self.getIPSucceedCall then
			self.getIPSucceedCall(ipstate)
		end
	end
end

function SocketClient:onGetIPFailed(ipstate)
	if self.getIPFailedCall then
		self.getIPFailedCall(ipstate)
	end
end

function SocketClient:getSecureIP(unionid, succeedCall, failedCall)
	self.getIPSucceedCall = succeedCall
	self.getIPFailedCall = failedCall
	require("app/secure/init")
	secure.poll:init({uuid=unionid, succeedCall=handler(self, self.onGetIPSucceed), failedCall=handler(self, self.onGetIPFailed)})
	secure.poll:request()
end

function SocketClient:savePlayCount(count)
	if count then
		require("app/secure/init")
		secure.poll:savePlayCount(count)
	end
end


return SocketClient


