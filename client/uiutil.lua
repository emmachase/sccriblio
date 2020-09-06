local uiutil = {}

function uiutil.centerWrite(y, text)
    local width = term.getSize()
    local maxSize = 0
    for line in text:gmatch("[^\n]+") do
        maxSize = math.max(maxSize, #line)
    end

    local x = math.ceil((width - maxSize)/2)
    for line in text:gmatch("[^\n]+") do
        term.setCursorPos(x, y)
        term.write(line)

        y = y + 1
    end
end

return uiutil
