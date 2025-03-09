--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local util   = require("tests.chain.util")
local config = require("tests.config")

local chainServer = {}

chainServer.name = "chain.server"

function chainServer.test()
  local ctx = {
    mode = "server",
    protocol = "any",
    key = sys.load_resource(config.certs .. "serverAkey.pem"),
    certificate = sys.load_resource(config.certs .. "serverA.pem"),
    cafile = sys.load_resource(config.certs .. "rootA.pem"),
    verify = {"peer", "fail_if_no_peer_cert"},
    options = "all",
  }

  local server = socket.tcp()
  server:setoption('reuseaddr', true)
  assert( server:bind("*", config.serverPort) )
  server:listen()

  local conn = server:accept()

  conn = assert( ssl.wrap(conn, ctx) )
  assert( conn:dohandshake() )

  util.show( conn:getpeercertificate() )

  print("----------------------------------------------------------------------")

  local expectedpeerchain = { sys.load_resource(config.certs .. "clientAcert.pem"), sys.load_resource(config.certs .. "rootA.pem") }

  local peerchain = conn:getpeerchain()
  assert(#peerchain == #expectedpeerchain)
  for k, cert in ipairs( peerchain ) do
    util.show(cert)
    local expectedpem = expectedpeerchain[k]
    assert(cert:pem() == expectedpem, "peer chain mismatch @ "..tostring(k))
  end

  local expectedlocalchain = { sys.load_resource(config.certs .. "serverAcert.pem") }

  local localchain = assert(conn:getlocalchain())
  assert(#localchain == #expectedlocalchain)
  for k, cert in ipairs( localchain ) do
    util.show(cert)
    local expectedpem = expectedlocalchain[k]
    assert(cert:pem() == expectedpem, "local chain mismatch @ "..tostring(k))
    if k == 1 then
      assert(cert:pem() == conn:getlocalcertificate():pem())
    end
  end

  local str = ctx.cafile

  util.show( ssl.loadcertificate(str) )

  print("----------------------------------------------------------------------")
  local cert = conn:getpeercertificate()
  print( cert )
  print( cert:digest() )
  print( cert:digest("sha1") )
  print( cert:digest("sha256") )
  print( cert:digest("sha512") )

  conn:close()
  server:close()
end

return chainServer
