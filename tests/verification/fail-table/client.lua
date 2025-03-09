--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local params = {
   mode = "client",
   protocol = "tlsv1",
   key = config.certs .. "clientBkey.pem",
   certificate = config.certs .. "clientB.pem",
   cafile = config.certs .. "rootB.pem",
   verify = {"peer", "fail_if_no_peer_cert"},
   options = "all",
   verifyext = "lsec_continue",
}

-- [[ SSL context
local ctx = assert(ssl.newcontext(params))
--]]

local peer = socket.tcp()
peer:connect(config.serverIP, config.serverPort)

-- [[ SSL wrapper
peer = assert( ssl.wrap(peer, ctx) )
assert(peer:dohandshake())
--]]

local succ, errs = peer:getpeerverification()
print(succ, errs)
for i, err in pairs(errs) do
  for j, msg in ipairs(err) do
    print("depth = " .. i, "error = " .. msg)
  end
end

print(peer:receive("*l"))
peer:close()
