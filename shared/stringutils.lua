local stringutils = {}

function stringutils.explode(pattern, text)
    local result = {}
    while #text > 0 do
        local nextInst, endInst = text:find(pattern)
        if nextInst then
            table.insert(result, text:sub(1, nextInst - 1))
            table.insert(result, text:sub(nextInst, endInst))
            text = text:sub(endInst + 1)
        else
            table.insert(result, text)
            break
        end
    end

    return result
end

function stringutils.split(pattern, text)
    local result = {}
    while #text > 0 do
        local nextInst, endInst = text:find(pattern)
        if nextInst then
            table.insert(result, text:sub(1, nextInst - 1))
            text = text:sub(endInst + 1)
        else
            table.insert(result, text)
            break
        end
    end

    return result
end

return stringutils
