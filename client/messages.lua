local MessageContainer = {}

local uuid = require("vendor.uuid")

local gcm = require("shared.gcm")
local async = require("shared.async")
local logger = require("shared.logger")
local tableutils = require("shared.tableutils")

local connection = require("client.connection")

local function sendMessage(text)
    return connection:request("guess", {text = text})
end

function MessageContainer.new(width)
    local self = {
        width = width,
        textField = {
            content = "",
            cursor  = 0,
            scrollX = 0,
        },
        pendingMessages = {},
        messages = {
            -- {author={name="Lemmmy", color=colors.cyan}, content={color=colors.gray, text="penis"}},
            -- {author={name="Lemmmy", color=colors.cyan}, content={color=colors.gray, text="abc"}},
            -- {author={name="Ema", color=colors.purple}, content={color=colors.gray, text="cat"}},
            -- {author={}, content={color=colors.lightGray, text="Game started ="}}

        }
    }

    setmetatable(self, {__index = MessageContainer, __tostring = MessageContainer.tostring})

    gcm:addRoutine(self.inputThread, self)

    connection:on("message", function(msg)
        logger.info("Message!", msg)
        table.insert(self.messages, 1, msg)
        self:render()
    end)

    return self
end

function MessageContainer:inputThread()
    while true do
        local e, key = coroutine.yield()
        if e == "char" then
            local cursor = self.textField.cursor
            local text = self.textField.content
            text = text:sub(1, cursor) .. key .. text:sub(cursor + 1)

            self.textField.content = text
            self.textField.cursor = cursor + 1

            self:renderTextField()
        elseif e == "key" then
            -- TODO: Movement
            if key == keys.enter then
                local mid = uuid()
                table.insert(self.pendingMessages, 1, {
                    id = mid,
                    author = {
                        name = "Ema",
                        color = colors.lightGray
                    },
                    content = {
                        text = self.textField.content,
                        color = colors.lightGray
                    }
                })

                sendMessage(self.textField.content)
                :next(function()
                    logger.info("is okay")
                end)
                    :catch(function(e)
                        -- TODO: Tell user some how?
                        logger.info(debug.traceback())

                        if type(e) == "table" then
                            e = e.description or e.error or e.err
                        end

                        table.insert(self.messages, 1, {
                            author={
                                name="SERVER",
                                color=colors.orange
                            },
                            content={
                                text=tostring(e),
                                color=colors.red
                            }
                        })
                    end)
                    :finally(function()
                        for i = 1, #self.pendingMessages do
                            if self.pendingMessages[i].id == mid then
                                table.remove(self.pendingMessages, i)
                                break
                            end
                        end

                        self:render()
                    end)

                self.textField.content = ""
                self.textField.cursor = 0

                self:render()
            end
        end
    end
end

function MessageContainer:render()
    local width = self.width
    local s_height = select(2, term.getSize())
    local b_x = width + 1

    -- term.setBackgroundColor(colors.lightGray)

    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.white)
    for row = 1, s_height do
        term.setCursorPos(b_x, row)
        term.write("\149")
    end

    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.lightGray)
    for row = 1, s_height do
        term.setCursorPos(b_x + 1, row)
        term.write("\149") -- Border
    end

    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.gray)
    for row = 1, s_height do
        term.setCursorPos(1, row)
        term.write((" "):rep(width))
    end

    self:printMessages(width, s_height - 3)

    self:renderTextField()
    self:placeCursor()
end

function MessageContainer:renderTextField()
    local s_height = select(2, term.getSize())

    term.setCursorPos(1, s_height - 1)
    term.setBackgroundColor(colors.lightGray)
    term.write((" "):rep(self.width))

    term.setCursorPos(1, s_height - 1)
    term.write(self.textField.content)
end

function MessageContainer:placeCursor()
    local s_height = select(2, term.getSize())
    term.setTextColor(colors.black)
    term.setCursorPos(1, s_height - 1)
    term.setCursorBlink(true)
end

function MessageContainer:printMessages(width, height)
    local message, m_i
    local allMessages = tableutils.proxycat(self.pendingMessages, self.messages)
    message, m_i = allMessages[1], 1

    while message and height >= 1 do
        -- First print the message content
        term.setTextColor(message.content.color)

        local text = message.content.text
        local lineHeight = math.ceil(#text / width)
        for i = 1, lineHeight do
            term.setCursorPos(1, height - lineHeight + i)
            term.write(text:sub(1, width))
            text = text:sub(width + 1)
        end

        height = height - lineHeight

        -- Now the author
        local nextMessage = allMessages[m_i + 1]
        if (not nextMessage) or nextMessage.author.name ~= message.author.name then
            if message.author.name then
                term.setTextColor(message.author.color or colors.black)

                term.setCursorPos(1, height)
                term.write(message.author.name or "")

                height = height - 2
            else
                height = height - 1
            end
        end

        m_i = m_i + 1
        message = allMessages[m_i]
    end
end

return MessageContainer
