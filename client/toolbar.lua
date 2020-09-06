local ToolBar = {}

ToolBar.Tool = {
    PENCIL = 1, ERASER = 2, FILL = 3
}

local toolIcons = {
    [ToolBar.Tool.PENCIL] = "pen",
    [ToolBar.Tool.ERASER] = "erase",
    [ToolBar.Tool.FILL] = "fill"
}

local toolColors = {
    [ToolBar.Tool.PENCIL] = colors.green,
    [ToolBar.Tool.ERASER] = colors.orange,
    [ToolBar.Tool.FILL] = colors.blue
}

function ToolBar.new(x, y)
    local self = {
        x = x, y = y,
        selected = ToolBar.Tool.PENCIL
    }

    setmetatable(self, {__index = ToolBar, __tostring = ToolBar.tostring})
    return self
end

function ToolBar:render()
    term.setCursorPos(self.x, self.y)

    for i = 1, #toolIcons do
        if self.selected == i then
            term.setBackgroundColor(toolColors[i])
            term.setTextColor(colors.white)
        else
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.lightGray)
        end
        term.write(toolIcons[i])

        local cx, cy = term.getCursorPos()
        term.setCursorPos(cx + 1, cy)
    end
end

return ToolBar
