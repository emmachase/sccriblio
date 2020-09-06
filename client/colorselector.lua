local ColorSelector = {}

function ColorSelector.new()
    local self = {
        selected = { colors.white, colors.lightBlue }
    }

    setmetatable(self, {__index = ColorSelector, __tostring = ColorSelector.tostring})
    return self
end

function ColorSelector:render()
    local s_width, s_height = term.getSize()
    local y = math.ceil((s_height - 16) / 2)

    for row = 1, 16 do
        term.setCursorPos(s_width, y + row)
        local color = 2^(row - 1)


        if color == self.selected[1] then
            term.setBackgroundColor(color)
            term.setTextColor(colors.lightGray)
            term.write("\149")
        elseif color == self.selected[2] then
            term.setBackgroundColor(color)
            term.setTextColor(colors.gray)
            term.write("\149")
        else
            term.setBackgroundColor(color)
            term.write(" ")
        end

        -- term.setBackgroundColor(colors.gray)
        -- term.setTextColor(color)
        -- term.write("\149")
    end
end

return ColorSelector
