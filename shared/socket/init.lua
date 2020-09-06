local socket = {}

local uuid = require("vendor.uuid")

local logger = require("shared.logger")
local async = require("shared.async")
local fn = require("shared.funcutils")

local sockType = require("shared.socket.types")

socket.backends = {
    require("shared.socket.backends.modem")
}

local backend
for i = 1, #socket.backends do
    if socket.backends[i].tryInit() then
        backend = socket.backends[i]
        break
    end
end

if not backend then
    error("No socket backend could be initialized."
    .. " Please add attach a modem to your computer.")
end

socket.Socket = {}
function socket.Socket.new(bsocket)
    local self = {
        uuid = uuid(),
        bsocket = bsocket,
        handlers = {},
        request_handlers = {},
        active_requests = {},
        hid = 0,
        rid = 0
    }

    bsocket:onRecieve(fn.bind(socket.Socket.handleMsg, self))
    bsocket:onDisconnect(function()
        if self.onDisconnect then
            self:onDisconnect()
        end
    end)

    setmetatable(self, {
        __index = socket.Socket,
        __tostring = socket.Socket.tostring
    })
    return self
end

function socket.Socket:tostring()
    return "Socket<" .. tostring(self.bsocket) .. ">"
end

function socket.Socket:handleMsg(msg)
    logger.debug("Socket message:", msg)
    if msg.type == "event" then
        if type(msg.data) == "table" then
            if self.handlers[msg.event] then
                for _, handler in ipairs(self.handlers[msg.event]) do
                    handler.callback(msg.data)
                end
            else
                logger.warn("Received unrouted event", msg.event, msg.data)
            end
        end
    elseif msg.type == "request" then
        if type(msg.rid) ~= "number" then return end
        if self.request_handlers[msg.request] then
            self.request_handlers[msg.request]({
                succeed = function(response)
                    self.bsocket:write({
                        ok=true,
                        type="response",
                        rid=msg.rid,
                        data=response
                    })
                end,
                fail = function(err)
                    self.bsocket:write({
                        ok=false,
                        type="response",
                        rid=msg.rid,
                        error=err
                    })
                end
            }, msg.data)
        else
            logger.error("Invalid endpoint '" .. msg.request .. "' requested")
            self.bsocket:write({
                ok=false,
                type="response",
                rid=msg.rid,
                error="No such request defined"
            })
        end
    elseif msg.type == "response" then
        if type(msg.rid) ~= "number" then return end
        if self.active_requests[msg.rid] then
            if msg.ok then
                self.active_requests[msg.rid][1](msg.data)
                self.active_requests[msg.rid] = nil
            else
                self.active_requests[msg.rid][2](msg.error)
                self.active_requests[msg.rid] = nil
            end
        end
    end
end

function socket.Socket:handleDisconnect(callback)
    self.onDisconnect = callback
end

function socket.Socket:request(rtype, data)
    self.rid = (self.rid + 1) % 2^32
    return async.Promise.new(function(resolve, reject)
        self.active_requests[self.rid] = {resolve, reject}
        self.bsocket:write({
            type="request",
            request=rtype,
            rid = self.rid,
            data = data or {}
        })
    end)
end

function socket.Socket:emit(event, data)
    self.bsocket:write({
        type="event",
        event = event,
        data = data
    })
end

function socket.Socket:handle(rtype, func)
    self.request_handlers[rtype] = func
end

function socket.Socket:on(event, callback)
    self.hid = self.hid + 1
    self.handlers[event] = self.handlers[event] or {}
    table.insert(self.handlers[event], {
        hid = self.hid,
        callback = callback
    })

    return self.hid
end

function socket.Socket:off(event, hid)
    local hlist = self.handlers[event]
    if not hlist then return end
    for i = 1, #hlist do
        if hlist[i].hid == hid then
            table.remove(hlist, i)
            break
        end
    end
end

local handleSocketConnection = async { function(onNewSocket, sock)
    logger.debug("BSocket Connection:", sock.uid)
    -- local msgQueue = {}



    -- TODO: Encryption?
    -- if sock.type == sockType.SocketType.COMPANION then
    --     -- We go first.
    --     -- sock:write()
    -- else -- INITIATOR

    -- end

    onNewSocket(socket.Socket.new(sock))
    -- onConnectionEstablished()
end }

function socket.listen(options, onNewSocket)
    backend.listen(fn.bind(handleSocketConnection, onNewSocket), options)
end

function socket.connect(options)
    return backend.connect(options):next(socket.Socket.new)
end

return socket
