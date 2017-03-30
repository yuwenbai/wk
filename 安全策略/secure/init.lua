
cc.exports.secure = {
	log = true,
	polls = {"ips", "oss", "gaofang"},
	ips = {servername = "hunan"},
	gaofang = {ip = "hnmj.xianlaiyx.com"}
}

local function log(msg, ...)
	if not secure.log then
		return
	end
	msg = msg .. " "
	local args = {...}
	for i,v in ipairs(args) do
		msg = msg .. tostring(v) .. " "
	end
	print(os.date("%Y-%m-%d %H:%M:%S") .. "------secure log:" .. msg)
end
secure.log = log

secure.poll = require("app/secure/poll"):getInstance()