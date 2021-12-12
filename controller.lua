enum = require("enum")
require "helpers"

Button = enum.new("Buttons", {
  "UP",
  "DOWN",
  "LEFT",
  "RIGHT",
  "A",
  "B",
  "SELECT",
  "START",
})

A      = "A"
B      = "B"
START  = "start"
SELECT = "select"
UP     = "up"
DOWN   = "down"
LEFT   = "left"
RIGHT  = "right"

-- Converts a Button to the actual String value needed by fceux engine
-- @button :: Button
-- @returns :: String
function convertButton(button)
  if     button == Button.UP     then return UP
  elseif button == Button.DOWN   then return DOWN
  elseif button == Button.LEFT   then return LEFT
  elseif button == Button.RIGHT  then return RIGHT
  elseif button == Button.A      then return A
  elseif button == Button.B      then return B
  elseif button == Button.SELECT then return SELECT
  elseif button == Button.START  then return START
  else log.err("Argument was not a button!", tostring(button))
  end
end

emptyInputs = {
  [START] = nil,
  [A]     = nil,
  [B]     = nil,
  [UP]    = nil,
  [DOWN]  = nil,
  [LEFT]  = nil,
  [RIGHT] = nil,
}

function waitFrames (n)
  for i = 1,n do emu.frameadvance() end
end

-- waits either maxFrames, or until f yields true
function waitUntil (f, maxFrames, msg)
  -- log.debug("Waiting until: " .. msg .. " for up to " .. maxFrames .. " frames.")
  local nrFramesWaited = 0
  for i = 1,maxFrames do
    if f() then
      -- log.debug("Waited until: " .. msg .. " waited exactly " .. nrFramesWaited .. " frames, and condition is: " .. tostring(f()))
      return
    end
    emu.frameadvance()
    nrFramesWaited = nrFramesWaited + 1
  end
  -- log.debug("Waited until: " .. msg .. " waited exactly " .. nrFramesWaited .. " frames, and condition is: " .. tostring(f()))
end

function clearController()
  joypad.write(1, emptyInputs)
end

function pressButton (button, wait)
  -- log.debug("Pressing " .. tostring(button) .. " and waiting .. " .. tostring(wait))
  e = table.shallow_copy(emptyInputs)
  e[convertButton(button)] = true
  joypad.write(1, e)
  waitFrames(wait)
  clearController()
  waitFrames(1)
end

function holdButton (button, frames)
  local nrFrames = 0
  holdButtonUntil(button, "frame count is: " .. frames, function()
    nrFrames = nrFrames + 1
    return nrFrames >= frames
  end)
end

function holdButtonUntil(button, msg, conditionFunction)
  -- log.debug("Holding " .. tostring(button) .. " until " .. msg)
  e = table.shallow_copy(emptyInputs)
  e[convertButton(button)] = true
  while not conditionFunction() do
    joypad.write(1, e)
    emu.frameadvance()
  end
  -- log.debug("Done holding " .. tostring(button) .. " until " .. msg)
  clearController()
  emu.frameadvance()
end

function holdButtonUntilOrMaxFrames(button, msg, conditionFunction, maxFrames)
  if maxFrames == nil then return holdButtonUntil(button, msg, conditionFunction)
  else
    local nrFrames = 0
    holdButtonUntil(button, msg .. " or frame count is: " .. maxFrames, function()
      nrFrames = nrFrames + 1
      return (nrFrames >= maxFrames) or conditionFunction()
    end)
  end
end

function pressStart (wait) pressButton(Button.START, wait) end
function pressSelect (wait) pressButton(Button.SELECT, wait) end
function pressA (wait) pressButton(Button.A, wait) end
function pressB (wait) pressButton(Button.B, wait) end
function pressLeft (wait) pressButton(Button.LEFT, wait) end
function pressRight (wait) pressButton(Button.RIGHT, wait) end
function pressUp (wait) pressButton(Button.UP, wait) end
function pressDown (wait) pressButton(Button.DOWN, wait) end

function holdStart (frames) holdButton(Button.START, frames) end
function holdStartUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(Button.START, msg, f, maxFrames) end
function holdSelect (frames) holdButton(Button.SELECT, frames) end
function holdSelectUntil (f, maxFrames) holdButtonUntilOrMaxFrames(Button.SELECT, msg, f, maxFrames) end
function holdA (frames) holdButton(Button.A, frames) end
function holdAUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(Button.A, msg, f, maxFrames) end
function holdB (frames) holdButton(Button.B, frames) end
function holdBUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(Button.B, msg, f, maxFrames) end
function holdLeft (frames) holdButton(Button.LEFT, frames) end
function holdLeftUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(Button.LEFT, msg, f, maxFrames) end
function holdRight (frames) holdButton(Button.RIGHT, frames) end
function holdRightUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(Button.RIGHT, msg, f, maxFrames) end
function holdUp (frames) holdButton(Button.UP, frames) end
function holdUpUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(Button.UP, msg, f, maxFrames) end
function holdDown (frames) holdButton(Button.DOWN, frames) end
function holdDownUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(Button.DOWN, msg, f, maxFrames) end
