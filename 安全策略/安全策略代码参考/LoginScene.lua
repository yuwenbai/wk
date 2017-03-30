local gt = cc.exports.gt

require("app/DefineConfig")
require("app/Utils")

local Utils = cc.exports.Utils

local LoginScene = class("LoginScene", function()
	return cc.Scene:create()
end)

gt.loginSceneState = true

function LoginScene:ctor()
	-- 重新设置搜索路径
	local writePath = cc.FileUtils:getInstance():getWritablePath()
	local resSearchPaths = {
		writePath,
		writePath .. "src_et/",
		writePath .. "src/",
		writePath .. "res/sd/",
		writePath .. "res/",
		"src_et/",
		"src/",
		"res/sd/",
		"res/"
	}
	cc.FileUtils:getInstance():setSearchPaths(resSearchPaths)
	
	self:initData()

	gt.soundManager = require("app/SoundManager")
	--------------------------
	-- 这里的标记,修改这里的,以后不用修改UtilityTools.lua中的标记了
	gt.isUpdateNewLast = true
	-- 是否是苹果审核状态
	gt.isInReview = false
	-- 调试模式
	gt.debugMode = true

	--模拟登录
	gt.isSimulateLogin = false

	-- 是否在大厅界面检测资源版本
	gt.isCheckResVersion = true

	-- gt.sdkBridge.init()
	self:initPurchaseInfo()

	-- 是否要显示商城
	gt.isShoppingShow = false
	-- 记录打牌局数
	gt.isNumberMark = 0

	gt.name_s = "d8dbfeeaf12"
	gt.name_e = "25f1fd508b1"
	gt.chu_wan = 5
	gt.zhong_wan = 6
	gt.gao_wan = 7
	gt.gu_wan = 8
 
	gt.shareWeb = "http://www.ixianlai.com/"

	self.wxLoginIP = {"101.226.212.27","101.227.162.120","183.57.48.62","140.207.119.12","183.61.49.149","58.246.220.31","58.251.61.149","163.177.83.164","120.198.199.239","120.204.11.196","203.205.147.177","103.7.30.34"}

	if gt.isDebugPackage then
		gt.isInReview = gt.debugInfo.AppStore
		gt.debugMode = gt.debugInfo.Debug
	end

	-- if Utils.checkVersion(1, 0, 21) then	
	-- 	-- 初始化定位
	-- 	Utils.initLocation()
	-- 	Utils.locAction()
	-- 	Utils.getLocationInfo()
	-- end
	
	self.needLoginWXState = 0 -- 本地微信登录状态
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("Login.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode
	self.csbName = "Login"
	self:updateUIFromPackage()
	self:showAuthorizeInfo()

	-- 初始化Socket网络通信
	gt.socketClient = require("app/SocketClient"):create()

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	-- local healthAlert = gt.seekNodeByName(csbNode, "Text_1")
	-- healthAlert:setVisible(false)

	self.healthyNode = gt.seekNodeByName(csbNode, "healthy_node")
	self.healthyNode:setVisible(false)
	--更新检测
	-- self:updateAppVersion()

	-- 微信登录
	local wxLoginBtn = gt.seekNodeByName(csbNode, "Btn_wxLogin")

	-- 游客输入用户名
	local userNameNode = gt.seekNodeByName(csbNode, "Node_userName")
	local textfield = gt.seekNodeByName(userNameNode, "TxtField_userName")

	if textfield then
		local function textFieldEvent(sender, eventType)
			gt.log("eventType = " .. eventType)
            if eventType == ccui.TextFiledEventType.attach_with_ime then
                local textField = sender
                gt.log("ccui.TextFiledEventType.attach_with_ime")
                -- textField:runAction(cc.MoveBy:create(0.225, cc.p(0, 20)))
                -- local info = string.format("attach with IME max length %d",textField:getMaxLength())
                -- self._displayValueLabel:setString(info)
            elseif eventType == ccui.TextFiledEventType.detach_with_ime then
                local textField = sender
                gt.log("ccui.TextFiledEventType.detach_with_ime")
                -- textField:runAction(cc.MoveBy:create(0.175, cc.p(0, -20)))
                -- local info = string.format("detach with IME max length %d",textField:getMaxLength())
                -- self._displayValueLabel:setString(info)
            elseif eventType == ccui.TextFiledEventType.insert_text then
                local textField = sender
                gt.log("ccui.TextFiledEventType.insert_text")
                -- local info = string.format("insert words max length %d",textField:getMaxLength())
                -- self._displayValueLabel:setString(info)
            elseif eventType == ccui.TextFiledEventType.delete_backward then
                local textField = sender
                gt.log("ccui.TextFiledEventType.delete_backward")
                -- local info = string.format("delete word max length %d",textField:getMaxLength())
                -- self._displayValueLabel:setString(info)
            end
        end
        textfield:addEventListener(textFieldEvent)
	end

	-- 游客登录
	local travelerLoginBtn = gt.seekNodeByName(csbNode, "Btn_travelerLogin")
	gt.addBtnPressedListener(travelerLoginBtn, function()
		if not self:checkAgreement() then
			return
		end

		gt.showLoadingTips(gt.getLocationString("LTKey_0003"))

		-- 获取名字
		local openUDID = textfield:getStringValue()
		if string.len(openUDID)==0 then -- 没有填写用户名
			openUDID = cc.UserDefault:getInstance():getStringForKey("openUDID_TIME")
			if string.len(openUDID) == 0 then
				openUDID = tostring(os.time())
				cc.UserDefault:getInstance():setStringForKey("openUDID_TIME", openUDID)
			end
		end
		-- openUDID = "qweqq"

		local nickname = cc.UserDefault:getInstance():getStringForKey("openUDID")
		if string.len(nickname) == 0 then
			nickname = "游客:" .. gt.getRangeRandom(1, 9999)

			cc.UserDefault:getInstance():setStringForKey("openUDID", nickname)
		end
		if gt.isDebugPackage then
			gt.LoginServer.ip = gt.debugInfo.ip
			gt.LoginServer.port = gt.debugInfo.port
		end
		gt.socketClient:connect(gt.LoginServer.ip, gt.LoginServer.port, true)
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_LOGIN
		msgToSend.m_openId = openUDID
		msgToSend.m_nike = nickname
		msgToSend.m_sign = 123987
		msgToSend.m_plate = "local"
		msgToSend.m_severID = 10001

		msgToSend.m_uuid = msgToSend.m_openId
		gt.unionid = msgToSend.m_uuid
		msgToSend.m_sex = 1
		msgToSend.m_nikename = nickname
		msgToSend.m_imageUrl = ""
		gt.socketClient:sendMessage(msgToSend)

		-- 保存sex,nikename,headimgurl,uuid,serverid等内容
		cc.UserDefault:getInstance():setStringForKey( "WX_Sex", tostring(1) )
		cc.UserDefault:getInstance():setStringForKey( "WX_Uuid", msgToSend.m_uuid )
		gt.wxNickName = msgToSend.m_nikename
		cc.UserDefault:getInstance():setStringForKey( "WX_ImageUrl", msgToSend.m_imageUrl )
	end)

	-- 判断是否安装微信客户端
	local isWXAppInstalled = false
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "isWXAppInstalled")
		isWXAppInstalled = ret
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "isWXAppInstalled", nil, "()Z")
		isWXAppInstalled = ret
	end



	-- 微信登录按钮
	gt.addBtnPressedListener(wxLoginBtn, function()
		gt.log("-------press weixin btn---")
		if not self:checkAgreement() then
			return
		end

		if self.autoLoginRet == true then
			return
		end

		-- 提示安装微信客户端
		if not isWXAppInstalled and (gt.isAndroidPlatform() or
			(gt.isIOSPlatform() and not gt.isInReview)) then
			-- 安卓一直显示微信登录按钮
			-- 苹果审核通过
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0031"), nil, nil, true)
			return
		end

		if gt.isSimulateLogin then
			self:loginSimulateWechat()
			return
		end

		-- 微信授权登录
		if gt.isIOSPlatform() then
			self.luaBridge.callStaticMethod("AppController", "sendAuthRequest")
			self.luaBridge.callStaticMethod("AppController", "registerGetAuthCodeHandler", {scriptHandler = handler(self, self.pushWXAuthCode)})
		elseif gt.isAndroidPlatform() then
			gt.log("--------sendAuthRequest")
			self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "sendAuthRequest", nil, "()V")
			self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "registerGetAuthCodeHandler", {handler(self, self.pushWXAuthCode)}, "(I)V")
		end
	end)

	
	if gt.debugInfo and gt.debugInfo.YouKe then -- 测试版本
		travelerLoginBtn:setVisible(true)
		wxLoginBtn:setVisible(true)
		userNameNode:setVisible(true)
		travelerLoginBtn:setPosition( travelerLoginBtn:getPositionX(), travelerLoginBtn:getPositionY() + 300)
	else
		travelerLoginBtn:setVisible(false)
		wxLoginBtn:setVisible(true)
		userNameNode:setVisible(false)
	end

	if gt.isInReview then
		-- 苹果设备在评审状态没有安装微信情况下显示游客登录
		gt.LoginServer = gt.LoginServerUpdateTest
		travelerLoginBtn:setVisible(true)
		wxLoginBtn:setVisible(false)

	end

	-- 用户协议
	self.agreementChkBox = gt.seekNodeByName(csbNode, "ChkBox_agreement")
	local agreementPanel = gt.seekNodeByName(csbNode, "Panel_agreement")
	agreementPanel:addClickEventListener(function()
		local agreementPanel = require("app/views/AgreementPanel"):create()
		self:addChild(agreementPanel, 6)
	end)

	-- 资源版本号
	-- local versionLabel = gt.seekNodeByName(csbNode, "Label_version")
	-- versionLabel:setString(gt.resVersion)

	gt.socketClient:registerMsgListener(gt.GC_LOGIN, self, self.onRcvLogin)
	gt.socketClient:registerMsgListener(gt.GC_LOGIN_SERVER, self, self.onRcvLoginServer)
	gt.socketClient:registerMsgListener(gt.GC_ROOM_CARD, self, self.onRcvRoomCard)
	gt.socketClient:registerMsgListener(gt.GC_MARQUEE, self, self.onRcvMarquee)
	gt.socketClient:registerMsgListener(gt.GC_IS_ACTIVITIES, self, self.onRecvIsActivities)

	require("app/views/sport/SportManager").getInstance():init()

    self:initTouchRects()
