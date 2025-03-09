--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local params = {
   mode = "client",
   protocol = "tlsv1",
   key = config.certs .. "clientAkey.pem",
   certificate = config.certs .. "clientA.pem",
   cafile = config.certs .. "rootA.pem",
   verify = {"peer", "fail_if_no_peer_cert"},
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
