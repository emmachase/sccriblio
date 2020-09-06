local async = {}

local tableutils = require("shared.tableutils")
local logger = require("shared.logger")
local gcm = require("shared.gcm")

async.Promise = {
    States = { PENDING = 1, RESOLVED = 2, REJECTED = 3, CANCELED = 4 }
}

local function dispatchYield(promise, waiter)
    logger.trace(tostring(promise), ": trying to dispatch")
    if promise.yield then
        if waiter then
            waiter(tableutils.unpack(promise.yield))
        end
    end
end

function async.Promise.new(runner)
    local self = {}
    self.status = async.Promise.States.PENDING
    setmetatable(self, {
        __index = async.Promise,
        __tostring = async.Promise.tostring
    })

    local resolve = function(...)
        if self.status ~= async.Promise.States.PENDING then
            return
        end

        self.status = async.Promise.States.RESOLVED
        self.yield = {...}
        dispatchYield(self, self.waiter)
    end

    local reject = function(...)
        if self.status ~= async.Promise.States.PENDING then
            return
        end

        self.status = async.Promise.States.REJECTED
        self.yield = {...}
        dispatchYield(self, self.catcher)
        if not self.catcher then
            logger.fatal("Unhandled promise rejection:", ...)
        end
    end

    self.rid = gcm:addRoutine(runner, resolve, reject)
    return self
end

--- Takes a list of promises, and returns a promise that resolves immediately when any of them resolve
function async.Promise.any(...)
    local promises = {...}
    return async.Promise.new(function(resolve, reject)
        local function cancelAll()
            for i = 1, #promises do
                promises[i]:cancel()
            end
        end

        for i = 1, #promises do
            local promise = promises[i]

            promise:next(function(...)
                cancelAll()
                resolve(...)
            end):catch(function(...)
                cancelAll()
                reject(...)
            end)
        end
    end)
end

function async.Promise:tostring()
    if self.status == async.Promise.States.PENDING then
        return "Promise<pending>"
    else
        return "Promise<" .. tostring(self.yield) .. ">"
    end
end

function async.Promise:cancel()
    if self.status == async.Promise.States.PENDING then
        self.status = async.Promise.States.CANCELED
    end
end

function async.Promise:next(callback)
    if self.status == async.Promise.States.RESOLVED then
        local val = {callback(tableutils.unpack(self.yield))}
        if select("#", tableutils.unpack(val)) > 0 then
            self.yield = val
        end

        return self
    end

    if self.waiter then
        local first = self.waiter
        self.waiter = function(...)
            local val = {first(...)}
            if select("#", tableutils.unpack(val)) > 0 then
                self.yield = val
            end

            return callback(tableutils.unpack(self.yield))
        end
    else
        self.waiter = callback
    end

    return self
end

function async.Promise:catch(callback)
    return async.Promise.new(function(resolve, reject)
        self:next(resolve)
        self.catcher = function(...)
            local s, e = tableutils.postpack(1, pcall(callback, ...))
            if s then
                resolve(tableutils.unpack(e))
            else
                reject(tableutils.unpack(e))
            end
        end
    end)
end

function async.Promise:finally(callback)
    return async.Promise.new(function(resolve, reject)
        self:next(function(...)
            resolve(...)
            callback(...)
        end):catch(function(...)
            reject(...)
            callback(...)
        end)
    end)
end

function async.await(promise)
    if type(promise[1]) == "table" then
        promise = promise[1]
    end

    if not promise.next then
        error("await called with non-promise", 2)
    end

    local returnValue
    promise:next(function(...)
        logger.trace(promise, ": resolved!")
        returnValue = {...}
    end)

    logger.trace("await : about to yield for", tostring(promise))
    while not returnValue do
        coroutine.yield()
    end

    return tableutils.unpack(returnValue)
end

setmetatable(async, { __call = function(_, val)
    if type(val) == "table" then
        val = val[1]
    end

    if type(val) ~= "function" then
        error("async generator called with non-function", 2)
    end

    return function(...)
        local args = {...}
        return async.Promise.new(function(resolve, reject)
            local success, datum = tableutils.postpack(1, pcall(val, tableutils.unpack(args)))
            if success then
                resolve(tableutils.unpack(datum))
            else
                reject(tableutils.unpack(datum))
            end
        end)
    end
end })

return async
