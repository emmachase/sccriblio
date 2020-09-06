local defaultLogLevel = _G.LOG_LEVEL or "info"
local logger = {}

logger.LogLevels = {
    "off", OFF = "off",
    "fatal", FATAL = "fatal",
    "error", ERROR = "error",
    "warn", WARN = "warn",
    "info", INFO = "info",
    "debug", DEBUG = "debug",
    "trace", TRACE = "trace",
    ALL = "all"
}

local instance -- Logger is setup as singleton
function logger.init(backends, options)
    backends = backends or {}
    options = options or {}

    if instance then
        error("Logger already initialized. Use logger.destroy() to reset.", 2)
    end

    for i = 1, #backends do
        local backend = backends[i]
        for _, level in ipairs(logger.LogLevels) do
            if not backend[level] and not backend.generic then
                error("Backend #" .. i .. " (" .. tostring(backend) .. ") does"
                .. " not implement '" .. level .. "' and does not provide a"
                .. " generic logger method.")
            end
        end
    end

    local maxLevel = options.level or defaultLogLevel
    local enabledLevels = {}
    for _, level in ipairs(logger.LogLevels) do
        enabledLevels[level] = true
        if level == maxLevel then
            break
        end
    end

    instance = {
        backends = backends,
        options = options,
        enabledLevels = enabledLevels
    }
end

function logger.destroy()
    for i = 1, #instance.backends do
        local bk = instance.backends[i]
        if bk.destroy then
            bk:destroy()
        end
    end

    instance = nil
end

-------------------------------------
local function checkValid(level)
    if not instance then
        error("Logger not initialized, use logger.init first", 4)
    end

    if not instance.enabledLevels[level] then
        return false
    end

    return true
end

local function dispatch(level, valueList)
    if not checkValid(level) then return end

    for _, backend in ipairs(instance.backends) do
        if backend[level] then
            backend[level](backend, valueList)
        else
            backend:generic(level, valueList)
        end
    end
end

function logger.fatal(...)
    dispatch("fatal", {...})
end

function logger.error(...)
    dispatch("error", {...})
end

function logger.warn(...)
    dispatch("warn", {...})
end

function logger.info(...)
    dispatch("info", {...})
end

function logger.debug(...)
    dispatch("debug", {...})
end

function logger.trace(...)
    dispatch("trace", {...})
end

return logger
