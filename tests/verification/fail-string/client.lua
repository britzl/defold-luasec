--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local params = {
   mode = "client",
   protocol = "tlsv1",
   key = config.certs .. "clientBkey.pem",
   certificate = config.certs .. "clientB.pem",
   cafile = config.certs .. "rootB.pem",
   verify = "none",
   options = "all",
}

local peer = socket.tcp()
peer:connect(config.serverIP, config.serverPort)

-- [[ SSL wrapper
peer = assert( ssl.wrap(peer, params) )
assert(peer:dohandshake())
--]]

local err, msg = peer:getpeerverification()
print(err, msg)

print(peer:receive("*l"))
peer:close()
