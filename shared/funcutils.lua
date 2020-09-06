local funcutils = {}

local tableutils = require("shared.tableutils")

function funcutils.bind(fn, ...)
    local n = select("#", ...)
    local bound = {...}
    return function(...)
        local rn = select("#", ...)
        local rargs = {...}

        local args = {}
        for i = 1, n do
            args[i] = bound[i]
        end

        for i = 1, rn do
            args[i + n] = rargs[i]
        end

        return fn(tableutils.unpack(args, 1, n + rn))
    end
end

return funcutils