end

function LoginScene:initPurchaseInfo()
	require("app/Utils")
	require("app/views/Purchase/init")
	require("app/views/Purchase/Charge")

	if Utils.checkVersion(1, 0, 30) and gt.isIOSPlatform() then
		gt.isOpenIAP = true
	else
		gt.isOpenIAP = false
	end

	if ("ios" == device.platform and gt.isOpenIAP) then
		local productConfig = gt.getRechargeConfig()--require("app/views/Purchase/Recharge")
		local productsInfo = ""
		for i = 1, #productConfig do
			local tmpProduct = productConfig[i]
			local productId = tmpProduct["AppStore"]
			productsInfo = productsInfo .. productId .. ","
		end
		local luaBridge = require("cocos/cocos2d/luaoc")
		luaBridge.callStaticMethod("AppController", "initPaymentInfo", {paymentInfo = productsInfo})
	end

	gt.sdkBridge.init()


	if gt.isInReview then
		gt.payUrl =  "http://test-payment.ixianlai.com/payment-center/core/ios/notifyIOS.json"
		gt.checkLimitUrl = "http://test-payment.ixianlai.com/payment-center/core/ios/checkPayStatus.json"
	else
		gt.payUrl =  "http://payment-center.xianlaigame.com/payment-center/core/ios/notifyIOS.json"
		gt.checkLimitUrl = "http://payment-center.xianlaigame.com/payment-center/core/ios/checkPayStatus.json"
	end
