return {
    SVERR = { code = -1, description = "Internal Server Error" },
    NINGAME = { code = 0, description = "You are not in a game." },
    AINGAME = { code = 1, description = "You are already in a game." },
    INVALIDREQ = { code = 2, description = "Invalid request options." },
    MISSING = function(param)
        return { code = 3, description = "Missing parameter '" .. param .. "'" }
    end,
    WTYPE = function(expected, path)
        return { code = 4, description = "Expected type '" .. expected .. "' for " .. path}
    end,
    BOUND = function(bound, path)
        return { code = 5, description = "Parameter '" .. path .. "' out of bounds, expected " .. bound }
    end,
    NEXISTS = { code = 6, description = "Requested entity does not exist" }
}
