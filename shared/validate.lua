local validate = {}

local apierrors = require("shared.apierrors")

local function pchk(d, t)
    if type(d) ~= t then
        error({prim = t})
    end
end

validate.types = {
    Color = function()
        return function(d, key)
            pchk(d, "number")

            local cval = 1 + (math.log(d) / math.log(2))
            return (cval >= 1 and cval <= 16), apierrors.WTYPE("COLOR", key)
        end
    end,

    String = function(max, min)
        return function(d, key)
            pchk(d, "string")

            local len = #d
            if max and len > max then
                return false, apierrors.BOUND("# <= " .. max, key)
            end

            if min and len < min then
                return false, apierrors.BOUND("# >= " .. min, key)
            end

            return true
        end
    end,

    Bool = function()
        return function(d)
            pchk(d, "boolean")
            return true
        end
    end,

    Min = function(minval)
        return function(d, key)
            pchk(d, "number")
            return d >= minval, apierrors.BOUND(">= " .. minval, key)
        end
    end,

    Max = function(maxval)
        return function(d, key)
            pchk(d, "number")
            return d <= maxval, apierrors.BOUND("<= " .. maxval, key)
        end
    end,

    Tab = function(spec)
        return function(d, key)
            return validate:exec(d, spec, key .. ".")
        end
    end
}

function validate:exec(data, spec, path)
    path = path or ""

    if type(data) ~= "table" then
        return false, apierrors.INVALIDREQ
    end

    for key, validators in pairs(spec) do
        if data[key] == nil then
            return false, apierrors.MISSING(key)
        end

        local kpath = path .. key

        local datum = data[key]
        for _, validator in ipairs(validators) do
            local s, ev, err = pcall(validator, datum, kpath)
            if s then
                if not ev then
                    return false, err or apierrors.INVALIDREQ
                end
            else
                if type(ev) == "table" and ev.prim then
                    return false, apierrors.WTYPE(ev.prim, kpath)
                else
                    return false, apierrors.SVERR
                end
            end
        end
    end

    return true
end

setmetatable(validate, { __call = validate.exec })

return validate
