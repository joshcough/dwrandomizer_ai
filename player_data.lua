Torch = 0x1
FairyWater = 0x2
Wings = 0x3
DragonScale = 0x4
FairyFlute = 0x5
FightersRing = 0x6
ErdricksToken = 0x7
GwaelinsLove = 0x8
CursedBelt = 0x9
SilverHarp = 0xa
DeathNecklace = 0xb
StonesOfSunlight = 0xc
StaffOfRain = 0xd
RainbowDrop = 0xe

ITEMS = {
  [Torch] = "Torch",
  [FairyWater] = "Fairy Water",
  [Wings] = "Wings",
  [DragonScale] = "Dragon's Scale",
  [FairyFlute] = "Fairy Flute",
  [FightersRing] = "Fighter's Ring",
  [ErdricksToken] = "Erdrick's Token",
  [GwaelinsLove] = "Gwaelin's Love",
  [CursedBelt] = "Cursed Belt",
  [SilverHarp] = "Silver Harp",
  [DeathNecklace] = "Death Necklace",
  [StonesOfSunlight] = "Stones of Sunlight",
  [StaffOfRain] = "Staff of Rain",
  [RainbowDrop] = "Rainbow Drop",
  -- i dont think this is actually used, especially since it says (glitched)
  -- [0xf] = "Herb (glitched)"
}

Items = class(function(a,nrHerbs,nrKeys,slots)
  a.nrHerbs = nrHerbs
  a.nrKeys = nrKeys
  a.slots = slots
end)

function Items:__tostring()
  local res = "=== Items ===\n"
  res = res .. "Keys: " .. self.nrKeys .. "\n"
  res = res .. "Herbs: " .. self.nrHerbs .. "\n"
  for idx = 1,#(self.slots) do
    if self.slots[idx] ~= 0
    then
      res = res .. idx .. ": " .. ITEMS[self.slots[idx]] .. "\n"
    end
  end
  return res
end

function Items:contains(itemId)
  return table.contains(self.slots, itemId)
end

function Items:numberOfTorches()
  return table.count(self.slots, Torch)
end

function Items:numberOfFairyWaters()
  return table.count(self.slots, FairyWater)
end

function Items:numberOfWings()
  return table.count(self.slots, Wings)
end

function Items:hasDragonScale()
  return self:contains(DragonScale)
end

function Items:hasFairyFlute()
  return self:contains(FairyFlute)
end

function Items:hasFightersRing()
  return self:contains(FightersRing)
end

function Items:hasErdricksToken()
  return self:contains(ErdricksToken)
end

function Items:hasGwaelinsLove()
  return self:contains(GwaelinsLove)
end

function Items:numberOfCursedBelts()
  return table.count(self.slots, CursedBelt)
end

function Items:hasSilverHarp()
  return self:contains(SilverHarp)
end

function Items:hasDeathNecklace()
  return self:contains(DeathNecklace)
end

function Items:hasStonesOfSunlight()
  return self:contains(StonesOfSunlight)
end

function Items:hasStaffOfRain()
  return self:contains(StaffOfRain)
end

function Items:hasRainbowDrop()
  return self:contains(RainbowDrop)
end

BambooPole    = 0x20 --  = 32  = 00100000
Club          = 0x40 --  = 64  = 01000000
CopperSword   = 0x60 --  = 96  = 01100000
HandAxe       = 0x80 --  = 128 = 10000000
BroadSword    = 0xa0 --  = 160 = 10100000
FlameSword    = 0xc0 --  = 192 = 11000000
ErdricksSword = 0xe0 --  = 224 = 11100000

WEAPONS = {
  [BambooPole]    = "Bamboo Pole",
  [Club]          = "Club",
  [CopperSword]   = "Copper Sword",
  [HandAxe]       = "Hand Axe",
  [BroadSword]    = "Broad Sword",
  [FlameSword]    = "Flame Sword",
  [ErdricksSword] = "Erdrick's Sword",
}

Clothes        = 0x4  --  = 4  = 00000100
LeatherArmor   = 0x8  --  = 8  = 00001000
ChainMail      = 0xc  --  = 12 = 00001100
HalfPlateArmor = 0x10 --  = 16 = 00010000
FullPlateArmor = 0x14 --  = 20 = 00010100
MagicArmor     = 0x18 --  = 24 = 00011000
ErdricksArmor  = 0x1c --  = 28 = 00011100

ARMOR = {
  [Clothes]        = "Clothes",
  [LeatherArmor]   = "Leather Armor",
  [ChainMail]      = "Chain Mail",
  [HalfPlateArmor] = "Half Plate Armor",
  [FullPlateArmor] = "Full Plate Armor",
  [MagicArmor]     = "Magic Armor",
  [ErdricksArmor]  = "Erdrick's Armor",
}

SmallShield  = 0x1 -- = 1 = 00000001
LargeShield  = 0x2 -- = 2 = 00000010
SilverShield = 0x3 -- = 3 = 00000011

SHIELDS = {
  [SmallShield]  = "Small Shield",
  [LargeShield]  = "Large Shield",
  [SilverShield] = "Silver Shield",
}

Equipment = class(function(a,swordId,armorId,shieldId)
  a.swordId = swordId
  a.armorId = armorId
  a.shieldId = shieldId
end)

function Equipment:__tostring()
  local res = "=== Equipment ===\n"
  res = res .. "Sword: "  .. (self.swordId == 0 and "Nothing" or WEAPONS[self.swordId]) .. "\n"
  res = res .. "Armor: "  .. (self.armorId == 0 and "Nothing" or ARMOR[self.armorId]) .. "\n"
  res = res .. "Shield: " .. (self.shieldId == 0 and "Nothing" or SHIELDS[self.shieldId]) .. "\n"
  return res
end

Stats = class(function(a,currentHP,maxHP,currentMP, maxMP, xp, gold, level, strength, agility, attackPower, defensePower)
  a.currentHP = currentHP
  a.maxHP = maxHP
  a.currentMP = currentMP
  a.maxMP = maxMP
  a.xp = xp
  a.gold = gold
  a.level = level
  a.strength = strength
  a.agility = agility
  a.attackPower = attackPower
  a.defensePower = defensePower
end)

function Stats:__tostring()
  local res = "=== Stats ===\n"
  res = res .. "CurrentHP: " .. self.currentHP .. "\n"
  res = res .. "MaxHP: " .. self.maxHP .. "\n"
  res = res .. "CurrentMP: " .. self.currentMP .. "\n"
  res = res .. "MaxMP: " .. self.maxMP .. "\n"
  res = res .. "XP: " .. self.xp .. "\n"
  res = res .. "Gold: " .. self.gold .. "\n"
  res = res .. "Level: " .. self.level .. "\n"
  res = res .. "Strength: " .. self.strength .. "\n"
  res = res .. "Agility: " .. self.agility .. "\n"
  res = res .. "AttackPower: " .. self.attackPower .. "\n"
  res = res .. "DefensePower: " .. self.defensePower .. "\n"
  return res
end

PlayerData = class(function(a,stats,equipment,items)
  a.stats = stats
  a.equipment = equipment
  a.items = items
end)

function PlayerData:__tostring()
  local res = "==== Player Data ====\n"
  res = res .. tostring(self.stats)
  res = res .. tostring(self.equipment)
  res = res .. tostring(self.items)
  return res
end
