--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local digestClient = {}

digestClient.name = "digest.client"

function digestClient.test()
   local ctx = {
      mode = "client",
      protocol = "tlsv1_2",
      key = sys.load_resource(config.certs .. "clientAkey.pem"),
      certificate = sys.load_resource(config.certs .. "clientA.pem"),
      cafile = sys.load_resource(config.certs .. "rootA.pem"),
      verify = {"peer", "fail_if_no_peer_cert"},
      options = "all",
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

return digestClient
