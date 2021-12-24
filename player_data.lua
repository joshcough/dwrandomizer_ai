require 'Class'
enum = require("enum")
require 'helpers'

-- =====================
-- ======= Items =======
-- =====================

TorchByte = 0x1
FairyWaterByte = 0x2
WingsByte = 0x3
DragonScaleByte = 0x4
FairyFluteByte = 0x5
FightersRingByte = 0x6
ErdricksTokenByte = 0x7
GwaelinsLoveByte = 0x8
CursedBeltByte = 0x9
SilverHarpByte = 0xa
DeathNecklaceByte = 0xb
StonesOfSunlightByte = 0xc
StaffOfRainByte = 0xd
RainbowDropByte = 0xe
HerbByte = 0xf
MagicKeyByte = 0x10

Item = class(function(a, byte, name)
  a.byte = byte
  a.name = name
end)

function Item:__tostring()
  return self.name
end

Torch = Item(TorchByte, "Torch")
FairyWater = Item(FairyWaterByte, "Fairy Water")
Wings = Item(WingsByte, "Wings")
DragonScale = Item(DragonScaleByte, "Dragon's Scale")
FairyFlute = Item(FairyFluteByte, "Fairy Flute")
FightersRing = Item(FightersRingByte, "Fighter's Ring")
ErdricksToken = Item(ErdricksTokenByte, "Erdrick's Token")
GwaelinsLove = Item(GwaelinsLoveByte, "Gwaelin's Love")
CursedBelt = Item(CursedBeltByte, "Cursed Belt")
SilverHarp = Item(SilverHarpByte, "Silver Harp")
DeathNecklace = Item(DeathNecklaceByte, "Death Necklace")
StonesOfSunlight = Item(StonesOfSunlightByte, "Stones of Sunlight")
StaffOfRain = Item(StaffOfRainByte, "Staff of Rain")
RainbowDrop = Item(RainbowDropByte, "Rainbow Drop")
Herb = Item(HerbByte, "Herb")
MagicKey = Item(MagicKeyByte, "Magic Key")

ITEMS = {
  [Torch.byte] = Torch,
  [FairyWater.byte] = FairyWater,
  [Wings.byte] = Wings,
  [DragonScale.byte] = DragonScale,
  [FairyFlute.byte] = FairyFlute,
  [FightersRing.byte] = FightersRing,
  [ErdricksToken.byte] = ErdricksToken,
  [GwaelinsLove.byte] = GwaelinsLove,
  [CursedBelt.byte] = CursedBelt,
  [SilverHarp.byte] = SilverHarp,
  [DeathNecklace.byte] = DeathNecklace,
  [StonesOfSunlight.byte] = StonesOfSunlight,
  [StaffOfRain.byte] = StaffOfRain,
  [RainbowDrop.byte] = RainbowDrop,
  -- these are not really used:
  [Herb.byte] = Herb,
  [MagicKey.byte] = MagicKey,
}

Items = class(function(a,nrHerbs,nrKeys,slots)
  a.nrHerbs = nrHerbs
  a.nrKeys = nrKeys
  a.slots = list.map(slots, function(slot) return ITEMS[slot] end)
end)

function Items:__tostring()
  local res = "=== Items ===\n"
  res = res .. "Keys: " .. self.nrKeys .. "\n"
  res = res .. "Herbs: " .. self.nrHerbs .. "\n"
  for idx = 1,#(self.slots) do
    res = res .. idx .. ": " .. tostring(self.slots[idx]) .. "\n"
  end
  return res
end

function Items:itemIndex(item)
  if not self:contains(item) then return nil end
  local herbOffset = self:haveHerbs() and 1 or 0
  local keyOffset = self:haveKeys() and 1 + herbOffset or 0
  local indexOffset = keyOffset
  if item == Herb and self:haveHerbs() then return 1
  elseif item == MagicKey and self:haveKeys() then return keyOffset
  else
    local slotIndex = list.indexOf(self.slots, item)
    return indexOffset + slotIndex
  end
end

