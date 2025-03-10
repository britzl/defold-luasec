--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local M = {}

function M.run()
   local params = {
      mode        = "client",
      protocol    = "tlsv1_2",
      key         = sys.load_resource("/tests/multicert/certs/clientECDSAkey.pem"),
      certificate = sys.load_resource("/tests/multicert/certs/clientECDSA.pem"),
      verify      = "none",
      options     = "all",
      ciphers     = "ALL:!aRSA"
   }

   local peer = socket.tcp()
   peer:connect(config.serverIP, config.serverPort)

   -- [[ SSL wrapper
   peer = assert( ssl.wrap(peer, params) )
   assert(peer:dohandshake())
   --]]

   local i = peer:info()
   for k, v in pairs(i) do print(k, v) end

   print(peer:receive("*l"))
   peer:close()
end

return M
