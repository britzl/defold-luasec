--
-- Public domain
--
local ssl = require("luasec.ssl")

local M = {}

M.name = "loadkey"

function M.test()
  local pass = "foobar"
  local cfg = {
    protocol = "tlsv1",
    mode = "client",
    key = sys.load_resource("/tests/key/key.pem"),
  }

  -- Text password
  cfg.password = pass
  ctx, err = ssl.newcontext(cfg)
  assert(ctx, err)
  print("Text: ok")

  -- Callback
  cfg.password = function() return pass end
  ctx, err = ssl.newcontext(cfg)
  assert(ctx, err)
  print("Callback: ok")
end

return M