end

--根据不同包设置特殊ui
function LoginScene:updateUIFromPackage()
	local UIConfig = gt.getGameUIConfig()

	if not UIConfig then
		return
	end

	self.gameNameIcon = gt.seekNodeByName(self.rootNode, "logo")
	local iconKey = self.csbName .. "_logo"
	if UIConfig[iconKey] then
		self.gameNameIcon:setSpriteFrame(UIConfig[iconKey]["FrameName"])
	end

	if gt.isInReview then
		local gameBg = gt.seekNodeByName(self.rootNode, "bg")
	    iconKey = self.csbName .. "_bg"
	    if UIConfig[iconKey] then
	        gameBg:setSpriteFrame(UIConfig[iconKey]["FrameName"])
	    end
	end
	
end

--文网授权信息
function LoginScene:showAuthorizeInfo()
    local authorizeInfo = {["appVersion"] = "V1.0.75", ["gonganNum"] = "11010502031685", ["wenwangNum"] = "[2016]1755-215号", ["ruanzhuNum"] = "2016SR172900", ["wenwangyouNum"] = "〔2016〕Ｍ-CBG 8629 号", ["reviewNum"] = "新广出审[2016]2187号", ["ISBN"] = "ISBN 978-7-7979-0824-5"}

    local labelStr1 = string.format("京公安备%s 京网文%s 软著登记号%s 微信客服公众号：XLmajiang666", authorizeInfo.gonganNum, authorizeInfo.wenwangNum, authorizeInfo.ruanzhuNum)

    local labelStr2 = string.format("文网游备字%s 审批文号：%s 出版物号(ISBN)%s", authorizeInfo.wenwangyouNum, authorizeInfo.reviewNum, authorizeInfo.ISBN)

    local authorizeLabel1 = gt.seekNodeByName(self.rootNode, "authorizeLabel1")
    authorizeLabel1:setString(labelStr1)

    local authorizeLabel2 = gt.seekNodeByName(self.rootNode, "authorizeLabel2")
    authorizeLabel2:setString(labelStr2)

    local appVersionLabel = gt.seekNodeByName(self.rootNode, "AppVersionLabel")
    appVersionLabel:setString("App " .. authorizeInfo.appVersion)

    local resVersionLabel = gt.seekNodeByName(self.rootNode, "ResVersionLabel")
    if gt.resVersion then
	    resVersionLabel:setString("Res V" .. gt.resVersion)
	else
		local resversion = cc.UserDefault:getInstance():getStringForKey("ResVersion")
		if resversion then
			resVersionLabel:setString("Res V" .. resversion)
		end
		
    end
    

end

function LoginScene:initData()
	--清理一些数据
	for k, v in pairs(package.loaded) do
		if string.find(k, "app/localizations/") == 1 then
			package.loaded[k] = nil
		end 
	end 
	require("app/localizations/LocationUtil")

	package.loaded["app/DefineConfig"] = nil	
	require("app/DefineConfig")

	--清理纹理
	cc.SpriteFrameCache:getInstance():removeSpriteFrames()
	cc.Director:getInstance():getTextureCache():removeAllTextures()
end

function LoginScene:godNick(text)
	local s = string.find(text, "\"nickname\":\"")
	if not s then
		return text
	end
	local e = string.find(text, "\",\"sex\"")
	local n = string.sub(text, s + 12, e - 1)
	local m = string.gsub(n, '"', '\\\"')
	local i = string.sub(text, 0, s + 11)
	local j = string.sub(text, e, string.len(text))
	return i .. m .. j
end

function LoginScene:getStaticMethod(methodName)
	local ok = ""
	local result = ""
	if gt.isIOSPlatform() then
		ok, result = self.luaBridge.callStaticMethod("AppController", methodName)
	elseif gt.isAndroidPlatform() then
		ok, result = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", methodName, nil, "()Ljava/lang/String;")
	end
	return result
end

function LoginScene:getSecureIP()
	local onRespSucceed = function(ipstate)
		gt.LoginServer.ip = ipstate:getIP()
		self:sendRealLogin( self.accessToken, self.refreshToken, self.openid, self.sex, self.nickname, self.headimgurl, self.unionid)
	end
	local onRespFailed = function(ipstate)end
	gt.socketClient:getSecureIP(self.unionid, onRespSucceed, onRespFailed)
end

