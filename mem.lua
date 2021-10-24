require 'Class'
require 'helpers'
require 'player_data'
require 'shops'

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

function Memory:getCoordinates()
  return Point(OverWorldId, self:readRAM(0xe114), self:readRAM(0xe11A))
end

function Memory:getRadiantTimer () return self:readRAM(0xDA) end
function Memory:setRadiantTimer (n) return self:writeRAM(0xDA, n) end

function Memory:getRepelTimer () return self:readRAM(0xDB) end
function Memory:setRepelTimer (n) return self:writeRAM(0xDB, n) end

-- get the id of the current enemy, if it exists
-- no idea what gets returned if not in battle
function Memory:getEnemyId () return self.ram.readbyte(ENEMY_ID_ADDR) end
function Memory:setEnemyId (enemyId) return memory.writebyte(ENEMY_ID_ADDR, enemyId) end

function Memory:setReturnWarpLocation(x, y)
  self:writeROM(RETURN_WARP_X_ADDR, x)
  self:writeROM(RETURN_WARP_Y_ADDR, y)
end

function Memory:getItemNumberOfHerbs ()
  return self.ram.readbyte(0xc0)
end

function Memory:getItemNumberOfKeys ()
  return self.ram.readbyte(0xbf)
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

function Memory:getStatuses()
  return Statuses(self.ram.readbyte(0xcf), self.ram.readbyte(0xdf))
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
  local highB = self.ram.readbyte(0xbb)
  local lowB = self.ram.readbyte(0xba)
  return (highB * 2^8 + lowB)
end

function Memory:getGold()
  -- todo have to check this with values over 256
  local highB = self.ram.readbyte(0xbd)
  local lowB = self.ram.readbyte(0xbc)
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

function Memory:readLevels()
  local res = {}
  local i = 0xF35B+16
  while i <= 0xF395+16 do
    local next = self:readROM(i+1) * 256 + self:readROM(i)
    table.insert(res, next)
    i = i + 2
  end
  return res
end

function Memory:readPlayerData()
  return PlayerData(self:getLocation(), self:readStats(), self:getEquipment(),
                    self:spells(), self:getItems(), self:getStatuses(), self:readLevels())
end

function Memory:readWeaponAndArmorShops()
  function readSlots(start, stop)
    local slots = {}
    for i = start,stop do table.insert(slots, self:readROM(i)) end
    return slots
  end

  -- TODO: these might have to be redone
  -- because one shop sometimes has 5 things, and sometimes 6
  -- and all the shops end with a special delimiter (253 i think)
  return WeaponAndArmorShops(
    readSlots(0x19A8, 0x19AC), -- Brecconary
    readSlots(0x19B4, 0x19B8), -- Cantlin1
    readSlots(0x19BA, 0x19BE), -- Cantlin2
    readSlots(0x19C0, 0x19C4), -- Cantlin3
    readSlots(0x19AE, 0x19B2), -- Garinham
    readSlots(0x19A1, 0x19A6), -- Kol
    readSlots(0x19C6, 0x19CA)  -- Rimuldar
  )
end

function Memory:readSearchSpots()
  function readSpot(b, loc)
    local id = self:readRAM(b)
    if id == 0 then return SearchSpot(loc, nil)
    else return SearchSpot(loc, CHEST_CONTENT[self:readRAM(b)])
    end
  end
  --  03:E11D: A9 01 LDA #$01  (rom position for overworld search spot)
  --  03:E13C: A9 00 LDA #$00  (rom position for kol search spot)
  --  03:E152: A9 11 LDA #$11  (rom position for hauksness search spot)
  return SearchSpots(
    readSpot(0xe11e, self:getCoordinates()),
    readSpot(0xe13d, Point(Kol, 9, 6)),
    readSpot(0xe153, Point(Hauksness, 18, 12))
  )
end

function Memory:readChests()
  local chests = {}
  -- 5DDD - 5E58  | Chest Data  | Four bytes long: Map,X,Y,Contents
  local firstChestAddr = 0x5ddd
  for i = 0,30 do
    local addr = firstChestAddr + i * 4
    local mapId = self:readROM(addr)
    local x = self:readROM(addr + 1)
    local y = self:readROM(addr + 2)
    local contents = self:readROM(addr + 3)
    table.insert(chests, Chest(Point(mapId, x, y), CHEST_CONTENT[contents]))
  end
  return Chests(chests)
end


-- 0x51 - ??       | NPC Data                | 16 bits ------------------------->   3 bits -> sprite
--                 |                         | 5 bits -> x coordinate
--                 |                         | 3 bits -> direction
--                 |                         | 5 bits -> y coordinate

-- .alias NPCXPos          $51     ;Through $8A. NPC X block position on current map. Also NPC type.
-- .alias NPCYPos          $52     ;Through $8B. NPC Y block position on current map. Also NPC direction.
-- .alias NPCMidPos        $53     ;Through $8C. NPC offset from current tile. Used only when moving.
function Memory:readNPCs()
  return {
    self:readNPC(0x51), -- 123
    self:readNPC(0x54), -- 456
    self:readNPC(0x57), -- 789
    self:readNPC(0x5A), -- abc
    self:readNPC(0x5D), -- def
    self:readNPC(0x60), -- 012
    self:readNPC(0x63), -- 345
    self:readNPC(0x66), -- 678
    self:readNPC(0x69), -- 9ab
    self:readNPC(0x6C), -- cde
    self:readNPC(0x6F), -- f01
    self:readNPC(0x72), -- 234
    self:readNPC(0x75), -- 567
    self:readNPC(0x78), -- 89a
    self:readNPC(0x7B), -- bcd
    self:readNPC(0x7E), -- ef0
    self:readNPC(0x81), -- 123
    self:readNPC(0x84), -- 456
    self:readNPC(0x87), -- 789
    self:readNPC(0x8A), -- abc
  }
end

function Memory:readNPC(byte)
  local b1 = self:readRAM(byte)
  local b2 = self:readRAM(byte + 1)
  return NPC(byte, AND(b1, 31), AND(b2, 31))
  -- if we ever care about sprite and direction (i doubt we will), we can use these:
  -- print("SSS? ", AND(b1, 224), decimalToHex(bitwise_and(b1, 224)))
  -- print("DDD? ", AND(b2, 224), decimalToHex(bitwise_and(b2, 224)))
end

NPC = class(function(a, byte, x, y)
  a.byte = byte
  a.x = x
  a.y = y
end)

function NPC:__tostring()
  return "NPC {x:" .. self.x .. ", y:" .. self.y .. "}"
end

function Memory:printNPCs()
  local npcs = self:readNPCs()
  for _, npc in ipairs(npcs) do
    print(npc)
  end
end