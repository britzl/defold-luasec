--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local params = {
   mode = "client",
   protocol = "tlsv1_2",
   key = config.certs .. "clientAkey.pem",
   certificate = config.certs .. "clientA.pem",
   cafile = config.certs .. "rootA.pem",
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
      os.exit(1)
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
while true do
   print("Sending...")
   local succ, err = peer:send(str)
   while succ do
      succ, err = peer:send(str)
   end
   print("Waiting...", err)
   wait(peer, err)
end
peer:close()
