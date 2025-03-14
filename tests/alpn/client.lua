local alpnClient = {}

alpnClient.name = "alpn.client"


function alpnClient.test()
   --
   -- Public domain
   --
   local socket = require("builtins.scripts.socket")
   local ssl    = require("luasec.ssl")
   local config = require("tests.config")

   local ctx = {
      mode = "client",
      protocol = "tlsv1_2",
      key = sys.load_resource(config.certs .. "clientAkey.pem"),
      certificate = sys.load_resource(config.certs .. "clientA.pem"),
      cafile = sys.load_resource(config.certs .. "rootA.pem"),
      verify = {"peer", "fail_if_no_peer_cert"},
      options = "all",
      --alpn = {"foo","bar","baz"}
      alpn = "foo"
   }

   local peer = socket.tcp()
   peer:connect(config.serverIP, config.serverPort)

   peer = assert( ssl.wrap(peer, ctx) )
   assert(peer:dohandshake())

   print("ALPN", peer:getalpn())

   peer:close()
end

return alpnClient
