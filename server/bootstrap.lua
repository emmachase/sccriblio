
local logger = require("shared.logger")
logger.init({
    require("shared.logger.backends.console").new()
}, { level = logger.LogLevels.INFO })

local gcm = require("shared.gcm")


logger.info("Bootstrapping application...")
gcm:run("server.main")





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

logger.destroy()
