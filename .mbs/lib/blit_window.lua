local colour_lookup = {}
for i = 0, 16 do
  colour_lookup[2 ^ i] = string.format("%x", i)
end

function create(original)
  if not original then original = term.current() end

  local text = {}
  local text_colour = {}
  local back_colour = {}
  local palette = {}

  local cursor_x, cursor_y = 1, 1

  local cursor_blink = false
  local cur_text_colour = "0"
  local cur_back_colour = "f"

  local sizeX, sizeY = original.getSize()
  local color = original.isColor()

  local bubble = true

  local redirect = {}

  if original.getPaletteColour then
    for i = 0, 15 do
      local c = 2 ^ i
      palette[c] = { original.getPaletteColour(c) }
    end
  end

  function redirect.write(writeText)
    writeText = tostring(writeText)
    if bubble then original.write(writeText) end

    local pos = cursor_x

    -- If we're off the screen then just emulate a write
    if cursor_y > sizeY or cursor_y < 1 then
      cursor_x = pos + #writeText
      return
    end

    if pos + #writeText <= 1 or pos > sizeX then
      -- If we're too far off the left then skip.
      cursor_x = pos + #writeText
      return
    elseif pos < 1 then
      -- Adjust text to fit on screen starting at one.
      writeText = string.sub(writeText, math.abs(cursor_x) + 2)
      pos = 1
    end

    local lineText = text[cursor_y]
    local lineColor = text_colour[cursor_y]
    local lineBack = back_colour[cursor_y]
    local preStop = pos - 1
    local preStart = math.min(1, preStop)
    local postStart = pos + #writeText
    local postStop = sizeX
    local sub, rep = string.sub, string.rep

    text[cursor_y] = sub(lineText, preStart, preStop) .. writeText .. sub(lineText, postStart, postStop)
    text_colour[cursor_y] = sub(lineColor, preStart, preStop) .. rep(cur_text_colour, #writeText) .. sub(lineColor, postStart, postStop)
    back_colour[cursor_y] = sub(lineBack, preStart, preStop) .. rep(cur_back_colour, #writeText) .. sub(lineBack, postStart, postStop)
    cursor_x = pos + #writeText
  end

  function redirect.blit(writeText, writeFore, writeBack)
    if type(writeText) ~= "string" then error("bad argument #1 (expected string, got " .. type(writeText) .. ")", 2) end
    if type(writeFore) ~= "string" then error("bad argument #2 (expected string, got " .. type(writeFore) .. ")", 2) end
    if type(writeBack) ~= "string" then error("bad argument #3 (expected string, got " .. type(writeBack) .. ")", 2) end
    if #writeFore ~= #writeText or #writeBack ~= #writeText then error("Arguments must be the same length", 2) end

    if bubble then original.blit(writeText, writeFore, writeBack) end
    local pos = cursor_x

    -- If we're off the screen then just emulate a write
    if cursor_y > sizeY or cursor_y < 1 then
      cursor_x = pos + #writeText
      return
    end

    if pos + #writeText <= 1 then
      --skip entirely.
      cursor_x = pos + #writeText
      return
    elseif pos < 1 then
      --adjust text to fit on screen starting at one.
      writeText = string.sub(writeText, math.abs(cursor_x) + 2)
      writeFore = string.sub(writeFore, math.abs(cursor_x) + 2)
      writeBack = string.sub(writeBack, math.abs(cursor_x) + 2)
      cursor_x = 1
    elseif pos > sizeX then
      --if we're off the edge to the right, skip entirely.
      cursor_x = pos + #writeText
      return
    end

    local lineText = text[cursor_y]
    local lineColor = text_colour[cursor_y]
    local lineBack = back_colour[cursor_y]
    local preStop = cursor_x - 1
    local preStart = math.min(1, preStop)
    local postStart = cursor_x + #writeText
    local postStop = sizeX
    local sub = string.sub

    text[cursor_y] = sub(lineText, preStart, preStop) .. writeText .. sub(lineText, postStart, postStop)
    text_colour[cursor_y] = sub(lineColor, preStart, preStop) .. writeFore .. sub(lineColor, postStart, postStop)
    back_colour[cursor_y] = sub(lineBack, preStart, preStop) .. writeBack .. sub(lineBack, postStart, postStop)
    cursor_x = pos + #writeText
  end

  function redirect.clear()
    for i = 1, sizeY do
      text[i] = string.rep(" ", sizeX)
      text_colour[i] = string.rep(cur_text_colour, sizeX)
      back_colour[i] = string.rep(cur_back_colour, sizeX)
    end

    if bubble then return original.clear() end
  end

  function redirect.clearLine()
    -- If we're off the screen then just emulate a clearLine
    if cursor_y > sizeY or cursor_y < 1 then
      return
    end

    text[cursor_y] = string.rep(" ", sizeX)
    text_colour[cursor_y] = string.rep(cur_text_colour, sizeX)
    back_colour[cursor_y] = string.rep(cur_back_colour, sizeX)

    if bubble then return original.clearLine() end
  end

  function redirect.getCursorPos()
    return cursor_x, cursor_y
  end

  function redirect.setCursorPos(x, y)
    if type(x) ~= "number" then error("bad argument #1 (expected number, got " .. type(x) .. ")", 2) end
    if type(y) ~= "number" then error("bad argument #2 (expected number, got " .. type(y) .. ")", 2) end

    cursor_x = math.floor(x)
    cursor_y = math.floor(y)
    if bubble then return original.setCursorPos(x, y) end
  end

  function redirect.setCursorBlink(b)
    cursor_blink = b
    if bubble then return original.setCursorBlink(b) end
  end

  function redirect.getSize()
    return sizeX, sizeY
  end

  function redirect.scroll(n)
    if type(n) ~= "number" then error("bad argument #1 (expected number, got " .. type(n) .. ")", 2) end

    local empty_text = string.rep(" ", sizeX)
    local empty_text_colour = string.rep(cur_text_colour, sizeX)
    local empty_back_colour = string.rep(cur_back_colour, sizeX)
    if n > 0 then
      for i = 1, sizeY do
        text[i] = text[i + n] or empty_text
        text_colour[i] = text_colour[i + n] or empty_text_colour
        back_colour[i] = back_colour[i + n] or empty_back_colour
      end
    elseif n < 0 then
      for i = sizeY, 1, -1 do
        text[i] = text[i + n] or empty_text
        text_colour[i] = text_colour[i + n] or empty_text_colour
        back_colour[i] = back_colour[i + n] or empty_back_colour
      end
    end

    if bubble then return original.scroll(n) end
  end

  function redirect.setTextColour(clr)
    if type(clr) ~= "number" then error("bad argument #1 (expected number, got " .. type(clr) .. ")", 2) end
    cur_text_colour = colour_lookup[clr] or error("Invalid colour (got " .. clr .. ")" , 2)
    if bubble then return original.setTextColour(clr) end
  end
  redirect.setTextColor = redirect.setTextColour

  function redirect.setBackgroundColour(clr)
    if type(clr) ~= "number" then error("bad argument #1 (expected number, got " .. type(clr) .. ")", 2) end
    cur_back_colour = colour_lookup[clr] or error("Invalid colour (got " .. clr .. ")" , 2)
    if bubble then return original.setBackgroundColour(clr) end
  end
  redirect.setBackgroundColor = redirect.setBackgroundColour

  function redirect.isColour()
    return color == true
  end
  redirect.isColor = redirect.isColour

  function redirect.getTextColour()
    return 2 ^ tonumber(cur_text_colour, 16)
  end
  redirect.getTextColor = redirect.getTextColour

  function redirect.getBackgroundColour()
    return 2 ^ tonumber(cur_back_colour, 16)
  end
  redirect.getBackgroundColor = redirect.getBackgroundColour

  if original.getPaletteColour then
    function redirect.setPaletteColour(colour, r, g, b)
      local palcol = palette[colour]
      if not palcol then error("Invalid colour (got " .. tostring(colour) .. ")", 2) end
      if type(r) == "number" and g == nil and b == nil then
          palcol[1], palcol[2], palcol[3] = colours.rgb8(r)
      else
          if type(r) ~= "number" then error("bad argument #2 (expected number, got " .. type(r) .. ")", 2) end
          if type(g) ~= "number" then error("bad argument #3 (expected number, got " .. type(g) .. ")", 2) end
          if type(b) ~= "number" then error("bad argument #4 (expected number, got " .. type(b) .. ")", 2) end

          palcol[1], palcol[2], palcol[3] = r, g, b
      end

      if bubble then return original.setPaletteColour(colour, r, g, b) end
    end
    redirect.setPaletteColor = redirect.setPaletteColour

    function redirect.getPaletteColour(colour)
      local palcol = palette[colour]
      if not palcol then error("Invalid colour (got " .. tostring(colour) .. ")", 2) end
      return palcol[1], palcol[2], palcol[3]
    end
    redirect.getPaletteColor = redirect.getPaletteColour
  end

  function redirect.draw(target)
    if not target then target = original end

    if target.getPaletteColour then
      for colour, pal in pairs(palette) do
        target.setPaletteColour(colour, pal[1], pal[2], pal[3])
      end
    end

    for i = 1, sizeY do
      target.setCursorPos(1, i)
      target.blit(text[i], text_colour[i], back_colour[i])
    end

    target.setCursorPos(cursor_x, cursor_y)
    target.setTextColour(2 ^ tonumber(cur_text_colour, 16))
    target.setBackgroundColor(2 ^ tonumber(cur_back_colour, 16))
    target.setCursorBlink(cursor_blink)
  end

  function redirect.bubble(b)
    bubble = b
  end

  function redirect.updateSize()
    local new_x, new_y = original.getSize()
    if new_x == sizeX and new_y == sizeY then return end

    -- For any existing lines, trim them
    for y = 1, sizeY do
      if new_x < sizeX then
        text[y] = text[y]:sub(1, new_x)
        text_colour[y] = text_colour[y]:sub(1, new_x)
        back_colour[y] = back_colour[y]:sub(1, new_x)
      elseif new_x > sizeX then
        text[y] = text[y] .. (" "):rep(new_x - sizeX)
        text_colour[y] = text_colour[y] .. cur_text_colour:rep(new_x - sizeX)
        back_colour[y] = back_colour[y] .. cur_back_colour:rep(new_x - sizeX)
      end
    end

    -- Add any new lines we might need.
    local text_line = (" "):rep(new_x)
    local fore_line = cur_text_colour:rep(new_x)
    local back_line = cur_back_colour:rep(new_x)
    for y = sizeY + 1, new_y do
      text[y] = text_line
      text_colour[y] = fore_line
      back_colour[y] = back_line
    end

    sizeX = new_x
    sizeY = new_y
  end

  redirect.clear()
  return redirect
end