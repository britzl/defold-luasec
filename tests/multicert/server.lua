--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local multicertServer = {}

multicertServer.name = "mutlicert.server"

function multicertServer.test()
   local params = {
      mode         = "server",
      protocol     = "any",
      certificates = {
         -- Comment line below and 'client-rsa' stop working
         { certificate = sys.load_resource(config.certs .. "serverRSA.pem"),   key = sys.load_resource(config.certs .. "serverRSAkey.pem")   },
         -- Comment line below and 'client-ecdsa' stop working
         { certificate = sys.load_resource(config.certs .. "serverECDSA.pem"), key = sys.load_resource(config.certs .. "serverECDSAkey.pem") }
      },
      verify  = "none",
      options = "all"
   }


   -- [[ SSL context
   local ctx = assert(ssl.newcontext(params))
   --]]

   local server = socket.tcp()
   server:setoption('reuseaddr', true)
   assert( server:bind(config.serverBindAddress, config.serverPort) )
   server:listen()

   for _ = 1, 2 do
      local peer = server:accept()

      -- [[ SSL wrapper
      peer = assert( ssl.wrap(peer, ctx) )
      assert( peer:dohandshake() )
      --]]

      peer:send("oneshot test\n")
      peer:close()
   end
   server:close()
end

return multicertServer
