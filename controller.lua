A = "A"
B = "B"
START = "start"
SELECT = "select"
UP = "up"
DOWN = "down"
LEFT = "left"
RIGHT = "right"

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
  -- log.debug("Pressing " .. button .. " and waiting .. " .. tostring(wait))
  e = table.shallow_copy(emptyInputs)
  e[button] = true
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
  -- log.debug("Holding " .. button .. " until " .. msg)
  e = table.shallow_copy(emptyInputs)
  e[button] = true
  while not conditionFunction() do
    joypad.write(1, e)
    emu.frameadvance()
  end
  -- log.debug("Done holding " .. button .. " until " .. msg)
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

function pressStart (wait) pressButton(START, wait) end
function pressSelect (wait) pressButton(SELECT, wait) end
function pressA (wait) pressButton(A, wait) end
function pressB (wait) pressButton(B, wait) end
function pressLeft (wait) pressButton(LEFT, wait) end
function pressRight (wait) pressButton(RIGHT, wait) end
function pressUp (wait) pressButton(UP, wait) end
function pressDown (wait) pressButton(DOWN, wait) end

function holdStart (frames) holdButton(START, frames) end
function holdStartUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(START, msg, f, maxFrames) end
function holdSelect (frames) holdButton(SELECT, frames) end
function holdSelectUntil (f, maxFrames) holdButtonUntilOrMaxFrames(SELECT, msg, f, maxFrames) end
function holdA (frames) holdButton(A, frames) end
function holdAUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(A, msg, f, maxFrames) end
function holdB (frames) holdButton(B, frames) end
function holdBUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(B, msg, f, maxFrames) end
function holdLeft (frames) holdButton(LEFT, frames) end
function holdLeftUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(LEFT, msg, f, maxFrames) end
function holdRight (frames) holdButton(RIGHT, frames) end
function holdRightUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(RIGHT, msg, f, maxFrames) end
function holdUp (frames) holdButton(UP, frames) end
function holdUpUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(UP, msg, f, maxFrames) end
function holdDown (frames) holdButton(DOWN, frames) end
function holdDownUntil (f, msg, maxFrames) holdButtonUntilOrMaxFrames(DOWN, msg, f, maxFrames) end
