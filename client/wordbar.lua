local WordBar = {}

function WordBar.new(width)
    local self = {
        width = width,
        text = "______a_",
        time = 34
    }

    setmetatable(self, {__index = WordBar, __tostring = WordBar.tostring})
    return self
end

function WordBar:render()
    local s_width = term.getSize()
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)

    term.setCursorPos(s_width - self.width + 1, 1)
    term.write((" "):rep(self.width))

    local middle = math.floor((self.width + #self.text)/2)
    term.setCursorPos(s_width - middle, 1)
    term.write(self.text)

    self:renderTime()
end

function WordBar:renderTime()
    local s_width = term.getSize()

    term.setBackgroundColor(colors.gray)
    if self.time <= 10 then
        term.setTextColor(colors.red)
    else
        term.setTextColor(colors.white)
    end

    term.setCursorPos(s_width - self.width + 2, 1)
    term.write(tostring(self.time) .. "s")
end

return WordBar