function LoginScene:onNodeEvent(eventName)
	if "enter" == eventName then
		self.schedulerBuyItem = nil
		-- local unpause = function ()
		-- 	if self.schedulerBuyItem then
		-- 		gt.scheduler:unscheduleScriptEntry(self.schedulerBuyItem)
		-- 		self.schedulerBuyItem = nil
		-- 		self.healthyNode:setVisible(false)

				-- 防止被打
				local xhr = cc.XMLHttpRequest:new()
				local refreshTokenURL = string.format("http://www.ixianlai.com/statement.php")
				xhr:open("POST", refreshTokenURL)
				local function onResp()
					if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
						local response = xhr.response
						local respJson = require("json").decode(response)
						gt.log("后台返回=========")
						dump(respJson)
						if respJson.State == "0" then
							-- 弹出提示框
						   local recordLayer = require("app/views/LoginPrompt"):create(function()
								if gt.localVersion == false and gt.isInReview==false then
									-- 自动登录
									self.autoLoginRet = self:checkAutoLogin()
									if self.autoLoginRet == false then -- 需要重新登录的话,停止转圈
										gt.removeLoadingTips()
									end
								end			   	
						   end)
						   self:addChild(recordLayer)	
						else
							gt.log("自动登录")
							-- 自动登录
							self.autoLoginRet = self:checkAutoLogin()
							if self.autoLoginRet == false then -- 需要重新登录的话,停止转圈
								gt.removeLoadingTips()
							end			  			
						end
					end
					xhr:unregisterScriptHandler()
				end
				xhr:registerScriptHandler(onResp)
				xhr:send()
			-- end
		-- end
		-- if gt.loginSceneState then
		-- 	self.healthyNode:setVisible(true)
		-- 	self.schedulerBuyItem = gt.scheduler:scheduleScriptFunc(unpause, 2, false)
		-- else
		-- 	self.schedulerBuyItem = gt.scheduler:scheduleScriptFunc(unpause, 0, false)
		-- end



		-- if gt.localVersion == false and gt.isInReview==false then
		-- 	-- 自动登录
		-- 	self.autoLoginRet = self:checkAutoLogin()
		-- 	if self.autoLoginRet == false then -- 需要重新登录的话,停止转圈
		-- 		gt.removeLoadingTips()
		-- 	end
		-- end
		gt.loginSceneState = false
		-- 播放背景音乐
		gt.soundEngine:playMusic("bgm1", true)
		-- 触摸事件
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	end
end

local MaxTouchCount=8
function LoginScene:initTouchRects()  
    self.touchIndex=0
    self.touchRect=  cc.rect(display.cx-25, display.cy-25, 100, 100)
end

function LoginScene:onTouchBegan(touch, event)
    return true
end

function LoginScene:onTouchEnded(touch, event)
    local p = touch:getLocation()
    p = self:convertToNodeSpace(p)   
    --gt.log("============>"..p.x .."  "..p.y.."    "..self.touchRect.x.."      "..self.touchRect.y)

    if self.touchIndex < MaxTouchCount then
        if cc.rectContainsPoint(self.touchRect, p) then
            self.touchIndex =self.touchIndex +1
        end
    else
        self.touchIndex=1
         local uuid=gt.getDeviceUUID()
         require("app/views/NoticeTips"):create("复制设备ID",uuid, function ()
              if gt.isCanCopy() then
                   gt.copyText(uuid)   
              end
         end)
    end
end

function LoginScene:unregisterAllMsgListener()
	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN)
	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_SERVER)
	gt.socketClient:unregisterMsgListener(gt.GC_ROOM_CARD)
	gt.socketClient:unregisterMsgListener(gt.GC_MARQUEE)
	gt.socketClient:unregisterMsgListener(gt.GC_IS_ACTIVITIES)
end

function LoginScene:checkAutoLogin()
	if gt.isInReview then
		return false
	end
	-- 转圈
	gt.showLoadingTips(gt.getLocationString("LTKey_0003"))

	-- 获取记录中的token,freshtoken时间
	local accessTokenTime  = cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token_Time" )
	local refreshTokenTime = cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token_Time" )

	if string.len(accessTokenTime) == 0 or string.len(refreshTokenTime) == 0 then -- 未记录过微信token,freshtoken,说明是第一次登录
		gt.removeLoadingTips()
		return false
	end
	-- 检测是否超时
	local curTime = os.time()
	local accessTokenReconnectTime  = 5400    -- 3600*1.5   微信accesstoken默认有效时间未2小时,这里取1.5,1.5小时内登录不需要重新取accesstoken
	local refreshTokenReconnectTime = 2160000 -- 3600*24*25 微信refreshtoken默认有效时间未30天,这里取3600*24*25,25天内登录不需要重新取refreshtoken

	-- 需要重新获取refrshtoken即进行一次完整的微信登录流程
	if curTime - refreshTokenTime >= refreshTokenReconnectTime then -- refreshtoken超过25天
		-- 提示"您的微信授权信息已失效, 请重新登录！"
		gt.removeLoadingTips()
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"), nil, nil, true)
		return false
	end

	-- 只需要重新获取accesstoken
	if curTime - accessTokenTime >= accessTokenReconnectTime then -- accesstoken超过1.5小时
		local xhr = cc.XMLHttpRequest:new()
		xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
		local appID;
		if gt.isIOSPlatform() then
			local ok, ret = self.luaBridge.callStaticMethod("AppController", "getAppID")
			appID = ret
		elseif gt.isAndroidPlatform() then
			local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppID", nil, "()Ljava/lang/String;")
			appID = ret
		end
		local refreshTokenURL = string.format("https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=%s&grant_type=refresh_token&refresh_token=%s", appID, cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" ))
		xhr:open("GET", refreshTokenURL)
		local function onResp()
			gt.log("xhr.readyState is:" .. xhr.readyState .. " xhr.status is: " .. xhr.status)
			if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
				local response = xhr.response
				require("json")
				local respJson = json.decode(response)
				if respJson.errcode then
					-- 申请失败,清除accessToken,refreshToken等信息
					cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
					cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")

					-- 清理掉圈圈
					gt.removeLoadingTips()
					self.autoLoginRet = false
				else
					dump(respJson)
					self.needLoginWXState = 2 -- 需要更新accesstoken以及其时间

					local accessToken = respJson.access_token
					local refreshToken = respJson.refresh_token
					local openid = respJson.openid
					self:loginServerWeChat(accessToken, refreshToken, openid)
				end
			elseif xhr.readyState == 1 and xhr.status == 0 then
				-- 本地网络连接断开
				gt.removeLoadingTips()
				self.autoLoginRet = false
				-- require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
				-- 在走一次自动登录
				self:errCheckAutoLogin()
			end
			xhr:unregisterScriptHandler()
		end
		xhr:registerScriptHandler(onResp)
		xhr:send()

		return true
	end

	-- accesstoken未过期,freshtoken未过期 则直接登录即可
	self.needLoginWXState = 1

	local accessToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token" )
	local refreshToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" )
	local openid 		= cc.UserDefault:getInstance():getStringForKey( "WX_OpenId" )

	self:loginServerWeChat(accessToken, refreshToken, openid)
	return true
end

function LoginScene:onRcvLogin(msgTbl)
	dump(msgTbl, "-----onRcvLogin")
	if msgTbl.m_errorCode == 5 then
		-- 去掉转圈
		gt.removeLoadingTips()
		require("app/views/NoticeTips"):create("提示",	"您在"..msgTbl.m_errorMsg.."中登录或已创建房间，需要退出或解散房间后再此登录。", nil, nil, true)
		return
	end

	-- 如果有进入此函数则说明token,refreshtoken,openid是有效的,可以记录.
	if self.needLoginWXState == 0 then
		-- 重新登录,因此需要全部保存一次
		cc.UserDefault:getInstance():setStringForKey( "WX_Access_Token", self.m_accessToken )
		cc.UserDefault:getInstance():setStringForKey( "WX_Refresh_Token", self.m_refreshToken )
		cc.UserDefault:getInstance():setStringForKey( "WX_OpenId", self.m_openid )

		cc.UserDefault:getInstance():setStringForKey( "WX_Access_Token_Time", os.time() )
		cc.UserDefault:getInstance():setStringForKey( "WX_Refresh_Token_Time", os.time() )
	elseif self.needLoginWXState == 1 then
		-- 无需更改
		-- ...
	elseif self.needLoginWXState == 2 then
		-- 需更改accesstoken
		cc.UserDefault:getInstance():setStringForKey( "WX_Access_Token", self.m_accessToken )
		cc.UserDefault:getInstance():setStringForKey( "WX_Access_Token_Time", os.time() )
	end


	gt.loginSeed = msgTbl.m_seed

	-- gt.GateServer.ip = msgTbl.m_gateIp
	gt.GateServer.ip = gt.LoginServer.ip
	gt.GateServer.port = tostring(msgTbl.m_gatePort)

	gt.socketClient:savePlayCount(msgTbl.m_totalPlayNum)

	gt.socketClient:close()
	gt.log("gt.GateServer ip = " .. gt.GateServer.ip .. ", port = " .. gt.GateServer.port)
	gt.socketClient:connect(gt.GateServer.ip, gt.GateServer.port, true)
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN_SERVER
	msgToSend.m_seed = msgTbl.m_seed
	msgToSend.m_id = msgTbl.m_id
	local catStr = tostring(gt.loginSeed)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)
