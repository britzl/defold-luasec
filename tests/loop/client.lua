--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local infoClient = {}

infoClient.name = "info.client"

function infoClient.test()
   local params = {
      mode = "client",
      protocol = "tlsv1_2",
      key = sys.load_resource(config.certs .. "clientAkey.pem"),
      certificate = sys.load_resource(config.certs .. "clientA.pem"),
      cafile = sys.load_resource(config.certs .. "rootA.pem"),
      verify = {"peer", "fail_if_no_peer_cert"},
      options = "all",
   }

   while true do
      local peer = socket.tcp()
      assert( peer:connect(config.serverIP, config.serverPort) )

      -- [[ SSL wrapper
      peer = assert( ssl.wrap(peer, params) )
      assert( peer:dohandshake() )
      --]]

      peer:getpeercertificate():extensions()

      print(peer:receive("*l"))
      peer:close()
   end
end

return infoClient
