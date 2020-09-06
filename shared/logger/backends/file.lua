local file = {}

local serpent = require("vendor.serpent")

function file.new(filename)
    local self = {
        handle = fs.open(filename, "a")
    }

    return setmetatable(self, {__index = file})
end

function file:generic(level, text)
    local str = ("[%s] [%s]"):format(tostring(os.epoch("utc")), level:upper())
    for i = 1, #text do
        str = str .. " "
        local val = text[i]
        if type(val) == "string" then
            str = str .. val
        elseif (getmetatable(val) or {}).__tostring then
            str = str .. tostring(val)
        else
            str = str .. serpent.block(val)
        end
    end

    self.handle.write(str .. "\n")
    self.handle.flush()
end

function file:destroy()
    self.handle.close()
end

return file
