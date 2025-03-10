--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local wantServer = {}

wantServer.named = "want.server"

function wantServer.test()
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
   socket.sleep(2) -- force the timeout in the client dohandshake()
   assert( peer:dohandshake() )
   --]]

   for i = 1, 10 do
      local v = tostring(i)
      io.write(v)
      io.flush()
      peer:send(v)
      socket.sleep(1) -- force the timeout in the client receive()
   end
   io.write("\n")
   peer:send("\n")
   peer:close()
   server:close()
end

return wantServer
