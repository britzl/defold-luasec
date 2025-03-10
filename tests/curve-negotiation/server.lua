--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local server = {}

server.name = "curve-negotiation.server"

function server.test()
   local ctx = {
      mode = "server",
      protocol = "any",
      key = sys.load_resource(config.certs .. "serverAkey.pem"),
      certificate = sys.load_resource(config.certs .. "serverA.pem"),
      cafile = sys.load_resource(config.certs .. "rootA.pem"),
      verify = {"peer", "fail_if_no_peer_cert"},
      options = {"all"},
      --
      curveslist = "P-384:P-256:P-521",
   }


   local server = socket.tcp()
   server:setoption('reuseaddr', true)
   assert( server:bind(config.serverBindAddress, config.serverPort) )
   server:listen()

   local peer = server:accept()

   -- [[ SSL wrapper
   peer = assert( ssl.wrap(peer, ctx) )
   assert( peer:dohandshake() )
   --]]

   peer:send("oneshot with curve negotiation test\n")
   peer:close()

   server:close()
end

return server
