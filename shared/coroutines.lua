local coroutines = {}

local tableutils = require("shared.tableutils")
local logger = require("shared.logger")

local function isDead(co)
    if not co then return true end

    return coroutine.status(co) == "dead"
end

coroutines.Manager = {}
function coroutines.Manager.new()
    local self = {
        routines = {},
        garbage = {},
        running = false,
        id_counter = 0,
    }

    return setmetatable(self, { __index = coroutines.Manager })
end

function coroutines.Manager:addRoutine(constructor, ...)
    self.id_counter = (self.id_counter + 1) % 2^32
    local co = setmetatable({
        id = self.id_counter,
        constructor = constructor,
        thread = coroutine.create(constructor)
    }, { __tostring = function(self)
        return tostring(self.thread) .. "<" .. tostring(self.constructor) .. ">"
    end})

    logger.trace("Priming " .. tostring(co))
    local success, datum = coroutine.resume(co.thread, ...)
    if success then
        if coroutine.status(co.thread) == "suspended" then
            co.filter = datum
            table.insert(self.routines, co)
        end
        logger.trace("Primed " .. tostring(co))

        return self.id_counter
    else
        logger.fatal("Error priming " .. tostring(co) .. ": " .. datum)

        return false
    end
end

function coroutines.Manager:killRoutine(id)
    logger.trace("Thread " .. tostring(id) .. " marked for culling")
    table.insert(self.garbage, id)
end

function coroutines.Manager:shutdown()
    self.running = false
    coroutine.yield()
end

function coroutines.Manager:run(main, disableTerminate)
    self.running = true
    self:addRoutine(require, main)

    while self.running and #self.routines > 0 do
        local event = {coroutine.yield()}

        if event[1] == "terminate" then
            if not disableTerminate then
                self.running = false
                break
            end
        end

        self.garbage = {}
        for i = 1, #self.routines do
            local co = self.routines[i]
            if isDead(co.thread) then
                logger.trace("Marking " .. tostring(co) .. " for collection")
                table.insert(self.garbage, co.id)
            else
                if co.filter == event[1] or not co.filter then
                    local success, datum = coroutine.resume(co.thread, tableutils.unpack(event))
                    if not self.running then
                        break
                    end

                    if success then
                        if type(datum) == "string" then
                            co.filter = datum
                        else
                            co.filter = nil
                        end
                    else
                        logger.error("Error resuming coroutine: " .. datum)
                        logger.trace("Marking " .. tostring(co) .. " for collection")
                        table.insert(self.garbage, co.id)
                    end
                end
            end
        end

        for i = 1, #self.garbage do
            for j = 1, #self.routines do
                local co = self.routines[j]
                if co.id == self.garbage[i] then
                    logger.trace("Collecting", self.routines[j])
                    table.remove(self.routines, j)
                    break
                end
            end
        end
    end

    logger.info("Coroutine manager shutting down...")
end


function coroutines.loop(...)
    local routineCount = select("#", ...)
    local routineConstructors = {...}
    local activeRoutines = {}
    local filters = {}

    local first = true
    while true do
        local event
        if first then
            first = false
        else
            event = {coroutine.yield()}
        end

        if event and event[1] == "terminate" then
            break
        end

        for i = 1, routineCount do
            local resumeSuccess = true
            if isDead(activeRoutines[i]) then
                activeRoutines[i] = coroutine.create(routineConstructors[i])
                resumeSuccess, filters[i] = coroutine.resume(activeRoutines[i])
            else
                if filters[i] == event[1] or not filters[i] then
                    resumeSuccess, filters[i] = coroutine.resume(activeRoutines[i], tableutils.unpack(event))
                end
            end

            if not resumeSuccess then
                logger.error("Error resuming coroutine: " .. filters[i])
                filters[i] = nil
            end
        end
    end
end

function coroutines.runTimer(duration)
    local timerId = os.startTimer(duration)
    while true do
        local e, i = coroutine.yield("timer")
        if e == "timer" and i == timerId then
            return
        end
    end
end

return coroutines
