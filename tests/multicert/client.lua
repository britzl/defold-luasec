local client_ecdsa = require("tests.multicert.client-ecdsa")
local client_rsa = require("tests.multicert.client-rsa")

local muticertClient = {}

muticertClient.name = "multicert.client"

function muticertClient.test()
    print("Run RSA client")
    client_rsa.run()

    print("Run ECDSA client")
    client_ecdsa.run()
end

return muticertClient
