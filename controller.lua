enum = require("enum")
require "helpers"

Button = enum.new("Button", {
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

controller = {}

function controller.waitFrames (n)
  for _ = 1,n do emu.frameadvance() end
end

-- waits either maxFrames, or until f yields true
function controller.waitUntil (f, maxFrames, msg)
  -- log.debug("Waiting until: " .. msg .. " for up to " .. maxFrames .. " frames.")
  local nrFramesWaited = 0
  for _ = 1,maxFrames do
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

function controller.pressButton (button, wait)
  -- log.debug("Pressing " .. tostring(button) .. " and waiting .. " .. tostring(wait))
  e = table.shallow_copy(emptyInputs)
  e[convertButton(button)] = true
  joypad.write(1, e)
  controller.waitFrames(wait)
  clearController()
  controller.waitFrames(1)
end

function controller.holdButton (button, frames)
  local nrFrames = 0
  controller.holdButtonUntil(button, "frame count is: " .. frames, function()
    nrFrames = nrFrames + 1
    return nrFrames >= frames
  end)
end

function controller.holdButtonUntil(button, msg, conditionFunction)
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

function controller.holdButtonUntilOrMaxFrames(button, msg, conditionFunction, maxFrames)
  if maxFrames == nil then return controller.holdButtonUntil(button, msg, conditionFunction)
  else
    local nrFrames = 0
    controller.holdButtonUntil(button, msg .. " or frame count is: " .. maxFrames, function()
      nrFrames = nrFrames + 1
      return (nrFrames >= maxFrames) or conditionFunction()
    end)
  end
end

function controller.pressStart (wait) controller.pressButton(Button.START, wait) end
function controller.pressSelect (wait) controller.pressButton(Button.SELECT, wait) end
function controller.pressA (wait) controller.pressButton(Button.A, wait) end
function controller.pressB (wait) controller.pressButton(Button.B, wait) end
function controller.pressLeft (wait) controller.pressButton(Button.LEFT, wait) end
function controller.pressRight (wait) controller.pressButton(Button.RIGHT, wait) end
function controller.pressUp (wait) controller.pressButton(Button.UP, wait) end
function controller.pressDown (wait) controller.pressButton(Button.DOWN, wait) end

function controller.holdStart (frames) controller.holdButton(Button.START, frames) end
function controller.holdStartUntil (f, msg, maxFrames) controller.holdButtonUntilOrMaxFrames(Button.START, msg, f, maxFrames) end
function controller.holdSelect (frames) controller.holdButton(Button.SELECT, frames) end
function controller.holdSelectUntil (f, maxFrames) controller.holdButtonUntilOrMaxFrames(Button.SELECT, msg, f, maxFrames) end
function controller.holdA (frames) controller.holdButton(Button.A, frames) end
function controller.holdAUntil (f, msg, maxFrames) controller.holdButtonUntilOrMaxFrames(Button.A, msg, f, maxFrames) end
function controller.holdB (frames) controller.holdButton(Button.B, frames) end
function controller.holdBUntil (f, msg, maxFrames) controller.holdButtonUntilOrMaxFrames(Button.B, msg, f, maxFrames) end
function controller.holdLeft (frames) controller.holdButton(Button.LEFT, frames) end
function controller.holdLeftUntil (f, msg, maxFrames) controller.holdButtonUntilOrMaxFrames(Button.LEFT, msg, f, maxFrames) end
function controller.holdRight (frames) controller.holdButton(Button.RIGHT, frames) end
function controller.holdRightUntil (f, msg, maxFrames) controller.holdButtonUntilOrMaxFrames(Button.RIGHT, msg, f, maxFrames) end
function controller.holdUp (frames) controller.holdButton(Button.UP, frames) end
function controller.holdUpUntil (f, msg, maxFrames) controller.holdButtonUntilOrMaxFrames(Button.UP, msg, f, maxFrames) end
function controller.holdDown (frames) controller.holdButton(Button.DOWN, frames) end
function controller.holdDownUntil (f, msg, maxFrames) controller.holdButtonUntilOrMaxFrames(Button.DOWN, msg, f, maxFrames) end
