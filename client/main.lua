-- This has to be done first in order to ensure require semantics
local conn = require("client.connection") -- Make sure connection is setup





local logger = require("shared.logger")
local async = require("shared.async")

-- conn:request("newgame", {
--     color = colors.purple,
--     title = "Lemmmy's Private room",
--     name = "Emma",
--     private = true
-- })

conn:request("joingame", {
    color = colors.brown,
    name = "Lemmmy",
    code = "UOIG"
})

conn:request("games"):next(function(d)
    logger.info(d)
end)

-- logger.init({
--     require("shared.logger.backends.console").new()
-- }, { level = logger.LogLevels.ALL })
-- print("hi")
local s_width, s_height = term.getSize()

local Canvas = require("client.canvas")
local canvas = Canvas.new(17, 1, 35, 19)
canvas:render()

local ColorSelector = require("client.colorselector")
local cselector = ColorSelector.new(50, 2)
cselector:render()

local WordBar = require("client.wordbar")
local wordbar = WordBar.new(35)
wordbar:render()

local ToolBar = require("client.toolbar")
local toolbar = ToolBar.new(18, s_height)
toolbar:render()

local Messages = require("client.messages")
local messages = Messages.new(14)
messages:render()
messages:placeCursor()

while true do
    os.pullEvent()
end

-- local co = require("shared.socket")
-- local sock = async.await { co.connect({service="sccriblio"}) }
-- logger.info(sock)

-- local resp = async.await { sock:request("games") }
-- logger.info(resp)
-- local x = peripheral.wrap("left")

-- x.open(9876)
-- local uid = uuid()
-- x.transmit(14762, 9876, '{"type":"connect","uid":"' .. uid .. '","port":9876}')
-- x.transmit(14762, 9876, '{"type":"data","uid":"' .. uid .. '","port":9876,"data":{"prop": 4}}')

-- print(os.pullEvent("modem_message"))

-- co.loop(function()
--     print("a")
--     -- coroutine.yield()
-- end, function()
--     print("b")
--     -- coroutine.yield()
-- end, function()
--     while true do
--         co.runTimer(0.5)
--         print("hey")
--     end
-- end)

-- logger.debug("I shouldn't appear")
-- logger.info("I did a thing")
-- logger.warn("Yoo123")
-- logger.error("oopsie")
-- logger.fatal("FUCK")

-- logger.destroy()
