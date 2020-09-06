local gcm = require("shared.gcm")
if not gcm.running then
    error("Main entrypoint encountered without GCM running!")
end



local socket = require("shared.socket")
local logger = require("shared.logger")

local apierrors = require("shared.apierrors")
local validate = require("shared.validate")
local vtp = validate.types

local ScGame = require("server.game")

-- local async = require("shared.async")
-- local await = async.await

-- local plusOne = async {function(a)
--     return a + 1
-- end}

-- local prom = plusOne(2)
-- logger.info(prom)

-- local val = await { prom }
-- logger.info(val)

local runningGames = {}

socket.listen({ service="sccriblio" }, function(sock)
    local currentGame

    sock:handleDisconnect(function()
        if currentGame then
            currentGame:removePlayer(sock)

            if currentGame:isEmpty() then
                runningGames[currentGame.code] = nil
            end
        end
    end)

    local function generateCode()
        local codeLen = 4
        local tries = 0
        while true do
            local code = ""
            for _ = 1, codeLen do
                code = code .. string.char(
                    math.random(string.byte("A"), string.byte("Z"))
                )
            end

            if not runningGames[code] then
                return code
            end

            tries = tries + 1
            if tries % 5 == 0 then
                codeLen = codeLen + 1
            end
        end
    end

    sock:handle("newgame", function(res, data)
        if currentGame then
            return res.fail(apierrors.AINGAME)
        end

        local s, err = validate(data, {
            title = {vtp.String(32, 1)},
            name = {vtp.String(14, 1)},
            color = {vtp.Color(), vtp.Min(2)},
            private = {vtp.Bool()}
        })

        if not s then
            return res.fail(err)
        end

        local gameCode = generateCode()
        currentGame = ScGame.new(data.title, data.private, gameCode)
        currentGame:addPlayer(data.name, data.color, sock)

        runningGames[gameCode] = currentGame

        sock:emit("message", {
            author = {},
            content = { color = colors.lightGray,
                text = "Use the code: '" .. gameCode .. "' to invite others" }
        })
    end)

    sock:handle("joingame", function(res, data)
        if currentGame then
            return res.fail(apierrors.AINGAME)
        end

        local s, err = validate(data, {
            code = {vtp.String(nil, 1)},
            name = {vtp.String(14, 1)},
            color = {vtp.Color(), vtp.Min(2)}
        })

        if not s then
            return res.fail(err)
        end

        if runningGames[data.code] then
            currentGame = runningGames[data.code]
            currentGame:addPlayer(data.name, data.color, sock)
        else
            return res.fail(apierrors.NEXISTS)
        end
    end)

    sock:handle("guess", function(res, data)
        if not currentGame then
            res.fail(apierrors.NINGAME)
        end

        local s, err = validate(data, {
            text = {vtp.String(64, 1)},
        })

        if not s then
            return res.fail(err)
        end

        if currentGame.word then
            -- TODO:
        end

        currentGame:broadcast(sock, data.text)

        return res.succeed()
    end)

    sock:handle("games", function(res)
        local list = {}
        for code, game in pairs(runningGames) do
            if not game.private then
                table.insert(list, {
                    code = code,
                    title = game.title,
                    players = #game.players
                })
            end
        end

        res.succeed(list)
    end)
end)



-- gcm:addRoutine(sock.listen)
-- gcm:addRoutine(function()

--     local testFn = async {function(a)
--         return a + 1
--     end}

--     local prom = testFn(6)
--     print(prom)

--     local val = await { prom }
--     print(val)
--     print(prom)

-- end)
