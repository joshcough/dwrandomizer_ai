require 'Class'
require 'helpers'
require 'player_data'

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
-- get the id of the current map
function Memory:getMapId () return self:readRAM(MAP_ADDR) end

function Memory:getLocation ()
  return Point(self:getMapId(), self:getX(), self:getY())
end

function Memory:getRadiantTimer () return self:readRAM(0xDA) end
function Memory:setRadiantTimer (n) return self:writeRAM(0xDA, n) end

function Memory:getRepelTimer () return self:readRAM(0xDB) end
function Memory:setRepelTimer (n) return self:writeRAM(0xDB, n) end

-- get the id of the current enemy, if it exists
-- no idea what gets returned if not in battle
function Memory:getEnemyId () return self.ram.readbyte(ENEMY_ID_ADDR)+1 end
function Memory:setEnemyId (enemyId) return memory.writebyte(ENEMY_ID_ADDR, enemyId) end

function setReturnWarpLocation(x, y)
  mem:writeROM(RETURN_WARP_X_ADDR, x)
  mem:writeROM(RETURN_WARP_Y_ADDR, y)
end

function Memory:getItemNumberOfHerbs ()
  return self.ram.readbyte(0xbf)
end

function Memory:getItemNumberOfKeys ()
  return self.ram.readbyte(0xc0)
end

function Memory:getItems()
  local slots = {}
  local b12 = self.ram.readbyte(0xc1)
  slots[1] = loNibble(b12)
  slots[2] = hiNibble(b12)
  local b34 = self.ram.readbyte(0xc2)
  slots[3] = loNibble(b34)
  slots[4] = hiNibble(b34)
  local b56 = self.ram.readbyte(0xc3)
  slots[5] = loNibble(b56)
  slots[6] = hiNibble(b56)
  local b78 = self.ram.readbyte(0xc4)
  slots[7] = loNibble(b78)
  slots[8] = hiNibble(b78)
  return Items(self:getItemNumberOfHerbs(), self:getItemNumberOfKeys(), slots)
end

function Memory:getEquipment()
  local b = self.ram.readbyte(0xbe)
  local weaponId = bitwise_and(b, 224)
  local armorId = bitwise_and(b, 28)
  local shieldId = bitwise_and(b, 3)
  return Equipment(weaponId, armorId, shieldId)
end

function Memory:getCurrentHP ()
  return self.ram.readbyte(0xc5)
end

function Memory:getMaxHP ()
  return self.ram.readbyte(0xca)
end

function Memory:getCurrentMP ()
  return self.ram.readbyte(0xc6)
end

function Memory:getMaxMP ()
  return self.ram.readbyte(0xcb)
end

function Memory:getXP()
  local highB = self.ram.readbyte(0xba)
  local lowB = self.ram.readbyte(0xbb)
  return (highB * 2^8 + lowB)
end

function Memory:getGold()
  local highB = self.ram.readbyte(0xbc)
  local lowB = self.ram.readbyte(0xbd)
  return (highB * 2^8 + lowB)
end

function Memory:getLevel()
  return self.ram.readbyte(0xc7)
end

function Memory:getStrength()
  return self.ram.readbyte(0xc8)
end

function Memory:getAgility()
  return self.ram.readbyte(0xc9)
end

function Memory:getAttackPower()
  return self.ram.readbyte(0xcc)
end

function Memory:getDefensePower()
  return self.ram.readbyte(0xcd)
end

function Memory:readStats()
  return Stats(
    self:getCurrentHP(),
    self:getMaxHP(),
    self:getCurrentMP(),
    self:getMaxMP(),
    self:getXP(),
    self:getGold(),
    self:getLevel(),
    self:getStrength(),
    self:getAgility(),
    self:getAttackPower(),
    self:getDefensePower()
  )
end

function Memory:spells()
  return Spells(self.ram.readbyte(0xce),  self.ram.readbyte(0xcf))
end

function Memory:readPlayerData()
  return PlayerData(self:readStats(), self:getEquipment(), self:spells(), self:getItems())
end
