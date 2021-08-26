require 'Class'

-- Some constant memory locations
MAP_ADDR = 0x45
X_ADDR = 0x8e
Y_ADDR = 0x8f
ENEMY_ID_ADDR = 0x3c
-- DB10 - DB1F | "Return" placement code
-- The notes of dwr say that that block has the codes, but
-- I've narrowed it down to these exact addresses:
RETURN_WARP_X_ADDR = 0xDB15
RETURN_WARP_Y_ADDR = 0xDB1D

-- ideally this would be an interface or something
-- where we can have different implementations.
-- one from real NES memory and other to mock these calls out or whatever.
Memory = class(function(a,ram,rom)
  a.ram = ram
  a.rom = rom
end)

function Memory:readRAM(addr) return self.ram.readbyte(addr) end
function Memory:writeRAM(addr, value) self.ram.writebyte(addr, value) end

-- TODO: these are being called from outside this file but they should not be!
-- they should be private, and we should expose functions like the ones below these, only.
function Memory:readROM(addr) return self.rom.readbyte(addr) end
function Memory:writeROM(addr, value) self.rom.writebyte(addr, value) end

-- get the x coordinate of the player in the current map
function Memory:getX () return self:readRAM(X_ADDR) end
-- get the y coordinate of the player in the current map
function Memory:getY () return self:readRAM(Y_ADDR) end
-- get the x,y coordinates of the player in the current map
function Memory:getXY () return {["x"]=self:getX(), ["y"]=self:getY()} end
-- get the id of the current map
function Memory:getMapId () return self:readRAM(MAP_ADDR) end
-- get the id of the current enemy, if it exists
-- no idea what gets returned if not in battle
function getEnemyId ()  return memory.readbyte(ENEMY_ID_ADDR)+1 end

function setReturnWarpLocation(x, y)
  mem:writeROM(RETURN_WARP_X_ADDR, x)
  mem:writeROM(RETURN_WARP_Y_ADDR, y)
end
