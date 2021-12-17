require 'Class'
require 'controller'
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
  -- TODO have to check this with values over 256
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

-- ShopItemsTbl:
-- ;Koll weapons and armor shop.
-- L9991:  .byte $02, $03, $0A, $0B, $0E, $FD
-- ;Brecconary weapons and armor shop.
-- L9997:  .byte $00, $01, $02, $07, $08, $0E, $FD
-- ;Garinham weapons and armor shop.
-- L999E:  .byte $01, $02, $03, $08, $09, $0A, $0F, $FD
-- ;Cantlin weapons and armor shop 1.
-- L99A6:  .byte $00, $01, $02, $08, $09, $0F, $FD
-- ;Cantlin weapons and armor shop 2.
-- L99AD:  .byte $03, $04, $0B, $0C, $FD
-- ;Cantlin weapons and armor shop 3.
-- L99B2:  .byte $05, $10, $FD
-- ;Rimuldar weapons and armor shop.
-- L99B5:  .byte $02, $03, $04, $0A, $0B, $0C, $FD
function Memory:readWeaponAndArmorShops()
  function readSlots(start)
    local slots = {}
    local counter = 1
    local nextSlot = self:readROM(start)
    while nextSlot ~= 253 and counter <= 6 do
      table.insert(slots, nextSlot)
      nextSlot = self:readROM(start+counter)
      counter = counter + 1
    end
    return {slots, start+counter}
  end

  local t = {}
  -- 19A1-19CB | Weapon Shop Inventory |
  local addr = 0x19A1
  for i = 1,7 do
    local rs = readSlots(addr)
    t[i] = rs[1]
    addr = rs[2]
  end

  return WeaponAndArmorShops(
    t[2], -- Brecconary
    t[4], -- Cantlin1
    t[5], -- Cantlin2
    t[6], -- Cantlin3
    t[3], -- Garinham
    t[1], -- Kol
    t[7]  -- Rimuldar
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
  local chests = Table3D()
  -- 5DDD - 5E58  | Chest Data  | Four bytes long: Map,X,Y,Contents
  local firstChestAddr = 0x5ddd
  for i = 0,30 do
    local addr = firstChestAddr + i * 4
    local mapId = self:readROM(addr)
    local x = self:readROM(addr + 1)
    local y = self:readROM(addr + 2)
    local contents = self:readROM(addr + 3)
    local p = Point(mapId, x, y)
    local chest = Chest(p, CHEST_CONTENT[contents])
    -- log.debug("chest", chest)
    chests:insert(p, chest)
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
  -- log.debug("SSS? ", AND(b1, 224), decimalToHex(bitwise_and(b1, 224)))
  -- log.debug("DDD? ", AND(b2, 224), decimalToHex(bitwise_and(b2, 224)))
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
    log.debug(npc)
  end
end


function Memory:printDoorsAndChests()
  -- .alias DoorXPos         $600C   ;Through $601A. X and y positions of doors-->
  -- .alias DoorYPos         $600D   ;Through $601B. opened on the current map.
  -- .alias TrsrXPos         $601C   ;Through $602A. X and y positions of treasure-->
  -- .alias TrsrYPos         $601D   ;Through $602B. chests picked up on the current map.
  log.debug("=== Doors:")
  local i = 0x600C
  while i <= 0x601A do
    log.debug(self:readRAM(i), self:readRAM(i+1))
    i = i + 2
  end

  log.debug("=== Chests:")
  local i = 0x601C
  while i <= 0x602A do
    log.debug(self:readRAM(i), self:readRAM(i+1))
    i = i + 2
  end
end

-- .alias CharDirection    $602F   ;Player's facing direction, 0-up, 1-right, 2-down, 3-left.
function Memory:readPlayerDirection()
  local dir = self:readRAM(0x602F)
  if     dir == 0 then return Heading.UP
  elseif dir == 1 then return Heading.RIGHT
  elseif dir == 2 then return Heading.DOWN
  else                 return Heading.LEFT
  end
end