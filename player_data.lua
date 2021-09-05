ITEMS = {
  [0x1] = "Torch",
  [0x2] = "Fairy Water",
  [0x3] = "Wings",
  [0x4] = "Dragon's Scale",
  [0x5] = "Fairy Flute",
  [0x6] = "Fighter's Ring",
  [0x7] = "Erdrick's Token",
  [0x8] = "Gwaelin's Love",
  [0x9] = "Cursed Belt",
  [0xa] = "Silver Harp",
  [0xb] = "Death Necklace",
  [0xc] = "Stones of Sunlight",
  [0xd] = "Staff of Rain",
  [0xe] = "Rainbow Drop",
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

WEAPONS = {
  [0x20] = "Bamboo Pole",     --  = 32  = 00100000
  [0x40] = "Club",            --  = 64  = 01000000
  [0x60] = "Copper Sword",    --  = 96  = 01100000
  [0x80] = "Hand Axe",        --  = 128 = 10000000
  [0xa0] = "Broad Sword",     --  = 160 = 10100000
  [0xc0] = "Flame Sword",     --  = 192 = 11000000
  [0xe0] = "Erdrick's Sword", --  = 224 = 11100000 
}

ARMOR = {
  [0x4]  = "Clothes",          --  = 4  = 00000100
  [0x8]  = "Leather Armor",    --  = 8  = 00001000
  [0xc]  = "Chain Mail",       --  = 12 = 00001100
  [0x10] = "Half Plate Armor", --  = 16 = 00010000
  [0x14] = "Full Plate Armor", --  = 20 = 00010100
  [0x18] = "Magic Armor",      --  = 24 = 00011000
  [0x1c] = "Erdrick's Armor",  --  = 28 = 00011100
}

SHIELDS = {
  [0x1] = "Small Shield",  -- = 1 = 00000001
  [0x2] = "Large Shield",  -- = 2 = 00000010
  [0x3] = "Silver Shield", -- = 3 = 00000011
}

Equipment = class(function(a,swordId,armorId,shieldId)
  a.swordId = swordId
  a.armorId = armorId
  a.shieldId = shieldId
end)

function Equipment:__tostring()
  local res = "=== Equipment ===\n"
  res = res .. "Sword: " .. (self.swordId == 0 and "Nothing" or WEAPONS[self.swordId]) .. "\n"
  res = res .. "Armor: " .. (self.armorId == 0 and "Nothing" or ARMOR[self.armorId]) .. "\n"
  res = res .. "Shield: " ..(self.shieldId == 0 and "Nothing" or SHIELDS[self.shieldId]) .. "\n"
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


