--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local infoServer = {}

infoServer.name = "info.server"

function infoServer.test()
  local params = {
    mode = "server",
    protocol = "any",
    key = sys.load_resource(config.certs .. "serverAkey.pem"),
    certificate = sys.load_resource(config.certs .. "serverA.pem"),
    cafile = sys.load_resource(config.certs .. "rootA.pem"),
    verify = {"peer", "fail_if_no_peer_cert"},
    options = "all",
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

  -- Before handshake: nil
  print( peer:info() )

  assert( peer:dohandshake() )
  --]]

  print("---")
  local info = peer:info()
  for k, v in pairs(info) do
    print(k, v)
  end

  print("---")
  print("-> Compression", peer:info("compression"))

  peer:send("oneshot test\n")
  peer:close()
  server:close()
end

return infoServer
