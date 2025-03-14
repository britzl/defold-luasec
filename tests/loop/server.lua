--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local loopServer = {}

loopServer.name = "loop.server"

function loopServer.test()
   local params = {
      mode = "server",
      protocol = "any",
      key = sys.load_resource(config.certs .. "serverAkey.pem"),
      certificate = sys.load_resource(config.certs .. "serverA.pem"),
      cafile = sys.load_resource(config.certs .. "rootA.pem"),
      verify = {"peer", "fail_if_no_peer_cert"},
      options = "all",
   }

   -- [[ SSL context 
   local ctx = assert( ssl.newcontext(params) )
   --]]

   local server = socket.tcp()
   server:setoption('reuseaddr', true)
   assert( server:bind(config.serverBindAddress, config.serverPort) )
   server:listen()

   while true do
      local peer = server:accept()

      -- [[ SSL wrapper
      peer = assert( ssl.wrap(peer, ctx) )
      assert( peer:dohandshake() )
      --]]

      peer:send("loop test\n")
      peer:close()
   end
   server:close()
end

return loopServer