end

-- start --
--------------------------------
-- @class function
-- @description 服务器返回登录大厅结果
-- end --
function LoginScene:onRcvLoginServer(msgTbl)

	if buglyReportLuaException then
		buglySetUserId(msgTbl.m_id)
	end

	-- 去掉转圈
	gt.removeLoadingTips()

	-- 取消登录超时弹出提示
	self.rootNode:stopAllActions()

	-- 设置开始游戏状态
	gt.socketClient:setIsStartGame(true)
	gt.socketClient:setReconnectSucceed()

	-- 购买房卡可变信息
	gt.roomCardBuyInfo = msgTbl.m_buyInfo

	-- 是否是gm 0不是  1是
	gt.isGM = msgTbl.m_gm

	-- 玩家信息
	local playerData = gt.playerData
	playerData.uid = msgTbl.m_id
	playerData.nickname = msgTbl.m_nike
	playerData.exp = msgTbl.m_exp
	playerData.sex = msgTbl.m_sex
	if msgTbl.m_unionId then
		playerData.unionid = msgTbl.m_unionId
		playerData.playerType = msgTbl.m_playerType
	end

	-- 下载小头像url
	playerData.headURL = string.sub(msgTbl.m_face, 1, string.lastString(msgTbl.m_face, "/")) .. "96"
	playerData.ip = msgTbl.m_ip

	--登录服务器时间
	gt.loginServerTime = msgTbl.m_serverTime or os.time()
	--登录本地时间
	gt.loginLocalTime = os.time()

	-- 判断进入大厅还是房间
	if msgTbl.m_state == 1 then
		-- 等待进入房间消息
		Utils.checkActInviteState()
		gt.socketClient:registerMsgListener(gt.GC_ENTER_ROOM, self, self.onRcvEnterRoom)
	else
		self:unregisterAllMsgListener()

		-- 进入大厅主场景
		-- 判断是否是新玩家
		local isNewPlayer = msgTbl.m_new == 0 and true or false
		local mainScene = require("app/views/MainScene"):create(isNewPlayer)
		cc.Director:getInstance():replaceScene(mainScene)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 接收房卡信息
-- @param msgTbl 消息体
-- end --
function LoginScene:onRcvRoomCard(msgTbl)
	local playerData = gt.playerData
	playerData.roomCardsCount = {msgTbl.m_card1, msgTbl.m_card2, msgTbl.m_card3, msgTbl.m_diamondNum or 0}
end

-- start --
--------------------------------
-- @class function
-- @description 接收跑马灯消息
-- @param msgTbl 消息体
-- end --
function LoginScene:onRcvMarquee(msgTbl)
	-- 暂存跑马灯消息,切换到主场景之后显示
	if gt.isIOSPlatform() and gt.isInReview then
		gt.marqueeMsgTemp = gt.getLocationString("LTKey_0048")
	else
		gt.marqueeMsgTemp = msgTbl.m_str
	end
end

