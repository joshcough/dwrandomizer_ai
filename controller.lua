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
function waitUntil (f, maxFrames)
  for i = 1,maxFrames do
    if f() then return end
    emu.frameadvance()
  end
end

function clearController()
  joypad.write(1, emptyInputs)
end

function pressButton (button, wait)
  -- print("Pressing " .. button)
  e = table.shallow_copy(emptyInputs)
  e[button] = true
  joypad.write(1, e)
  waitFrames(wait)
  clearController()
  waitFrames(1)
end

function holdButton (button, frames)
  local nrFrames = 0
  holdButtonUntil(button, function()
    nrFrames = nrFrames + 1
    return nrFrames >= frames
  end)
end

function holdButtonUntil(button, conditionFunction)
  -- print("Holding " .. button)
  e = table.shallow_copy(emptyInputs)
  e[button] = true
  while not conditionFunction() do
    joypad.write(1, e)
    emu.frameadvance();
  end
  -- print("Done holding " .. button)
  clearController()
  emu.frameadvance();
end

function holdButtonUntilOrMaxFrames(button, conditionFunction, maxFrames)
  -- print("Holding " .. button)
  local nrFrames = 0
  holdButtonUntil(button, function()
    nrFrames = nrFrames + 1
    return (nrFrames >= maxFrames) or conditionFunction()
  end)
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
function holdStartUntil (f, maxFrames) holdButtonUntilOrMaxFrames(START, f, maxFrames) end
function holdSelect (frames) holdButton(SELECT, frames) end
function holdSelectUntil (f, maxFrames) holdButtonUntilOrMaxFrames(SELECT, f, maxFrames) end
function holdA (frames) holdButton(A, frames) end
function holdAUntil (f, maxFrames) holdButtonUntilOrMaxFrames(A, f, maxFrames) end
function holdB (frames) holdButton(B, frames) end
function holdBUntil (f, maxFrames) holdButtonUntilOrMaxFrames(B, f, maxFrames) end
function holdLeft (frames) holdButton(LEFT, frames) end
function holdLeftUntil (f, maxFrames) holdButtonUntilOrMaxFrames(LEFT, f, maxFrames) end
function holdRight (frames) holdButton(RIGHT, frames) end
function holdRightUntil (f, maxFrames) holdButtonUntilOrMaxFrames(RIGHT, f, maxFrames) end
function holdUp (frames) holdButton(UP, frames) end
function holdUpUntil (f, maxFrames) holdButtonUntilOrMaxFrames(UP, f, maxFrames) end
function holdDown (frames) holdButton(DOWN, frames) end
function holdDownUntil (f, maxFrames) holdButtonUntilOrMaxFrames(DOWN, f, maxFrames) end
