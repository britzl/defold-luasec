--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local params = {
   mode = "server",
   protocol = "tlsv1",
   key = config.certs .. "serverAkey.pem",
   certificate = config.certs .. "serverA.pem",
   cafile = config.certs .. "rootA.pem",
   verify = {"peer", "fail_if_no_peer_cert"},
   options = "all",
   verifyext = {"lsec_continue", "crl_check", "crl_check_chain"},
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
assert( peer:dohandshake() )
--]]

local succ, errs = peer:getpeerverification()
print(succ, errs)
for i, err in pairs(errs) do
  for j, msg in ipairs(err) do
    print("depth = " .. i, "error = " .. msg)
  end
end

peer:send("oneshot test\n")
peer:close()