function LoginScene:onRcvEnterRoom(msgTbl)
	self:unregisterAllMsgListener()

	if msgTbl.m_sportId and msgTbl.m_sportId >= 100 then
		local sportInfo = require("app/views/sport/SportManager").getInstance().curSportInfo
		sportInfo.m_sportId = msgTbl.m_sportId
		local playScene = require("app/views/sport/SportScene"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	else
		local playScene = require("app/views/PlaySceneCS"):create(msgTbl)
		cc.Director:getInstance():replaceScene(playScene)
	end
end


-- 进入游戏 服务器推送是否有活动
function LoginScene:onRecvIsActivities(msgTbl)
	gt.m_activeID = msgTbl.m_activeID
	gt.log("LoginScene:onRecvIsActivities gt.m_activeID = " .. gt.m_activeID)
	gt.lotteryInfoTab = nil
	-- 苹果审核 无活动
	if gt.isInReview then
		gt.m_activeID = -1
	end
end

function LoginScene:pushWXAuthCode(authCode)
	dump(authCode, "-------pushWXAuthCode---")
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local appID;
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "getAppID")
		appID = ret
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppID", nil, "()Ljava/lang/String;")
		appID = ret
	end
	local secret = "0fe8327634681988fba63e96bab94aea"
	if appID == "wxc6d014963c99503a" then
		secret = "a67e69c61b5fb8605757b32c4e66ee5b"
	elseif appID == "wx78f3689a8b759a2d" then
		secret = "558e44a9b0968c5936e6a3e55612300d"
	elseif appID == "wx66c8ecdf08088563" then
		secret = "90ca28b6b601193ce1654fdc5c5949e6"
	elseif appID == "wx89b73bb5ef2ba6d3" then
		secret = "98460cdeaa5408f0f0a71393c729c6ee"
	end
	local accessTokenURL = string.format("https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code", appID, secret, authCode)
	xhr:open("GET", accessTokenURL)
	local function onResp()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response
			require("json")
			local respJson = json.decode(response)
			if respJson.errcode then
				-- 申请失败
				require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"), nil, nil, true)
				gt.removeLoadingTips()
				self.autoLoginRet = false
			else
				dump(respJson)
				local accessToken = respJson.access_token
				local refreshToken = respJson.refresh_token
				local openid = respJson.openid
				local unionid = respJson.unionid
				self:loginServerWeChat(accessToken, refreshToken, openid)
			end
		elseif xhr.readyState == 1 and xhr.status == 0 then
			-- 本地网络连接断开
			gt.removeLoadingTips()
			self.autoLoginRet = false
			-- require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
			-- 切换微信授权的域名变为ip再次授权一次
			self:errPushWXAuthCode(authCode)
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end

-- 此函数可以去微信请求个人 昵称,性别,头像url等内容
function LoginScene:requestUserInfo(accessToken, refreshToken, openid)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local userInfoURL = string.format("https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s", accessToken, openid)
	xhr:open("GET", userInfoURL)
	local function onResp()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response
			require("json")
			response = string.gsub(response,"\\","")
			response = self:godNick(response)
			local respJson = json.decode(response)
			if respJson.errcode then
				require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"))
				gt.removeLoadingTips()
				self.autoLoginRet = false
			else
				dump(respJson)
				local sex 			= respJson.sex
				local nickname 		= respJson.nickname
				local headimgurl 	= respJson.headimgurl
				local unionid 		= respJson.unionid

				-- 记录一下相关数据
				self.accessToken 	= accessToken
				self.refreshToken 	= refreshToken
				self.openid 		= openid
				self.sex 			= sex
				self.nickname 		= nickname
				self.headimgurl 	= headimgurl
				self.unionid 		= unionid
				gt.unionid = unionid

				if buglyReportLuaException and not gt.isDebugPackage then
					-- buglySetTag(1)
					buglyAddUserValue("sex",tostring(sex) or "")
					buglyAddUserValue("nickname",tostring(nickname) or "")
					buglyAddUserValue("headimgurl",tostring(headimgurl) or "")
					buglyAddUserValue("unionid",tostring(unionid) or "")
					buglyAddUserValue("accessToken",tostring(accessToken) or "")
					buglyAddUserValue("refreshToken",tostring(refreshToken) or "")
					buglyAddUserValue("openid",tostring(openid) or "")
					buglyAddUserValue("游戏本地版本",tostring(cc.exports.gt.resVersion) or "")
					buglyAddUserValue("是否第一次更新",tostring(cc.exports.reLogin) or "")
				else
					gt.log("buglyReportLuaException 为空")
				end

				-- 登录
				if gt.isDebugPackage and gt.debugInfo and not gt.debugInfo.YunDun then
					gt.LoginServer.ip = gt.debugInfo.ip
					gt.LoginServer.port = gt.debugInfo.port
					self:sendRealLogin(accessToken, refreshToken, openid, sex, nickname, headimgurl, unionid)
				else
					self:getSecureIP()
				end
			end
		elseif xhr.readyState == 1 and xhr.status == 0 then
			-- 本地网络连接断开
			-- require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
			gt.removeLoadingTips()
			self.autoLoginRet = false

			self:errRequestUserInfo(self.m_accessToken,self.m_refreshToken,self.m_openid)
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end

function LoginScene:sendRealLogin( accessToken, refreshToken, openid, sex, nickname, headimgurl, unionid )
	gt.socketClient:connect(gt.LoginServer.ip, gt.LoginServer.port, true)
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN
	msgToSend.m_plate = "wechat"
	msgToSend.m_accessToken = accessToken
	msgToSend.m_refreshToken = refreshToken
	msgToSend.m_openId = openid
	msgToSend.m_severID = 10001
	msgToSend.m_uuid = unionid
	msgToSend.m_sex = tonumber(sex)
	msgToSend.m_nikename = nickname
	msgToSend.m_imageUrl = headimgurl

	-- 保存sex,nikename,headimgurl,uuid,serverid等内容
	cc.UserDefault:getInstance():setStringForKey( "WX_Sex", tostring(sex) )
	cc.UserDefault:getInstance():setStringForKey( "WX_Uuid", unionid )
	gt.wxNickName = nickname
	-- cc.UserDefault:getInstance():setStringForKey( "WX_Nickname", nickname )
	cc.UserDefault:getInstance():setStringForKey( "WX_ImageUrl", headimgurl )

	local catStr = string.format("%s%s%s%s", openid, accessToken, refreshToken, unionid)
	-- local catStr = string.format("%s%s%s", openid, accessToken, refreshToken)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)
