--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

-- @param identity (string)
-- @param max_psk_len (number)
-- @return psk (string)
local function pskcb(identity, max_psk_len)
   print(string.format("PSK Callback: identity=%q, max_psk_len=%d", identity, max_psk_len))
   if identity == "abcd" then
     return "1234"
  end
  return nil
end

local pskServer = {}

pskServer.name = "psk.server"

function pskServer.test()
   if not ssl.config.capabilities.psk then
      print("[ERRO] PSK not available")
      return
   end
   local params = {
      mode = "server",
      protocol = "any",
      options = "all",

   -- PSK with just a callback
      psk = pskcb,

   -- PSK with identity hint
   --   psk = {
   --      hint = "hintpsksample",
   --      callback = pskcb,
   --   },
   }


   -- [[ SSL context
   local ctx = assert(ssl.newcontext(params))
   --]]

   local server = socket.tcp()
   server:setoption('reuseaddr', true)
   assert( server:bind(config.serverBindAddress, config.serverPort) )
   server:listen()

   local peer = server:accept()
   peer = assert( ssl.wrap(peer, ctx) )
   assert( peer:dohandshake() )

   print("--- INFO ---")
   local info = peer:info()
   for k, v in pairs(info) do
      print(k, v)
   end
   print("---")

   peer:close()
   server:close()
end

return pskServer
