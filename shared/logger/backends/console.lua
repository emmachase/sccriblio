local console = {}

local stringutils = require("shared.stringutils")
local tableutils = require("shared.tableutils")
local pretty = require("shared.pretty")

function console.new()
    local self = {}
    return setmetatable(self, {__index = console})
end

local function setBG(c)
    if term.isColor() then
        term.setBackgroundColor(c)
    end
end

local function setFG(c)
    if term.isColor() then
        term.setTextColor(c)
    end
end

local function cprintf(fmt, ...)
    local instructions = stringutils.explode("%%.", fmt)
    local values = {...}
    for _, instr in ipairs(instructions) do
        if instr:match("^%%.$") then
            local w = instr:sub(2)
            if w == "B" then
                setBG(table.remove(values, 1))
            elseif w == "C" then
                setFG(table.remove(values, 1))
            elseif w == "R" then
                setBG(colors.black)
                setFG(colors.white)
            elseif w == "s" then
                local val = table.remove(values, 1)
                if type(val) == "string" then
                    write(val)
                else
                    pretty.write(val)
                end
            elseif w == "v" then
                local tab = table.remove(values, 1)
                local n = #tab
                for i = 1, n do
                    local val = tab[i]
                    if type(val) == "string" then
                        write(val)
                    else
                        pretty.write(val)
                    end

                    if i ~= n then
                        write(" ")
                    end
                end
            end
        else
            -- local this = {}
            -- for p in instr:gmatch("%%.") do
            --     if p ~= "%%" then
            --         table.insert(this, table.remove(values, 1))
            --     end
            -- end

            write(instr)--:format(tableutils.unpack(this)))
        end
    end
    print()
end

function console:generic(level, text)
    cprintf("%C[%s] %R%v", colors.lightGray, level:upper(), text)
end

function console:trace(text)
    cprintf("%C[TRACE] %R%C%v", colors.gray, colors.lightGray, text)
end

function console:debug(text)
    cprintf("%C[DEBUG] %R%v", colors.purple, text)
end

function console:info(text)
    cprintf("%C[INFO] %R%v", colors.cyan, text)
end

function console:warn(text)
    cprintf("%C[WARN] %R%v", colors.yellow, text)
end

function console:error(text)
    cprintf("%C[ERROR] %R%v", colors.red, text)
end

function console:fatal(text)
    cprintf("%B%C[FATAL]%R %C%v\n", colors.red, colors.white, colors.red, text)
end


return console
