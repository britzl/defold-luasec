--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local client = {}

client.name = "curve-negotiation.client"

function client.test()
   local ctx = {
      mode = "client",
      protocol = "any",
      key = sys.load_resource(config.certs .. "clientAkey.pem"),
      certificate = sys.load_resource(config.certs .. "clientA.pem"),
      cafile = sys.load_resource(config.certs .. "rootA.pem"),
      verify = {"peer", "fail_if_no_peer_cert"},
      options = {"all"},
      --
      curve = "P-256:P-384",
   }

   local peer = socket.tcp()
   peer:connect(config.serverIP, config.serverPort)

   -- [[ SSL wrapper
   peer = assert( ssl.wrap(peer, ctx) )
   assert(peer:dohandshake())
   --]]

   print(peer:receive("*l"))
   peer:close()
end

return client