--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local params = {
   mode         = "server",
   protocol     = "any",
   certificates = { 
      -- Comment line below and 'client-rsa' stop working
      { certificate = config.certs .. "serverRSA.pem",   key = config.certs .. "serverRSAkey.pem"   },
      -- Comment line below and 'client-ecdsa' stop working
      { certificate = config.certs .. "serverECDSA.pem", key = config.certs .. "serverECDSAkey.pem" }
   },
   verify  = "none",
   options = "all"
}


-- [[ SSL context
local ctx = assert(ssl.newcontext(params))
--]]

local server = socket.tcp()
server:setoption('reuseaddr', true)
assert( server:bind("*", config.serverPort) )
server:listen()

local peer = server:accept()

-- [[ SSL wrapper
peer = assert( ssl.wrap(peer, ctx) )
assert( peer:dohandshake() )
--]]

peer:send("oneshot test\n")
peer:close()
