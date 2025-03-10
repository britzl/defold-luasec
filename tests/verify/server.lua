--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local verifyServer = {}

verifyServer.name = "verify.server"

function verifyServer.test()
  local params = {
    mode = "server",
    protocol = "any",
    key = sys.load_resource(config.certs .. "serverAkey.pem"),
    certificate = sys.load_resource(config.certs .. "serverA.pem"),
    cafile = sys.load_resource(config.certs .. "rootA.pem"),
    verify = {"peer", "fail_if_no_peer_cert"},
    verifyext = {"lsec_continue", "lsec_ignore_purpose"},
    options = "all",
  }


  local ctx = assert(ssl.newcontext(params))

  local server = socket.tcp()
  server:setoption('reuseaddr', true)
  assert( server:bind(config.serverBindAddress, config.serverPort) )
  server:listen()

  local peer = server:accept()

  peer = assert( ssl.wrap(peer, ctx) )
  assert( peer:dohandshake() )

  local succ, errs = peer:getpeerverification()
  print(succ, errs)
  for i, err in pairs(errs) do
    for j, msg in ipairs(err) do
      print("depth = " .. i, "error = " .. msg)
    end
  end

  peer:send("oneshot test\n")
  peer:close()
  server:close()
end

return verifyServer
