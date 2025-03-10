--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local verifyClient = {}

verifyClient.name = "verify.client"

function verifyClient.test()
  local params = {
    mode = "client",
    protocol = "tlsv1_2",
    key = sys.load_resource(config.certs .. "serverBkey.pem"),
    certificate = sys.load_resource(config.certs .. "serverB.pem"),
    cafile = sys.load_resource(config.certs .. "rootB.pem"),
    verify = {"peer", "fail_if_no_peer_cert"},
    verifyext = {"lsec_continue", "lsec_ignore_purpose"},
    options = "all",
  }

  local ctx = assert(ssl.newcontext(params))

  local peer = socket.tcp()
  peer:connect(config.serverIP, config.serverPort)

  peer = assert( ssl.wrap(peer, ctx) )
  assert(peer:dohandshake())

  local succ, errs = peer:getpeerverification()
  print(succ, errs)
  for i, err in pairs(errs) do
    for j, msg in ipairs(err) do
      print("depth = " .. i, "error = " .. msg)
    end
  end

  print(peer:receive("*l"))
  peer:close()
end

return verifyClient
