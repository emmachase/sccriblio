local pretty = {}

local syntaxTheme = {
    keyword = colors.purple,
    specialKeyword = colors.lightBlue,
    func = colors.cyan,
    string = colors.red,
    stringEscape = colors.yellow,
    primitive = colors.orange,
    comment = colors.lightGray,
    cref = colors.lightGray,
    catch = colors.white
}

local keywords = {
  [ "and" ] = true, [ "break" ] = true, [ "do" ] = true, [ "else" ] = true,
  [ "elseif" ] = true, [ "end" ] = true, [ "false" ] = true, [ "for" ] = true,
  [ "function" ] = true, [ "if" ] = true, [ "in" ] = true, [ "local" ] = true,
  [ "nil" ] = true, [ "not" ] = true, [ "or" ] = true, [ "repeat" ] = true, [ "return" ] = true,
  [ "then" ] = true, [ "true" ] = true, [ "until" ] = true, [ "while" ] = true,
}

local curColor
local function pwrite(text, color)
    if color ~= curColor then
        term.setTextColor(color)
        curColor = color
    end

    write(text)
end

local function prettySort(a, b)
    local ta, tb = type(a), type(b)

    if ta == "string" then return tb ~= "string" or a < b
    elseif tb == "string" then return false end

    if ta == "number" then return tb ~= "number" or a < b end

    return false
end

local debugInfo = (type(debug) == "table" and type(debug.getinfo) == "function" and debug.getinfo)

local function getFunctionArgs(func)
if debugInfo then
local args = {}
local hook = debug.gethook()

