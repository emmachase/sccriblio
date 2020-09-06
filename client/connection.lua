local co = require("shared.socket")
local gcm = require("shared.gcm")
local async = require("shared.async")

local ui = require("client.uiutil")

local sock
local loadingScreen = async { function()
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Connecting...")
    while not sock do
        os.sleep(0.5)
    end
end }

local connectTimeout = async { function(length)
    os.sleep(length)
    error("Connection timed out")
end }

local function errorScreen(err)
    if type(err) == "table" and err.description then
        err = err.description
    end

    while true do
        term.setBackgroundColor(colors.gray)
        term.clear()

        term.setTextColor(colors.white)
        ui.centerWrite(2, "Error connecting to server")

        term.setTextColor(colors.red)
        ui.centerWrite(4, tostring(err))

        os.sleep(0.5)
    end
end


while not sock do
    sock = async.await { async.Promise.any(
        loadingScreen(),
        connectTimeout(5),
        co.connect({service="sccriblio"})
    ):catch(errorScreen) }
end

return sock
