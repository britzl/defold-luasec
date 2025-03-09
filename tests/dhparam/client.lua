--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local params = {
   mode = "client",
   protocol = "any",
   key = config.certs .. "clientAkey.pem",
   certificate = config.certs .. "clientA.pem",
   cafile = config.certs .. "rootA.pem",
   verify = {"peer", "fail_if_no_peer_cert"},
   options = "all",
   ciphers = "EDH+AESGCM"
}

local peer = socket.tcp()
peer:connect(config.serverIP, config.serverPort)

-- [[ SSL wrapper
peer = assert( ssl.wrap(peer, params) )
assert(peer:dohandshake())
--]]

print(peer:receive("*l"))
peer:close()
