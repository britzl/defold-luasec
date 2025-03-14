--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local wantWriteClient = {}

wantWriteClient.name = "wantwrite.client"

function wantWriteClient.test()
   local params = {
      mode = "client",
      protocol = "tlsv1_2",
      key = sys.load_resource(config.certs .. "clientAkey.pem"),
      certificate = sys.load_resource(config.certs .. "clientA.pem"),
      cafile = sys.load_resource(config.certs .. "rootA.pem"),
      verify = {"peer", "fail_if_no_peer_cert"},
      options = "all",
   }

   local function wait(peer, err)
      if err == "wantread" then
         socket.select({peer}, nil)
      elseif err == "timeout" or err == "wantwrite" then
         socket.select(nil, {peer})
      else
         peer:close()
      end
   end


   local peer = socket.tcp()
   assert( peer:connect(config.serverIP, config.serverPort) )

   -- [[ SSL wrapper
   peer = assert( ssl.wrap(peer, params) )
   assert( peer:dohandshake() )
   --]]

   peer:settimeout(0.3)

   local str = "a rose is a rose is a rose is a...\n"
   for _ = 1, 10000 do
      print("Sending...")
      local succ, err = peer:send(str)
      for _ = 1, 1000 do
         succ, err = peer:send(str)
      end
      print("Waiting...", err)
      wait(peer, err)
   end
   peer:close()
end

return wantWriteClient