local modemBackend = {}

local json = require("vendor.json")
local uuid = require("vendor.uuid")

local gcm = require("shared.gcm")
local async = require("shared.async")
local logger = require("shared.logger")
local tableutils = require("shared.tableutils")
local coroutines = require("shared.coroutines")

local sockType = require("shared.socket.types")

local defaultPort = 14762
local modem

modemBackend.ModemError = {
    UID_TAKEN = { id=1, description="UID already taken, please use another" },
    INVALID_OPTS = { id=2, description="Connection options are invalid" }
}
local ModemError = modemBackend.ModemError

modemBackend.ModemSocketStatus = {
    CONNECTING = 1,
    READY = 2,
    DEAD = 3
}
local ModemSocketStatus = modemBackend.ModemSocketStatus

local ModemSocket = {}

function ModemSocket.new(uid, port, stype)
    local self = {
        uid = uid,
        port = port,
        type = stype,
        status = ModemSocketStatus.CONNECTING,
        handlers = {},
        last_active = os.clock()
    }

    setmetatable(self, {
        __index = ModemSocket,
        __tostring = ModemSocket.tostring
    })

    -- Spawn listen thread
    self:spawnListener()

    return self
end

function ModemSocket:tostring()
    return "MSock<" .. tostring(self.uid) .. ">"
end

function ModemSocket:write(data)
    modem.transmit(self.port, self.port,
        json.encode({
            type="data",
            uid=self.uid,
            port=self.port,
            data=data
        }))
end

function ModemSocket:ping()
    logger.trace("Transmitting on port", self.port)
    modem.transmit(self.port, self.port,
        json.encode({
            type="ping",
            uid=self.uid,
            port=self.port
        }))
end

function ModemSocket:onRecieve(callback)
    table.insert(self.handlers, callback)
end

function ModemSocket:onDisconnect(callback)
    self.dcHandler = callback
end

function ModemSocket:spawnListener()
    gcm:addRoutine(function()
        self.status = ModemSocketStatus.READY

        while true do
            local event, evdata = tableutils.postpack(1, coroutine.yield("modem_message_data"))
            if event == "modem_message_data" then
                local data = tableutils.unpack(evdata)
                if data.type == "data" and data.uid == self.uid and type(data.data) == "table" then
                    self.last_active = os.clock()

                    logger.debug("MSocket", self.uid, "received:", data)
                    if #self.handlers == 0 then
                        logger.warn("Discarding unhandled modem message.")
                    end

                    for i = 1, #self.handlers do
                        self.handlers[i](data.data)
                    end
                elseif data.type == "ping" then
                    logger.trace("Recieved ping, sending pong!")
                    modem.transmit(self.port, self.port, json.encode({
                        type = "pong",
                        uid = self.uid,
                        port = self.port
                    }))
                elseif data.type == "pong" and data.uid == self.uid then
                    self.last_active = os.clock()
                    logger.trace("Recieved pong from", self.uid)
                end
            end
        end
    end)
end


function modemBackend.tryInit()
    if not peripheral then return end
    modem = peripheral.find("modem")
    if modem then
        logger.debug("Using " .. (
            modem.isWireless() and "wireless" or ""
        ) .. " modem for socket backend")

        return true
    end
end

