--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local util   = require("tests.chain.util")
local config = require("tests.config")

local chainClient = {}

chainClient.name = "chain.client"

function chainClient.test()
  local ctx = {
    mode = "client",
    protocol = "tlsv1_2",
    key = sys.load_resource(config.certs .. "clientAkey.pem"),
    certificate = sys.load_resource(config.certs .. "clientA.pem"),
    cafile = sys.load_resource(config.certs .. "rootA.pem"),
    verify = {"peer", "fail_if_no_peer_cert"},
    options = "all",
  }

  local conn = socket.tcp()
  conn:connect(config.serverIP, config.serverPort)

  conn = assert( ssl.wrap(conn, ctx) )
  assert(conn:dohandshake())

  util.show( conn:getpeercertificate() )

  print("----------------------------------------------------------------------")

  for k, cert in ipairs( conn:getpeerchain() ) do
    util.show(cert)
  end

  local cert = conn:getpeercertificate()
  print( cert )
  print( cert:pem() )

  conn:close()
end

return chainClient