local argHook = function()
    local info = debugInfo(3)
    if info.name ~= "pcall" then return end

    for i = 1, math.huge do
        local name = debug.getlocal(2, i)

        if name == "(*temporary)" or not name then
            debug.sethook(hook)
            return error()
        end

        args[#args + 1] = name
    end
end

debug.sethook(argHook, "c")
pcall(func)

return args
end
end

local function prettyFunction(fn)
if debugInfo then
local info = debugInfo(fn, "S")
if info.short_src and info.linedefined and info.linedefined >= 1 then
    local args
    if info.what == "Lua" then
        args = getFunctionArgs(fn)
    end

    if args then
        return "function<" .. info.short_src .. ":" .. info.linedefined .. ">(" .. table.concat(args, ", ") .. ")"
        else
            return "function<" .. info.short_src .. ":" .. info.linedefined .. ">"
            end
        end
    end

    return tostring(fn)
end

local function prettySize(obj, tracking, limit)
    local objType = type(obj)
    if objType == "string" then return #string.format("%q", obj):gsub("\\\n", "\\n")
    elseif objType == "function" then return #prettyFunction(obj)
    elseif objType ~= "table" or tracking[obj] then return #tostring(obj) end

    local count = 2
    tracking[obj] = true
    for k, v in pairs(obj) do
        count = count + prettySize(k, tracking, limit) + prettySize(v, tracking, limit)
        if count >= limit then break end
    end
    tracking[obj] = nil
    return count
end

local function prettyImpl(obj, tracking, width, height, indent, tupleLength)
    local objType = type(obj)
    if objType == "string" then
        local formatted = string.format("%q", obj):gsub("\\\n", "\\n")

        local limit = math.max(8, math.floor(width * height * 0.8))

        if #formatted > limit then
            pwrite(formatted:sub(1, limit-3), syntaxTheme.string)
            pwrite("...", syntaxTheme.string)
        else
            pwrite(formatted, syntaxTheme.string)
        end

        return
    elseif objType == "number" then
        return pwrite(tostring(obj), syntaxTheme.primitive)
    elseif objType == "boolean" then
        return pwrite(tostring(obj), syntaxTheme.primitive)
    elseif objType == "function" then
        return pwrite(prettyFunction(obj), syntaxTheme.func)
    elseif objType ~= "table" or tracking[obj] then
        return pwrite(tostring(obj), syntaxTheme.cref)
    elseif (getmetatable(obj) or {}).__tostring then
        return pwrite(tostring(obj), syntaxTheme.catch)
    end

    local open, close = "{", "}"
    if tupleLength then open, close = "(", ")" end

    if (tupleLength == nil or tupleLength == 0) and next(obj) == nil then
        return pwrite(open .. close, syntaxTheme.catch)
    elseif width <= 7 then
        pwrite(open, syntaxTheme.catch)
        pwrite(" ... ", syntaxTheme.cref)
        pwrite(close, syntaxTheme.catch)
        return
    end

    local shouldNewline = false
    local length = tupleLength or #obj

    local size, children, keys, kn = 2, 0, {}, 0
    for k, v in pairs(obj) do
        if type(k) == "number" and k >= 1 and k <= length and k % 1 == 0 then
            local vs = prettySize(v, tracking, width)
            size = size + vs + 2
            children = children + 1
        else
            kn = kn + 1
            keys[kn] = k

            local vs, ks = prettySize(v, tracking, width), prettySize(k, tracking, width)
            size = size + vs + ks + 2
            children = children + 2
        end

        if size >= width * 0.6 then shouldNewline = true end
    end

    if shouldNewline and height <= 1 then
        pwrite(open, syntaxTheme.catch)
        pwrite(" ... ", syntaxTheme.cref)
        pwrite(close, syntaxTheme.catch)
        return
    end

    table.sort(keys, prettySort)

    local nextNewline, subIndent, childWidth, childHeight
    if shouldNewline then
        nextNewline, subIndent = ",\n", indent .. " "

        height = height - 2
        childWidth, childHeight = width - 2, math.ceil(height / children)

        if children > height then children = height - 2 end
    else
        nextNewline, subIndent = ", ", ""

        width = width - 2
        childWidth, childHeight = math.ceil(width / children), 1
    end

    pwrite(open .. (shouldNewline and "\n" or " "), syntaxTheme.catch)

    tracking[obj] = true
    local seen = {}
    local first = true
    for k = 1, length do
        if not first then pwrite(nextNewline, syntaxTheme.catch) else first = false end
        pwrite(subIndent, syntaxTheme.catch)

        seen[k] = true
        prettyImpl(obj[k], tracking, childWidth, childHeight, subIndent)

        children = children - 1
        if children < 0 then
            if not first then pwrite(nextNewline, syntaxTheme.catch) else first = false end
            pwrite(subIndent .. "...", syntaxTheme.cref)
            break
        end
    end

    for i = 1, kn do
        local k, v = keys[i], obj[keys[i]]
        if not seen[k] then
            if not first then pwrite(nextNewline, syntaxTheme.catch) else first = false end
            pwrite(subIndent, syntaxTheme.catch)

            if type(k) == "string" and not keywords[k] and k:match("^[%a_][%a%d_]*$") then
                pwrite(k .. " = ", syntaxTheme.catch)
                prettyImpl(v, tracking, childWidth, childHeight, subIndent)
            else
                pwrite("[", syntaxTheme.catch)
                prettyImpl(k, tracking, childWidth, childHeight, subIndent)
                pwrite("] = ", syntaxTheme.catch)
                prettyImpl(v, tracking, childWidth, childHeight, subIndent)
            end

            children = children - 1
            if children < 0 then
                if not first then pwrite(nextNewline, syntaxTheme.catch) end
                pwrite(subIndent .. "...", syntaxTheme.cref)
                break
            end
        end
    end
    tracking[obj] = nil

    pwrite((shouldNewline and "\n" .. indent or " ") .. (tupleLength and ")" or "}"), syntaxTheme.catch)
end

local function prettyp(t, n)
    local width, height = term.getSize()
    prettyImpl(t, {}, width, height - 2, "", n)
end

function pretty.write(...)
    local n = select("#", ...)
    if n > 1 then
        prettyp({...}, n)
    else
        local value = (...)
        prettyp(value)
    end
end

function pretty.print(...)
    pretty.write(...)
    print()
end

return pretty