function Items:contains(item)
  if item == Herb then return self:haveHerbs()
  elseif item == MagicKey then return self:haveKeys()
  else return list.any(self.slots, function(i) return i == item end)
  end
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

function Items:hasWings()
  return self:numberOfWings() > 0
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

function Items:haveKeys()
  return self.nrKeys > 0
end

function Items:haveHerbs()
  return self.nrHerbs > 0
end

function Items:equals(i)
  return self.nrHerbs == i.nrHerbs and
         self.nrKeys == i.nrKeys and
         #(self.slots) == #(i.slots) and
         list.all(list.zipWith(self.slots, i.slots), function (is) return is[1] == is[2] end)
end

-- =====================
-- ===== Statuses! =====
-- =====================

-- 0xdf | 0x80=Hero asleep, 0x40=Enemy asleep, 0x20=Enemy's spell stopped,
--      | 0x10=Hero's spell stopped, 0x8=You have left throne room,
--      | 0x4=Death necklace obtained, 0x2=Returned Gwaelin, 0x1=Carrying Gwaelin

-- 0xcf | Spells/Quest Prog | 0x80=death necklace equipped, 0x40=cursed belt equipped,
--      |                   | 0x20=fighters ring equipped, 0x10=dragon's scale equipped,
--      |                   | 0x8=rainbow bridge, 0x4=stairs in charlock found

Statuses = class(function(a, cfByte, dfByte)
  -- CF
  a.stairsInCharlock      = bitwise_and(cfByte, 0x4)  > 0
  a.rainbowBridge         = bitwise_and(cfByte, 0x8)  > 0
  a.dragonScaleEquipped   = bitwise_and(cfByte, 0x10) > 0
  a.fightersRingEquipped  = bitwise_and(cfByte, 0x20) > 0
  a.cursedBeltEquipped    = bitwise_and(cfByte, 0x40) > 0
  a.deathNecklaceEquipped = bitwise_and(cfByte, 0x80) > 0
  -- DF
  a.carryingGwaelin       = bitwise_and(dfByte, 0x1)  > 0
  a.returnedGwaelin       = bitwise_and(dfByte, 0x2)  > 0
  a.deathNecklaceObtained = bitwise_and(dfByte, 0x4)  > 0
  a.leftThroneRoom        = bitwise_and(dfByte, 0x8)  > 0
  a.heroSpellStopped      = bitwise_and(dfByte, 0x10) > 0
  a.enemySpellStopped     = bitwise_and(dfByte, 0x20) > 0
  a.enemyAsleep           = bitwise_and(dfByte, 0x40) > 0
  a.heroAsleep            = bitwise_and(dfByte, 0x80) > 0
end)

function Statuses:__tostring()
  local res = "=== Statuses ===\n"
  res = res .. "stairsInCharlock: "      .. tostring(self.stairsInCharlock) .. "\n"
  res = res .. "rainbowBridge: "         .. tostring(self.rainbowBridge) .. "\n"
  res = res .. "dragonScaleEquipped: "   .. tostring(self.dragonScaleEquipped) .. "\n"
  res = res .. "fightersRingEquipped: "  .. tostring(self.fightersRingEquipped) .. "\n"
  res = res .. "cursedBeltEquipped: "    .. tostring(self.cursedBeltEquipped) .. "\n"
  res = res .. "deathNecklaceEquipped: " .. tostring(self.deathNecklaceEquipped) .. "\n"
  res = res .. "carryingGwaelin: "       .. tostring(self.carryingGwaelin) .. "\n"
  res = res .. "returnedGwaelin: "       .. tostring(self.returnedGwaelin) .. "\n"
  res = res .. "deathNecklaceObtained: " .. tostring(self.deathNecklaceObtained) .. "\n"
  res = res .. "leftThroneRoom: "        .. tostring(self.leftThroneRoom) .. "\n"
  res = res .. "heroSpellStopped: "      .. tostring(self.heroSpellStopped) .. "\n"
  res = res .. "enemySpellStopped: "     .. tostring(self.enemySpellStopped) .. "\n"
  res = res .. "enemyAsleep: "           .. tostring(self.enemyAsleep) .. "\n"
  res = res .. "heroAsleep: "            .. tostring(self.heroAsleep) .. "\n"
  return res
