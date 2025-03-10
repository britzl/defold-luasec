--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local wantWriteServer = {}

wantWriteServer.name = "wantwrite.server"

function wantWriteServer.test()
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
   local ctx = assert(ssl.newcontext(params))
   --]]

   local server = socket.tcp()
   server:setoption('reuseaddr', true)
   assert( server:bind(config.serverBindAddress, config.serverPort) )
   server:listen()

   local peer = server:accept()

   -- [[ SSL wrapper
      peer = assert( ssl.wrap(peer, ctx) )
      assert( peer:dohandshake() )
   --]]

   while true do
      local str = peer:receive("*l")
      print(str)
   end
   peer:close()
   server:close()
end

return wantWriteServer
