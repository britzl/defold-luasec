local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local params = {
  mode = "client",
  protocol = "tlsv1_2",
  key = config.certs .. "clientAkey.pem",
  certificate = config.certs .. "clientA.pem",
  cafile = config.certs .. "rootA.pem",
  verify = "peer",
  options = "all",
}

local conn = socket.tcp()
conn:connect(config.serverIP, config.serverPort)

-- TLS/SSL initialization
conn = ssl.wrap(conn, params)

-- Comment the lines to not send a name
--conn:sni("servera.br")
--conn:sni("serveraa.br")
conn:sni("serverb.br")

assert(conn:dohandshake())
--
local cert = conn:getpeercertificate()
for k, v in pairs(cert:subject()) do
  for i, j in pairs(v) do
    print(i, j)
  end
end
--
print(conn:receive("*l"))
conn:close()