end

-- =====================
-- ===== Equipment =====
-- =====================

EquipmentItem = class(Item, function(a, byte, name)
  Item.init(a, byte, name)
end)

function EquipmentItem:__tostring()
  return self.name .. " (" .. self.byte .. ")"
end

NoWeaponByte      = 0x0  --  = 0   = 00000000
BambooPoleByte    = 0x20 --  = 32  = 00100000
ClubByte          = 0x40 --  = 64  = 01000000
CopperSwordByte   = 0x60 --  = 96  = 01100000
HandAxeByte       = 0x80 --  = 128 = 10000000
BroadSwordByte    = 0xa0 --  = 160 = 10100000
FlameSwordByte    = 0xc0 --  = 192 = 11000000
ErdricksSwordByte = 0xe0 --  = 224 = 11100000

Weapon = class(EquipmentItem, function(a, byte, name)
  EquipmentItem.init(a, byte, name)
end)

NoWeapon      = Weapon(NoWeaponByte,      "Nothing")
BambooPole    = Weapon(BambooPoleByte,    "Bamboo Pole")
Club          = Weapon(ClubByte,          "Club")
CopperSword   = Weapon(CopperSwordByte,   "Copper Sword")
HandAxe       = Weapon(HandAxeByte,       "Hand Axe")
BroadSword    = Weapon(BroadSwordByte,    "Broad Sword")
FlameSword    = Weapon(FlameSwordByte,    "Flame Sword")
ErdricksSword = Weapon(ErdricksSwordByte, "Erdrick's Sword")

WEAPONS = {
  [NoWeapon.byte]      = NoWeapon,
  [BambooPole.byte]    = BambooPole,
  [Club.byte]          = Club,
  [CopperSword.byte]   = CopperSword,
  [HandAxe.byte]       = HandAxe,
  [BroadSword.byte]    = BroadSword,
  [FlameSword.byte]    = FlameSword,
  [ErdricksSword.byte] = ErdricksSword,
}

NoArmorByte        = 0x0  --  = 0  = 00000000
ClothesByte        = 0x4  --  = 4  = 00000100
LeatherArmorByte   = 0x8  --  = 8  = 00001000
ChainMailByte      = 0xc  --  = 12 = 00001100
HalfPlateArmorByte = 0x10 --  = 16 = 00010000
FullPlateArmorByte = 0x14 --  = 20 = 00010100
MagicArmorByte     = 0x18 --  = 24 = 00011000
ErdricksArmorByte  = 0x1c --  = 28 = 00011100

Armor = class(EquipmentItem, function(a, byte, name)
  EquipmentItem.init(a, byte, name)
end)

NoArmor        = Armor(NoArmorByte,        "Nothing")
Clothes        = Armor(ClothesByte,        "Clothes")
LeatherArmor   = Armor(LeatherArmorByte,   "Leather Armor")
ChainMail      = Armor(ChainMailByte,      "Chain Mail")
HalfPlateArmor = Armor(HalfPlateArmorByte, "Half Plate Armor")
FullPlateArmor = Armor(FullPlateArmorByte, "Full Plate Armor")
MagicArmor     = Armor(MagicArmorByte,     "Magic Armor")
ErdricksArmor  = Armor(ErdricksArmorByte,  "Erdrick's Armor")

ARMOR = {
  [NoArmor.byte]        = NoArmor,
  [Clothes.byte]        = Clothes,
  [LeatherArmor.byte]   = LeatherArmor,
  [ChainMail.byte]      = ChainMail,
  [HalfPlateArmor.byte] = HalfPlateArmor,
  [FullPlateArmor.byte] = FullPlateArmor,
  [MagicArmor.byte]     = MagicArmor,
  [ErdricksArmor.byte]  = ErdricksArmor,
}

