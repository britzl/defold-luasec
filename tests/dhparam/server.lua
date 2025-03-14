--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local function readfile(filename)
  local dh = sys.load_resource("/tests/dhparam/" .. filename)
  assert(dh)
  return dh
end

local function dhparam_cb(export, keylength)
  print("---")
  print("DH Callback")
  print("Export", export)
  print("Key length", keylength)
  print("---")
  -- always return key with length 2048 because less length is unsupported in current OpenSSL version
  local filename = "dh-2048.pem"
  return readfile(filename)
end

local dhparamServer = {}

dhparamServer.name = "dhparam.server"

function dhparamServer.test()
  local params = {
    mode = "server",
    protocol = "tlsv1_2",
    key = sys.load_resource(config.certs .. "serverAkey.pem"),
    certificate = sys.load_resource(config.certs .. "serverA.pem"),
    cafile = sys.load_resource(config.certs .. "rootA.pem"),
    verify = {"peer", "fail_if_no_peer_cert"},
    options = "all",
    dhparam = dhparam_cb,
    ciphers = "EDH+AESGCM"
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
  -- --]]

  peer:send("oneshot test\n")
  peer:close()
  server:close()
end

return dhparamServer
