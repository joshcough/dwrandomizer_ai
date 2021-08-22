
emptyInputs = {
  ["start"] = nil,
  ["A"]     = nil,
  ["B"]     = nil,
  ["up"]    = nil,
  ["down"]  = nil,
  ["left"]  = nil,
  ["right"] = nil,
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

function pressStart (wait) pressButton("start", wait) end
function pressSelect (wait) pressButton("select", wait) end
function pressA (wait) pressButton("A", wait) end
function pressB (wait) pressButton("B", wait) end
function pressLeft (wait) pressButton("left", wait) end
function pressRight (wait) pressButton("right", wait) end
function pressUp (wait) pressButton("up", wait) end
function pressDown (wait) pressButton("down", wait) end

function holdStart (frames) holdButton("start", frames) end
function holdSelect (frames) holdButton("select", frames) end
function holdA (frames) holdButton("A", frames) end
function holdB (frames) holdButton("B", frames) end
function holdLeft (frames) holdButton("left", frames) end
function holdRight (frames) holdButton("right", frames) end
function holdUp (frames) holdButton("up", frames) end
function holdDown (frames) holdButton("down", frames) end
