-- =====================
-- ======= Items =======
-- =====================

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

function Items:equals(i)
  return self.nrHerbs == i.nrHerbs and
         self.nrKeys == i.nrKeys and
         #(self.slots) == #(i.slots) and
         list.all(list.zipWith(self.slots, i.slots), function (is) return is[1] == is[2] end)
end

-- =====================
-- ===== Equipment =====
-- =====================

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

function Equipment:equals(e)
  return self.swordId == e.swordId and
         self.armorId == e.armorId and
         self.shieldId == e.shieldId
end

-- =========================
-- === Player statistics ===
-- =========================

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

function Stats:equals(stats)
  return self.currentHP == stats.currentHP and
         self.maxHP == stats.maxHP and
         self.currentMP == stats.currentMP and
         self.maxMP == stats.maxMP and
         self.xp == stats.xp and
         self.gold == stats.gold and
         self.level == stats.level and
         self.strength == stats.strength and
         self.agility == stats.agility and
         self.attackPower == stats.attackPower and
         self.defensePower == stats.defensePower
end

-- =====================
-- ====== Spells! ======
-- =====================

SpellId = class(function(a,spellByte, spellId)
  a.spellByte = spellByte
  a.spellId = spellId
end)

function SpellId:equals(spellId)
  return self.spellByte == spellId.spellByte and self.spellId == spellId.spellId
end

Spell = class(function(a,spellId, spellName)
  a.spellId = spellId
  a.spellName = spellName
end)

function Spell:equals(spell)
  return self.spellId:equals(spell.spellId) and self.spellName == spell.spellName
end

function Spell:__tostring()
  return self.spellName
end

-- 0xce | Spells unlocked   | 0x80=repel, 0x40=return, 0x20=outside, 0x10=stopspell,
--      |                   | 0x8=radiant, 0x4=sleep, 0x2=hurt, 0x1=heal
-- 0xcf | Spells/Quest Prog | 0x80=death necklace equipped, 0x40=cursed belt equipped,
--      |                   | 0x20=fighters ring equipped, 0x10=dragon's scale equipped,
--      |                   | 0x8=rainbow bridge, 0x4=stairs in charlock found, 0x2=hurtmore, 0x1=healmore

CE_BYTE = 0xce
CF_BYTE = 0xcf

-- CE_BYTE
HealId      = SpellId(CE_BYTE, 0x1)  -- 00000001
HurtId      = SpellId(CE_BYTE, 0x2)  -- 00000010
SleepId     = SpellId(CE_BYTE, 0x4)  -- 00000100
RadiantId   = SpellId(CE_BYTE, 0x8)  -- 00001000
StopspellId = SpellId(CE_BYTE, 0x10) -- 00010000
OutsideId   = SpellId(CE_BYTE, 0x20) -- 00100000
ReturnId    = SpellId(CE_BYTE, 0x40) -- 01000000
RepelId     = SpellId(CE_BYTE, 0x80) -- 10000000
-- CF_BYTE
HealmoreId  = SpellId(CF_BYTE, 0x1)  -- 00000001
HurtmoreId  = SpellId(CF_BYTE, 0x2)  -- 00000010

Heal      = Spell(HealId,      "Heal")
Hurt      = Spell(HurtId,      "Hurt")
Sleep     = Spell(SleepId,     "Sleep")
Radiant   = Spell(RadiantId,   "Radiant")
Stopspell = Spell(StopspellId, "Stopspell")
Outside   = Spell(OutsideId,   "Outside")
Return    = Spell(ReturnId,    "Return")
Repel     = Spell(RepelId,     "Repel")
Healmore  = Spell(HealmoreId,  "Healmore")
Hurtmore  = Spell(HurtmoreId,  "Hurtmore")

--[[
=== Spells ===
  Hurt
  Sleep
  Radiant
  Return
  Repel
  Healmore
  Hurtmore
 ]]
-- no heal, stopspell, outside

ALL_SPELLS = {
  Heal,
  Hurt,
  Sleep,
  Radiant,
  Stopspell,
  Outside,
  Return,
  Repel,
  Healmore,
  Hurtmore,
}

-- reads all the spells owned by the player by reading ceByte, and cfByte
Spells = class(function(a,ceByte, cfByte)
  a.order = {}
  function f(spell)
    local byte = spell.spellId.spellByte == CE_BYTE and ceByte or cfByte
    local res = bitwise_and(byte, spell.spellId.spellId) > 0
    if res then table.insert(a.order, spell) end
    return res
  end
  for _,s in pairs(ALL_SPELLS) do f(s) end
end)

function Spells:spellIndex(spell)
  return list.indexOf(self.order, spell, function(s1, s2) return s1:equals(s2) end)
end

function Spells:__tostring()
  local res = "=== Spells ===\n"
  for ix,s in pairs(self.order) do
    res = res .. "  " .. tostring(ix) .. ": " .. tostring(s.spellName) .. "\n"
  end
  return res
end

function Spells:equals(spells)
  if #(self.order) ~= #(spells.order)
    then return false
  else
    return list.all(list.zipWith(self.order, spells.order), function (ss) return ss[1]:equals(ss[2]) end)
  end
end


-- =======================
-- === All Player data ===
-- =======================

PlayerData = class(function(a,stats,equipment,spells,items)
  a.stats = stats
  a.equipment = equipment
  a.spells = spells
  a.items = items
end)

function PlayerData:equals(pd)
  return self.stats:equals(pd.stats) and
         self.equipment:equals(pd.equipment) and
         self.spells:equals(pd.spells) and
         self.items:equals(pd.items)
end

function PlayerData:__tostring()
  local res = "==== Player Data ====\n"
  res = res .. tostring(self.stats)
  res = res .. tostring(self.equipment)
  res = res .. tostring(self.spells)
  res = res .. tostring(self.items)
  return res
end