NoShieldByte     = 0x0 -- = 0 = 00000000
SmallShieldByte  = 0x1 -- = 1 = 00000001
LargeShieldByte  = 0x2 -- = 2 = 00000010
SilverShieldByte = 0x3 -- = 3 = 00000011

Shield = class(EquipmentItem, function(a, byte, name)
  EquipmentItem.init(a, byte, name)
end)

NoShield     = Shield(NoShieldByte,     "Nothing")
SmallShield  = Shield(SmallShieldByte,  "Small Shield")
LargeShield  = Shield(LargeShieldByte,  "Large Shield")
SilverShield = Shield(SilverShieldByte, "Silver Shield")

SHIELDS = {
  [NoShield.byte]     = NoShield,
  [SmallShield.byte]  = SmallShield,
  [LargeShield.byte]  = LargeShield,
  [SilverShield.byte] = SilverShield,
}

Equipment = class(function(a,swordId,armorId,shieldId)
  a.weapon = WEAPONS[swordId]
  a.armor = ARMOR[armorId]
  a.shield = SHIELDS[shieldId]
end)

function Equipment:__tostring()
  local res = "=== Equipment ===\n"
  res = res .. "Weapon: " .. tostring(self.weapon) .. "\n"
  res = res .. "Armor: "  .. tostring(self.armor) .. "\n"
  res = res .. "Shield: " .. tostring(self.shield) .. "\n"
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

Spell = class(function(a,spellId, spellName, mp)
  a.spellId = spellId
  a.spellName = spellName
  a.mp = mp
end)

function Spell:equals(spell)
  return self.spellId:equals(spell.spellId) and self.spellName == spell.spellName
end

function Spell:__tostring()
  return self.spellName
end

-- 0xce | Spells unlocked   | 0x80=repel, 0x40=return, 0x20=outside, 0x10=stopspell,
--      |                   | 0x8=radiant, 0x4=sleep, 0x2=hurt, 0x1=heal
-- 0xcf | Spells/Quest Prog | 0x2=hurtmore, 0x1=healmore

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

Heal      = Spell(HealId,      "Heal",      3)
Hurt      = Spell(HurtId,      "Hurt",      2)
Sleep     = Spell(SleepId,     "Sleep",     2)
Radiant   = Spell(RadiantId,   "Radiant",   2)
Stopspell = Spell(StopspellId, "Stopspell", 2)
Outside   = Spell(OutsideId,   "Outside",   6)
Return    = Spell(ReturnId,    "Return",    8)
Repel     = Spell(RepelId,     "Repel",     2)
Healmore  = Spell(HealmoreId,  "Healmore",  8)
Hurtmore  = Spell(HurtmoreId,  "Hurtmore",  5)

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

function Spells:contains(spell)
  return self:spellIndex(spell) ~= nil
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

PlayerData = class(function(a,loc,stats,equipment,spells,items,statuses,levels)
  a.loc = loc
  a.stats = stats
  a.equipment = equipment
  a.spells = spells
  a.items = items
  a.statuses = statuses
  a.levels = levels
end)

function PlayerData:equals(pd)
  return self.loc:equals(pd.loc) and
         self.stats:equals(pd.stats) and
         self.equipment:equals(pd.equipment) and
         self.spells:equals(pd.spells) and
         self.items:equals(pd.items) and
         self.statuses:equals(pd.statuses)
end

function PlayerData:__tostring()
  local res = "==== Player Data ====\n"
  res = res .. "Location: " .. tostring(self.loc)
  res = res .. tostring(self.stats)
  res = res .. tostring(self.equipment)
  res = res .. tostring(self.spells)
  res = res .. tostring(self.items)
  res = res .. tostring(self.statuses)
  res = res .. tostring(self.levels)
  return res
end

function PlayerData:xpToNextLevel()
  return self.levels[self.stats.level + 1] - self.stats.xp
end

function PlayerData:totalXpToNextLevel(startLevel)
  return self.levels[startLevel + 1] - self.levels[startLevel]
end

function PlayerData:totalXpToNextLevelFromCurrentLevel()
  local startLevel = self.stats.level
  return self.levels[startLevel + 1] - self.levels[startLevel]
end