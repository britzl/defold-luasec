local digestServer = {}

digestServer.name = "digest.server"

function digestServer.test()
   --
   -- Public domain
   --
   local socket = require("builtins.scripts.socket")
   local ssl    = require("luasec.ssl")
   local config = require("tests.config")

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
   assert( server:bind("*", config.serverPort) )
   server:listen()

   local peer = server:accept()

   -- [[ SSL wrapper
   peer = assert( ssl.wrap(peer, ctx) )
   assert( peer:dohandshake() )
   --]]

   local cert = peer:getpeercertificate()
   local sha1   = cert:digest("sha1")
   local sha256 = cert:digest("sha256")
   local sha512 = cert:digest("sha512")

   print("SHA1",   sha1)
   print("SHA256", sha256)
   print("SHA512", sha512)

   peer:send("oneshot test\n")
   peer:close()
   server:close()
end

return digestServer