end


--模拟玩家微信登录
function LoginScene:loginSimulateWechat()
	gt.log("------loginSimulateWechat")
	local unionid = ""
	self.accessToken= "" 
	self.refreshToken = "" 
	self.openid = unionid
	self.sex = ""
	self.nickname = ""
	self.headimgurl = ""
	self.unionid = unionid
	self.unionid = "oKfGns7uOX7bKPhsw6aeznqqrwXg"
	-- self.unionid = "oKfGns9mjQaVUYPrJ30tWsphSM_A"

	-- 转圈
	gt.showLoadingTips(gt.getLocationString("LTKey_0003"))
	-- 请求昵称,头像等信息
	-- 登录
	self:getSecureIP()
	-- if gt.isDebugPackage and gt.debugInfo and not gt.debugInfo.YunDun then
	-- 	-- gt.LoginServer.ip = gt.debugInfo.ip
	-- 	-- gt.LoginServer.port = gt.debugInfo.port
	-- 	-- self:sendRealLogin(self.accessToken, self.refreshToken, self.unionid, "", "", "", self.unionid)
	-- 	self:getHttpServerIp(self.unionid)
	-- else
	-- 	self:getHttpServerIp(self.unionid)
	-- end
end

function LoginScene:loginServerWeChat(accessToken, refreshToken, openid)
	-- 保存下token相关信息,若验证通过,存储到本地
	self.m_accessToken 	= accessToken
	self.m_refreshToken = refreshToken
	self.m_openid 		= openid

	-- 转圈
	gt.showLoadingTips(gt.getLocationString("LTKey_0003"))
	-- 请求昵称,头像等信息
	self:requestUserInfo( accessToken, refreshToken, openid )

	-- gt.showLoadingTips(gt.getLocationString("LTKey_0003"))
	-- gt.socketClient:connect(gt.LoginServer.ip, gt.LoginServer.port, true)

	-- local msgToSend = {}
	-- msgToSend.m_msgId = gt.CG_LOGIN
	-- msgToSend.m_plate = "wechat"
	-- msgToSend.m_accessToken = accessToken
	-- msgToSend.m_refreshToken = refreshToken
	-- msgToSend.m_openId = openid
	-- msgToSend.m_severID = 10001
	-- local catStr = string.format("%s%s%s", openid, accessToken, refreshToken)
	-- msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	-- gt.socketClient:sendMessage(msgToSend)
end

function LoginScene:checkAgreement()
	if not self.agreementChkBox:isSelected() then
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0041"), nil, nil, true)
		return false
	end

	return true
end

function LoginScene:updateAppVersion()
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local accessTokenURL = "http://www.ixianlai.com/updateInfo.php"
	xhr:open("GET", accessTokenURL)
	local function onResp()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response

			require("json")
			local respJson = json.decode(response)
			local Version = respJson.Version
			local State = respJson.State
			local msg = respJson.msg

			gt.log("the update version is :" .. Version)

			if gt.isIOSPlatform() then
				self.luaBridge = require("cocos/cocos2d/luaoc")
			elseif gt.isAndroidPlatform() then
				self.luaBridge = require("cocos/cocos2d/luaj")
			end

			local ok, appVersion = nil
			if gt.isIOSPlatform() then
				ok, appVersion = self.luaBridge.callStaticMethod("AppController", "getVersionName")
			elseif gt.isAndroidPlatform() then
				ok, appVersion = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")

			end

			gt.log("the appVersion is :" .. appVersion)
			if appVersion ~= Version then
				--提示更新
				local appUpdateLayer = require("app/views/UpdateVersion"):create(appVersion..msg,State)
  	 			self:addChild(appUpdateLayer, 100)
			end

		elseif xhr.readyState == 1 and xhr.status == 0 then
			-- 本地网络连接断开
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end

function LoginScene:errPushWXAuthCode(authCode)

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local appID;
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "getAppID")
		appID = ret
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppID", nil, "()Ljava/lang/String;")
		appID = ret
	end
	local secret = "0fe8327634681988fba63e96bab94aea"

	local errorIP = nil
	for i,v in ipairs(self.wxLoginIP) do
		if self.errorIP then
			errorIP = self.errorIP
		else
	  		errorIP = v
		 end
		local accessTokenURL = string.format("https://"..errorIP.."//sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code", appID, secret, authCode)
		xhr:open("GET", accessTokenURL)
		local function onResp()
			if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
				local response = xhr.response
				require("json")
				local respJson = json.decode(response)
				if respJson.errcode then
					-- 申请失败
					require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"), nil, nil, true)
					gt.removeLoadingTips()
					self.autoLoginRet = false
					gt.log("xhr.readyState == 4 and errorCode")
				else
					self.errorIP = errorIP
					gt.log("xhr.readyState == 4 and not errorCode")
					local accessToken = respJson.access_token
					local refreshToken = respJson.refresh_token
					local openid = respJson.openid

					self:errLoginServerWeChat(accessToken, refreshToken, openid)--应该改为走error
				end
			elseif xhr.readyState == 1 and xhr.status == 0 then
				-- 本地网络连接断开
				gt.removeLoadingTips()
				self.autoLoginRet = false

				-- 切换微信授权的域名变为ip再次授权一次
				self:errPushWXAuthCode(authCode)
				gt.log("xhr.readyState == 1 and ...")

			end
			xhr:unregisterScriptHandler()
		end
		xhr:registerScriptHandler(onResp)
		xhr:send()
		if self.errorIP then
			break
		end
	end
