local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local sniServer = {}

sniServer.name = "sni.server"

function sniServer.test()
  local params01 = {
    mode = "server",
    protocol = "any",
    key = sys.load_resource(config.certs .. "serverAkey.pem"),
    certificate = sys.load_resource(config.certs .. "serverA.pem"),
    cafile = sys.load_resource(config.certs .. "rootA.pem"),
    verify = "none",
    options = "all",
    ciphers = "ALL:!ADH:@STRENGTH",
  }

  local params02 = {
    mode = "server",
    protocol = "any",
    key = sys.load_resource(config.certs .. "serverAAkey.pem"),
    certificate = sys.load_resource(config.certs .. "serverAA.pem"),
    cafile = sys.load_resource(config.certs .. "rootA.pem"),
    verify = "none",
    options = "all",
    ciphers = "ALL:!ADH:@STRENGTH",
  }

  --
  local ctx01 = ssl.newcontext(params01)
  local ctx02 = ssl.newcontext(params02)

  --
  local server = socket.tcp()
  server:setoption('reuseaddr', true)
  server:bind(config.serverBindAddress, config.serverPort)
  server:listen()
  local conn = server:accept()
  --

  -- Default context (when client does not send a name) is ctx01
  conn = ssl.wrap(conn, ctx01)

  -- Configure the name map
  local sni_map = {
    ["servera.br"]  = ctx01,
    ["serveraa.br"] = ctx02,
  }

  conn:sni(sni_map, true)

  assert(conn:dohandshake())
  --
  conn:send("one line\n")
  conn:close()
  server:close()
end

return sniServer
