local canvas = {}

local function colorToHex(color)
    return ("%X"):format(math.log(color)/math.log(2))
end

function canvas.new(x, y, width, height)
    local self = {}
    setmetatable(self, { __index = canvas })

    self:reframe(x, y, width, height)

    return self
end

function canvas:reframe(x, y, width, height)
    self.x, self.y = x, y
    self.width, self.height = width, height
    self.origin_x = x + math.floor(width/2)
    self.origin_y = y + math.floor(height/2)

    self.instance = {
        bg = {},
        fg = {},
        tx = {}
    }
    for row = 1, height do
        self.instance.bg[row] = {}
        self.instance.fg[row] = {}
        self.instance.tx[row] = {}
        for col = 1, width do
            self.instance.bg[row][col] = colorToHex(colors.gray)
            self.instance.fg[row][col] = colorToHex(colors.black)
            self.instance.tx[row][col] = "\127"
        end
    end
end

function canvas:canvasToInternal(x, y)
    return
        x + math.floor(self.width/2) + 1,
        y + math.floor(self.height/2) + 1
end

function canvas:scrnToCanvas(x, y)
    return x - self.origin_x, y - self.origin_y
end

function canvas:render()
    for row = 1, self.height do
        local bg = table.concat(self.instance.bg[row], "")
        local fg = table.concat(self.instance.fg[row], "")
        local tx = table.concat(self.instance.tx[row], "")
        term.setCursorPos(self.x, self.y + row - 1)
        term.blit(tx, fg, bg)
    end
end

return canvas
