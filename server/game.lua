local Game = {}

local logger = require("shared.logger")

function Game.new(title, private, code)
    local self = {
        title = title,
        private = private,
        code = code,
        players = {}
    }

    setmetatable(self, {__index = Game, __tostring = Game.tostring})
    return self
end

function Game:addPlayer(name, color, sock)
    table.insert(self.players, {
        name = name,
        color = color,
        sock = sock
    })

    self:broadcast(nil, "+" .. name .. " joined")
end

function Game:removePlayer(sock)
    for i = 1, #self.players do
        if self.players[i].sock.uuid == sock.uuid then
            table.remove(self.players, i)
            self:broadcast(nil, "-" .. self.players[i].name .. " left")
            return
        end
    end

    logger.warn("removePlayer was called with a player that wasn't in the game: ", sock.uuid)
end

function Game:isEmpty()
    return #self.players == 0
end

function Game:broadcast(originSock, text)
    local player
    if originSock then
        for i = 1, #self.players do
            if self.players[i].sock.uuid == originSock.uuid then
                player = self.players[i]
                break
            end
        end
    end

    local textColor = colors.gray
    if not player then
        player = {}
        textColor = colors.lightGray
    end

    for i = 1, #self.players do
        self.players[i].sock:emit("message", {
            author = { name = player.name, color = player.color },
            content = { color = textColor, text = text }
        })
    end
end

return Game
