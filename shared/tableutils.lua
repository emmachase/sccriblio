local tableutils = {}

local function ultraShittyUnpack(t, i, n)
    if (n and i == n + 1) or not (n or t[i]) then return end
    return t[i], ultraShittyUnpack(t, i + 1)
end

function tableutils.unpack(tab, s, n)
    if table.unpack then
        return table.unpack(tab, s, n)
    elseif _G["unpack"] then
        return _G["unpack"](tab, s, n)
    else
        return ultraShittyUnpack(tab, s or 1, n)
    end
end

--- Packs the last `# - count` elements of the varargs, leaving the first `count` intact
--- Example: prepack(2, "a", "b", "c", "d", "e") = ("a", "b", {"c", "d", "e"})
function tableutils.postpack(count, ...)
    local prehand = {}
    local posthand = {}

    local values = {...}
    for i = 1, select("#", ...) do
        if count > 0 then
            table.insert(prehand, values[i])
            count = count - 1
        else
            table.insert(posthand, values[i])
        end
    end

    table.insert(prehand, posthand)
    return tableutils.unpack(prehand)
end

-- Produces a metatable which indexes as if the given tables were concatenated.
function tableutils.proxycat(...)
    local tabs = {...}
    local index = {}
    local i = 0
    for t = 1, #tabs do
        for j = 1, #tabs[t] do
            i = i + 1
            index[i] = {tabs[t], j}
        end
    end

    local function search(k)
        for t = 1, #tabs do
            if tabs[t][k] then
                return tabs[t][k]
            end
        end
    end

    return setmetatable({}, {
        __index = function(_, k)
            if index[k] then
                return index[k][1][index[k][2]]
            else
                return search(k)
            end
        end
    })
end

return tableutils
