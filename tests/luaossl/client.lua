--
-- Public domain
--
local socket = require("builtins.scripts.socket")
local ssl    = require("luasec.ssl")
local config = require("tests.config")

local pkey = require "openssl.pkey"
local ssl_context = luasec.ssl.context
local x509 = luasec.ssl.x509
local x509_store = require "openssl.x509.store"

local function read_file(path)
	local file, err, errno = io.open(path, "rb")
	if not file then
		return nil, err, errno
	end
	local contents
	contents, err, errno = file:read "*a"
	file:close()
	return contents, err, errno
end

local ctx = ssl_context.new("TLSv1_2", false)
ctx:setPrivateKey(pkey.new(assert(read_file(config.certs .. "clientAkey.pem"))))
ctx:setCertificate(x509.new(assert(read_file(config.certs .. "clientA.pem"))))
local store = x509_store.new()
store:add(config.certs .. "rootA.pem")
ctx:setStore(store)
ctx:setVerify(ssl_context.VERIFY_FAIL_IF_NO_PEER_CERT)

local peer = socket.tcp()
peer:connect(config.serverIP, config.serverPort)

-- [[ SSL wrapper
peer = assert( ssl.wrap(peer, ctx) )
assert(peer:dohandshake())
--]]

print(peer:receive("*l"))
peer:close()
