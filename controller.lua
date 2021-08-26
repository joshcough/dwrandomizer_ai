A = "A"
B = "B"
START = "start"
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
  for i = 1,n do
    emu.frameadvance();
  end
end

function pressButton (button, wait)
  print("Pressing " .. button)
  e = table.shallow_copy(emptyInputs)
  e[button] = true
  joypad.write(1, e)
  waitFrames(wait)
  joypad.write(1, emptyInputs)
  waitFrames(1)
end

function holdButton (button, frames)
  print("Holding " .. button)
  e = table.shallow_copy(emptyInputs)
  e[button] = true
  for i = 1,frames do
    joypad.write(1, e)
    emu.frameadvance();
  end
  joypad.write(1, emptyInputs)
  emu.frameadvance();
end

function pressStart (wait) pressButton(START, wait) end
function pressSelect (wait) pressButton("select", wait) end
function pressA (wait) pressButton(A, wait) end
function pressB (wait) pressButton(B, wait) end
function pressLeft (wait) pressButton(LEFT, wait) end
function pressRight (wait) pressButton(RIGHT, wait) end
function pressUp (wait) pressButton(UP, wait) end
function pressDown (wait) pressButton(DOWN, wait) end

function holdStart (frames) holdButton(START, frames) end
function holdSelect (frames) holdButton("select", frames) end
function holdA (frames) holdButton(A, frames) end
function holdB (frames) holdButton(B, frames) end
function holdLeft (frames) holdButton(LEFT, frames) end
function holdRight (frames) holdButton(RIGHT, frames) end
function holdUp (frames) holdButton(UP, frames) end
function holdDown (frames) holdButton(DOWN, frames) end