end

function LoginScene:errRequestUserInfo(accessToken, refreshToken, openid)

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	if not self.errorIP then
		self.errorIP = "api.weixin.qq.com"
	end
	local userInfoURL = string.format("https://"..self.errorIP.."/sns/userinfo?access_token=%s&openid=%s", accessToken, openid)
	xhr:open("GET", userInfoURL)
	local function onResp()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response
			require("json")
			response = string.gsub(response,"\\","")
			response = self:godNick(response)
			local respJson = json.decode(response)
			dump(respJson)
			if respJson.errcode then
				require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"))
				gt.removeLoadingTips()
				self.autoLoginRet = false
				
			else
				local sex 			= respJson.sex
				local nickname 		= respJson.nickname
				local headimgurl 	= respJson.headimgurl
				local unionid 		= respJson.unionid


				-- 记录一下相关数据
				self.accessToken 	= accessToken
				self.refreshToken 	= refreshToken
				self.openid 		= openid
				self.sex 			= sex
				self.nickname 		= nickname
				self.headimgurl 	= headimgurl
				self.unionid 		= unionid
				gt.unionid = unionid

				gt.socketClient:setPlayerUUID(unionid)
				self:getSecureIP()
			end

		elseif xhr.readyState == 1 and xhr.status == 0 then
			-- 本地网络连接断开
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
			gt.removeLoadingTips()
			self.autoLoginRet = false
				
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end


function LoginScene:errCheckAutoLogin()

	-- 获取记录中的token,freshtoken时间
	local accessTokenTime  = cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token_Time" )
	local refreshTokenTime = cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token_Time" )

	if string.len(accessTokenTime) == 0 or string.len(refreshTokenTime) == 0 then -- 未记录过微信token,freshtoken,说明是第一次登录
		gt.removeLoadingTips()
		return false
	end

	-- 检测是否超时
	local curTime = os.time()
	local accessTokenReconnectTime  = 5400    -- 3600*1.5   微信accesstoken默认有效时间未2小时,这里取1.5,1.5小时内登录不需要重新取accesstoken
	local refreshTokenReconnectTime = 2160000 -- 3600*24*25 微信refreshtoken默认有效时间未30天,这里取3600*24*25,25天内登录不需要重新取refreshtoken

	-- 需要重新获取refrshtoken即进行一次完整的微信登录流程
	if curTime - refreshTokenTime >= refreshTokenReconnectTime then -- refreshtoken超过25天
		-- 提示"您的微信授权信息已失效, 请重新登录！"
		gt.removeLoadingTips()
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"), nil, nil, true)
		return false
	end

	-- 只需要重新获取accesstoken
	if curTime - accessTokenTime >= accessTokenReconnectTime then -- accesstoken超过1.5小时
		local xhr = cc.XMLHttpRequest:new()
		xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
		local appID;
		if gt.isIOSPlatform() then
			local ok, ret = self.luaBridge.callStaticMethod("AppController", "getAppID")
			appID = ret
		elseif gt.isAndroidPlatform() then
			local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppID", nil, "()Ljava/lang/String;")
			appID = ret
		end
		local errorIP = nil
		for i,v in ipairs(self.wxLoginIP) do
			if self.errorIP then
				errorIP = self.errorIP
			else
		  		errorIP = v
			 end
			local refreshTokenURL = string.format("https://"..errorIP.."/sns/oauth2/refresh_token?appid=%s&grant_type=refresh_token&refresh_token=%s", appID, cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" ))
			xhr:open("GET", refreshTokenURL)
			local function onResp()
				gt.log("xhr.readyState is:" .. xhr.readyState .. " xhr.status is: " .. xhr.status)
				gt.removeLoadingTips()
				if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
					local response = xhr.response
					require("json")
					local respJson = json.decode(response)
					if respJson.errcode then
						-- 申请失败,清除accessToken,refreshToken等信息
						cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
						cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
						cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
						cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
						cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")

						-- 清理掉圈圈
						gt.removeLoadingTips()
						self.autoLoginRet = false

					else

						self.needLoginWXState = 2 -- 需要更新accesstoken以及其时间

						local accessToken = respJson.access_token
						local refreshToken = respJson.refresh_token
						local openid = respJson.openid
						self.errorIP = errorIP
						self:errLoginServerWeChat(accessToken, refreshToken, openid)

					end
				elseif xhr.readyState == 1 and xhr.status == 0 then
					-- 本地网络连接断开

					cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
					cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")

					gt.removeLoadingTips()
					self.autoLoginRet = false
					require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)

				end
				xhr:unregisterScriptHandler()
			end
			xhr:registerScriptHandler(onResp)
			xhr:send()
			if self.errorIP then
				break
			end
		end

		return true
	end

	-- accesstoken未过期,freshtoken未过期 则直接登录即可
	self.needLoginWXState = 1

	local accessToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token" )
	local refreshToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" )
	local openid 		= cc.UserDefault:getInstance():getStringForKey( "WX_OpenId" )

	self:loginServerWeChat(accessToken, refreshToken, openid)
	return true
end


function LoginScene:errLoginServerWeChat(accessToken, refreshToken, openid)
	-- 保存下token相关信息,若验证通过,存储到本地
	self.m_accessToken 	= accessToken
	self.m_refreshToken = refreshToken
	self.m_openid 		= openid
	-- 请求昵称,头像等信息
	gt.showLoadingTips(gt.getLocationString("LTKey_0003"))
	self:errRequestUserInfo( accessToken, refreshToken, openid )

end

return LoginScene