function modemBackend.listen(callback, options)
    options = options or {}

    local port = options.port or defaultPort
    modem.open(port)
    logger.debug("Modem backend opened port " .. port .. " for connections")

    local activeSockets = {}
    local channelPortMap = {}

    local function tryClosePortMap(socket)
        local mapping = channelPortMap[socket.port]
        if not mapping then
            logger.error("Socket was never inserted into portmap?")

            return -- Don't close the port since apparently it was never opened?
        end

        if socket.dcHandler then
            socket:dcHandler()
        end

        for i = 1, #mapping do
            if mapping[i] == socket.uid then
                table.remove(mapping, i)
            end
        end

        if #mapping == 0 then
            logger.debug("Closing port " .. socket.port)
            modem.close(socket.port)
            channelPortMap[socket.port] = nil
        end
    end

    local function tryConnect(data, reply)
        if options.service ~= data.service then
            return -- Not meant for us
        end

        logger.debug("Attempted connection on port " .. reply .. " by " .. tostring(data.uid))

        if type(data.uid) ~= "string" and type(data.port) ~= "number" then
            return modem.transmit(reply, 65535,
                json.encode({ type="connect", uid=data.uid, ok=false, error=ModemError.INVALID_OPTS }))
        end

        if activeSockets[data.uid] then
            logger.debug("Connector tried to take existing uid")
            return modem.transmit(reply, 65535,
                json.encode({ type="connect", uid=data.uid, ok=false, error=ModemError.UID_TAKEN }))
        end

        activeSockets[data.uid] = ModemSocket.new(data.uid, data.port, sockType.SocketType.COMPANION)
        if not channelPortMap[data.port] then
            logger.debug("Opening port " .. data.port)
            modem.open(data.port)
            channelPortMap[data.port] = {}
        end

        table.insert(channelPortMap[data.port], data.uid)
        callback(activeSockets[data.uid])

        return modem.transmit(data.port, data.port,
            json.encode({ type="connect", uid=data.uid, ok=true }))
    end

    coroutines.loop(
        function() -- Ping check thread
            while true do
                coroutines.runTimer(10)

                for id, socket in pairs(activeSockets) do
                    socket:ping()

                    if os.clock() - socket.last_active > 30 then
                        logger.warn(socket, " is not responding to pings, dropping...")

                        -- Drop the connection
                        activeSockets[id] = nil

                        -- Try to close the port
                        tryClosePortMap(socket)
                    end
                end
            end
        end, function() -- Connection thread
            local servStr = options.service and ("for '" .. options.service .. "'") or ""
            logger.info("Modem backend now listening on port " .. port, servStr)

            while true do
                local event, evdata = tableutils.postpack(1, coroutine.yield("modem_message"))
                if event == "modem_message" then
                    local _, _, reply, msg = tableutils.unpack(evdata)
                    local success, data = pcall(json.decode, msg)
                    if success and type(data) == "table" then
                        if data.type == "connect" then
                            tryConnect(data, reply)
                        else
                            os.queueEvent("modem_message_data", data)
                        end
                    else
                        logger.debug("Invalid JSON received: '" .. msg .. "'")
                    end
                end
            end
        end)
end

local function genPort()
    return math.random(1000, 9999)
end

function modemBackend.connect(options)
    return async.Promise.new(function(resolve, reject)
        options = options or {}
        local port = options.port or defaultPort
        local selfPort = options.selfPort or genPort()
        local uid = uuid()

        modem.open(selfPort)
        modem.transmit(port, selfPort, json.encode({
            type = "connect",
            uid = uid,
            port = selfPort,
            service = options.service
        }))
            --'{"type":"connect","uid":"' .. uid .. '","port":9876}')
        gcm:addRoutine(function()
            while true do
                local event, evdata = tableutils.postpack(1, coroutine.yield("modem_message"))
                if event == "modem_message" then
                    local _, _, _, msg = tableutils.unpack(evdata)
                    local success, data = pcall(json.decode, msg)
                    if success and type(data) == "table" then
                        logger.trace("Modem message:", data)

                        if data.type == "connect" and data.uid == uid then
                            if data.ok then
                                if options.service then
                                    logger.info("Established connection to '" .. options.service .. "' as", uid)
                                else
                                    logger.info("Connection established!")
                                end
                                resolve(ModemSocket.new(uid, selfPort, sockType.SocketType.INITIATOR))
                            else
                                logger.error("Error establishing connection:", data.error)
                                reject(data.error)
                            end
                        else
                            os.queueEvent("modem_message_data", data)
                        end
                    else
                        logger.debug("Invalid JSON received: '" .. msg .. "'")
                    end
                end
            end
        end)
    end)
end

return modemBackend
