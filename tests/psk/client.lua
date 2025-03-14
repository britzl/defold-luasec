--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

-- @param hint (nil | string)
-- @param max_identity_len (number)
-- @param max_psk_len (number)
-- @return identity (string)
-- @return PSK (string)
local function pskcb(hint, max_identity_len, max_psk_len)
   print(string.format("PSK Callback: hint=%q, max_identity_len=%d, max_psk_len=%d", hint, max_identity_len, max_psk_len))
   return "abcd", "1234"
end

local pskClient = {}

pskClient.name = "psk.client"

function pskClient.test()
   if not ssl.config.capabilities.psk then
      print("[ERRO] PSK not available")
      return
   end

   local params = {
      mode = "client",
      protocol = "tlsv1_2",
      psk = pskcb,
   }

   local peer = socket.tcp()
   peer:connect(config.serverIP, config.serverPort)

   peer = assert( ssl.wrap(peer, params) )
   assert(peer:dohandshake())

   print("--- INFO ---")
   local info = peer:info()
   for k, v in pairs(info) do
      print(k, v)
   end
   print("---")

   peer:close()
end

return pskClient
