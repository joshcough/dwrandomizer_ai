require 'Class'
require 'player_data'

BambooPoleShopId     = 0
ClubShopId           = 1
CopperSwordShopId    = 2
HandAxeShopId        = 3
BroadSwordShopId     = 4
FlameSwordShopId     = 5
ErdricksSwordShopId  = 6 -- though, this does not appear in shops
ClothesShopId        = 7
LeatherArmorShopId   = 8
ChainMailShopId      = 9
HalfPlateArmorShopId = 10
FullPlateArmorShopId = 11
MagicArmorShopId     = 12
ErdricksArmorShopId  = 13 -- though, this also does not appear in shops
SmallShieldShopId    = 14
LargeShieldShopId    = 15
SilverShieldShopId   = 16

ShopItem = class(function(a,id,item,cost)
  a.id = id
  a.item = item
  a.cost = cost
end)

function ShopItem:__tostring()
  return tostring(self.item) .. " (" .. tostring(self.cost) .. "g)"
end

SHOP_ITEMS = {
  [BambooPoleShopId]     = ShopItem(BambooPoleShopId,     BambooPole,        10),
  [ClubShopId]           = ShopItem(ClubShopId,           Club,              60),
  [CopperSwordShopId]    = ShopItem(CopperSwordShopId,    CopperSword,      180),
  [HandAxeShopId]        = ShopItem(HandAxeShopId,        HandAxe,          560),
  [BroadSwordShopId]     = ShopItem(BroadSwordShopId,     BroadSword,      1500),
  [FlameSwordShopId]     = ShopItem(FlameSwordShopId,     FlameSword,      9800),
  [ErdricksSwordShopId]  = ShopItem(ErdricksSwordShopId,  ErdricksSword,      2),
  [ClothesShopId]        = ShopItem(ClothesShopId,        Clothes,           10),
  [LeatherArmorShopId]   = ShopItem(LeatherArmorShopId,   LeatherArmor,      70),
  [ChainMailShopId]      = ShopItem(ChainMailShopId,      ChainMail,        300),
  [HalfPlateArmorShopId] = ShopItem(HalfPlateArmorShopId, HalfPlateArmor,  1000),
  [FullPlateArmorShopId] = ShopItem(FullPlateArmorShopId, FullPlateArmor,  3000),
  [MagicArmorShopId]     = ShopItem(MagicArmorShopId,     MagicArmor,      7700),
  [ErdricksArmorShopId]  = ShopItem(ErdricksArmorShopId,  ErdricksArmor,      2),
  [SmallShieldShopId]    = ShopItem(SmallShieldShopId,    SmallShield,       90),
  [LargeShieldShopId]    = ShopItem(LargeShieldShopId,    LargeShield,      800),
  [SilverShieldShopId]   = ShopItem(SilverShieldShopId,   SilverShield,   14800),
}

-- TODO: for mobile NPCs, we probably need an NPC id of some sort.
WeaponAndArmorShop = class(function(a,locations,slots)
  a.locations = locations
  a.slots = slots
  a.seenByPlayer = false
end)

function WeaponAndArmorShop:__tostring()
  local res = "=== Weapon/Armor Shop ===\n"
  res = res .. "Locations: {" .. list.intercalateS(", ", self.locations) .. "}\n"
  res = res .. "Seen by player: " .. tostring(self.seenByPlayer) .. "\n"
  for idx = 1,#(self.slots) do
    res = res .. idx .. ": " .. tostring(self.slots[idx]) .. "\n"
  end
  return res
end

Upgrades = class(function(a,weapons,armors,shields)
  a.weapons = weapons
  a.armors = armors
  a.shields = shields
end)

function Upgrades:__tostring()
  function f(x)
    if x == nil then return "Unknown"
    else return "{" ..  list.intercalateS(", ", list.map(x, function(e) return tostring(e) end)) .. "}"
    end
  end
  return f({f(self.weapons), f(self.armors), f(self.shields)})
end

function Upgrades:isEmpty()
  return #(self.weapons) == 0 and #(self.armors) == 0 and #(self.shields) == 0
end

-- returns the items that are upgrades from the current equipment.
function WeaponAndArmorShop:getUpgrades(equip)
  local weapons = {}
  local armors = {}
  local shields = {}
  for i,item in ipairs(self.slots) do
    if     item.item:is_a(Weapon) and item.item.byte > equip.weapon.byte then table.insert(weapons, item)
    elseif item.item:is_a(Armor)  and item.item.byte > equip.armor.byte  then table.insert(armors,  item)
    elseif item.item:is_a(Shield) and item.item.byte > equip.shield.byte then table.insert(shields, item)
    end
  end
  return Upgrades(weapons, armors, shields)
end

function WeaponAndArmorShop:getAffordableUpgrades(playerData)
  local weapons = {}
  local armors = {}
  local shields = {}
  local e = playerData.equipment
  local g = playerData.stats.gold
  for i,item in pairs(self.slots) do
    if     item.item:is_a(Weapon) and item.item.byte > e.weapon.byte and item.cost < g then table.insert(weapons, item)
    elseif item.item:is_a(Armor)  and item.item.byte > e.armor.byte  and item.cost < g then table.insert(armors,  item)
    elseif item.item:is_a(Shield) and item.item.byte > e.shield.byte and item.cost < g then table.insert(shields, item)
    end
  end
  return Upgrades(weapons, armors, shields)
end

function WeaponAndArmorShop:getMostExpensiveAffordableWeaponUpgrade(playerData)
  local aff = self:getAffordableUpgrades(playerData)
  return aff.weapons[#(aff.weapons)]
end

function WeaponAndArmorShop:getMostExpensiveAffordableArmorUpgrade(playerData)
  local aff = self:getAffordableUpgrades(playerData)
  return aff.armors[#(aff.armors)]
end

function WeaponAndArmorShop:getMostExpensiveAffordableShieldUpgrade(playerData)
  local aff = self:getAffordableUpgrades(playerData)
  return aff.shields[#(aff.shields)]
end

function WeaponAndArmorShop:indexOf(itemId)
  return list.indexOf(self.slots, SHOP_ITEMS[itemId])
end

WeaponAndArmorShops = class(function(a, b, c1, c2, c3, g, k, r)
  function getShopItems(ids) return list.map(ids, function(id) return SHOP_ITEMS[id] end) end
  a.brecconary = WeaponAndArmorShop({Point(Brecconary, 5,  6)}, getShopItems(b))
  a.cantlin1   = WeaponAndArmorShop({Point(Cantlin,   20,  3),  Point(Cantlin, 20, 4), Point(Cantlin, 20, 5), Point(Cantlin, 20, 6)}, getShopItems(c1))
  a.cantlin2   = WeaponAndArmorShop({Point(Cantlin,   25, 26)}, getShopItems(c2))
  a.cantlin3   = WeaponAndArmorShop({Point(Cantlin,   26, 12)}, getShopItems(c3))
  a.garinham   = WeaponAndArmorShop({Point(Garinham,  10, 16)}, getShopItems(g))
  a.kol        = WeaponAndArmorShop({Point(Kol,       20, 12)}, getShopItems(k))
  a.rimuldar   = WeaponAndArmorShop({Point(Rimuldar,  23,  9)}, getShopItems(r))
end)

function WeaponAndArmorShops:__tostring()
  local res = "=== Weapon/Armor Shops ===\n"
  res = res .. "Brecconary: " .. tostring(self.brecconary) .. "\n"
  res = res .. "Cantlin 1: "  .. tostring(self.cantlin1)   .. "\n"
  res = res .. "Cantlin 2: "  .. tostring(self.cantlin2)   .. "\n"
  res = res .. "Cantlin 3: "  .. tostring(self.cantlin3)   .. "\n"
  res = res .. "Garinham: "   .. tostring(self.garinham)   .. "\n"
  res = res .. "Kol: "        .. tostring(self.kol)        .. "\n"
  res = res .. "Rimuldar: "   .. tostring(self.rimuldar)   .. "\n"
  return res
end

function WeaponAndArmorShops:getShopAt(location)
  function f(town) return list.exists(town.locations, location, function(l, r) return l:equals(r) end) end
  if f(self.brecconary) then return self.brecconary end
  if f(self.cantlin1) then return self.cantlin1 end
  if f(self.cantlin2) then return self.cantlin2 end
  if f(self.cantlin3) then return self.cantlin3 end
  if f(self.garinham) then return self.garinham end
  if f(self.kol) then return self.kol end
  if f(self.rimuldar) then return self.rimuldar end
  return nil
end

function WeaponAndArmorShops:visitShopAt(location)
  if self:getShopAt(location) ~= nil then
    self:getShopAt(location).seenByPlayer = true
  end
end

WeaponAndArmorShopsUpgrades = class(function(a, b, c1, c2, c3, g, k, r)
  a.brecconary = b
  a.cantlin1   = c1
  a.cantlin2   = c2
  a.cantlin3   = c3
  a.garinham   = g
  a.kol        = k
  a.rimuldar   = r
end)

function WeaponAndArmorShopsUpgrades:__tostring()
  local res = "=== Known Upgrades ===\n"
  function f(shop) if shop == nil then return "Unknown" else return tostring(shop) end end
  res = res .. "Brecconary: " .. f(self.brecconary) .. "\n"
  res = res .. "Cantlin 1: "  .. f(self.cantlin1)   .. "\n"
  res = res .. "Cantlin 2: "  .. f(self.cantlin2)   .. "\n"
  res = res .. "Cantlin 3: "  .. f(self.cantlin3)   .. "\n"
  res = res .. "Garinham: "   .. f(self.garinham)   .. "\n"
  res = res .. "Kol: "        .. f(self.kol)        .. "\n"
  res = res .. "Rimuldar: "   .. f(self.rimuldar)   .. "\n"
  return res
end

function WeaponAndArmorShops:getUpgrades(playerData, f)
  return WeaponAndArmorShopsUpgrades(
    f(self.brecconary),
    f(self.cantlin1),
    f(self.cantlin2),
    f(self.cantlin3),
    f(self.garinham),
    f(self.kol),
    f(self.rimuldar)
  )
end

function WeaponAndArmorShops:getAllKnownUpgrades(playerData)
  return self:getUpgrades(playerData, function(shop)
    if shop.seenByPlayer then return shop:getUpgrades(playerData.equipment) else return nil end
  end)
end

function WeaponAndArmorShops:getAllKnownAffordableUpgrades(playerData)
  return self:getUpgrades(playerData, function(shop)
    if shop.seenByPlayer then return shop:getAffordableUpgrades(playerData) else return nil end
  end)
end


-- Additional shops

-- typedef enum {
-- ... 0-16 is weapon/armor/shield data ...
-- 17?    SHOP_HERB,
-- 19    SHOP_TORCH = 0x13,
-- 21    SHOP_WINGS = 0x15,
-- 22?    SHOP_DRAGON_SCALE,
--     SHOP_END = 0xfd,
-- } dw_shop_item;

-- == Point(Garinham 3, 11)
-- Can buy herb, torch, dragon scale

-- == Point(Cantlin 4, 7)
-- Can buy herb, torch

-- == Point(Kol 12, 21)
-- Can buy herb, torch, dragonscale, wings

-- FAIRY WATER:
-- == Point(Cantlin 20, 13)
-- == Point(Brecconary, 22, 3-5) (girl moves around)
-- Can buy fairy water

-- KEYS:
-- == Point(Cantlin 27, 8)
-- == Point(Rimuldar 23, 9)
-- Can buy magic keys

-- 1957 - 1992 | Weapon & Item costs (calculation) |
-- 19A1-19CB   | Weapon Shop Inventory             |
-- 19CC - 19DE | Item Shop Inventory               |
-- 5DDD - 5E58 | Chest Data                        | Four bytes long: Map,X,Y,Contents

-- this is also used for search spots.
CHEST_CONTENT = {
 [1]  = ErdricksArmor,
 [2]  = Herb,
 [3]  = MagicKey,
 [4]  = Torch,
 [5]  = FairyWater,
 [6]  = Wings,
 [7]  = DragonScale,
 [8]  = FairyFlute,
 [9]  = FightersRing,
 [10] = ErdricksToken,
 [11] = GwaelinsLove,
 [12] = CursedBelt,
 [13] = SilverHarp,
 [14] = DeathNecklace,
 [15] = StonesOfSunlight,
 [16] = StaffOfRain,
 [17] = ErdricksSword,
 [18] = "Gold" -- todo: umm... how much gold?
}

Chest = class(function(a,location,item)
  a.location = location
  a.item = item
  a.currentlyOpen = false
  a.everOpened = false
end)

function Chest:__tostring()
  return "Chest at " .. tostring(self.location)
    .. " contains " .. tostring(self.item == nil and "Nothing" or self.item)
    .. " (open now: " .. tostring(self.currentlyOpen) .. ")"
    .. " (opened ever: " .. tostring(self.everOpened) .. ")"
end

-- chests :: [Chest]
-- returns Map MapId [Chest]
function getChestsByMapId(chests)
  local res = {}
  for i = 2, 29 do res[i] = {} end
  for i = 1,31 do
    table.insert(res[chests[i].location.mapId], c)
  end
  return res
end

Chests = class(function(a,chests)
  -- chests :: [Chest]
  a.chests = chests
  -- chestsByMapId :: Map MapId [Chest]
  a.chestsByMapId = getChestsByMapId(chests)
end)

function Chests:foreach(f)
  for i = 1,31 do f(self.chests[i]) end
end

function Chests:__tostring()
  local res = "=== Chests ===\n"
  self.chests:foreach(function (c)
    res = res .. "  " .. tostring(c) .. "\n"
  end)
  return res
end

function Chests:isChestOpen(location)
  log.debug("isChestOpen", location)
  return self:chestAt(location).currentlyOpen
end

function Chests:chestAt(location)
  local f = list.find(self.chests, function (c) return c.location:equals(location) end)
  if f == nil then
    local msg = "No chest at location"
    log.debug(msg, location)
    error(msg, location)
  end
  return f
end

function Chests:hasChestEverBeenOpened(location)
  log.debug("hasChestEverBeenOpened", location)
  return self:chestAt(location).everOpened
end

function Chests:openChestAt(location)
  log.debug("openChestAt", location)
  local c = self:chestAt(location)
  c.currentlyOpen = true
  c.everOpened = true
end

function Chests:closeAll()
  -- log.debug("Closing all chests!")
  self:foreach(function (c) c.currentlyOpen = false end)
end

-- get all the chests that we have seen
-- but have never been opened
function Chests:getAllChestsThatWeveSeenButNeverOpened(staticMaps)
  -- log.debug("getAllChestsThatWeveSeenButNeverOpened!")
  local res = {}

  for i,chest in pairs(self.chests) do
    -- log.debug("getAllChestsThatWeveSeenButNeverOpened", i, "chest", self.chests[i], "map seen", staticMaps[self.chests[i].location.mapId].seenByPlayer)
    if (not self.chests[i].everOpened) and staticMaps[self.chests[i].location.mapId].seenByPlayer then
      -- log.debug("there's a chest we could go to at: ", chest.location)
      table.insert(res, self.chests[i])
    end
  end

  return res
end

SearchSpot = class(function(a,location,item)
  a.location = location
  a.item = item
  a.seenByPlayer = false
end)

function SearchSpot:__tostring()
  return "  Search spot at " .. tostring(self.location)
    .. " contains " .. tostring(self.item == nil and "Nothing" or self.item)
    .. " (seen: " .. tostring(self.seenByPlayer) .. ")"
end

-- Erdrick’s Sword, Erdrick’s Armor, Erdrick’s Token, the Stones of Sunlight, the Silver Harp,
-- the Fairy Flute, or the Death Necklace could be placed on a search spot.
-- If the search item is the Death Necklace, the tile can be repeatedly searched to claim 100-120 G per search.
SearchSpots = class(function(a,coordinates,kol,hauksness)
  a.coordinates = coordinates
  a.kol = kol
  a.hauksness = hauksness
end)

function SearchSpots:__tostring()
  local res = "=== Search Spots ===\n"
  res = res .. tostring(self.coordinates) .. "\n"
  res = res .. tostring(self.kol) .. "\n"
  res = res .. tostring(self.hauksness) .. "\n"
  return res
end

-- TODO: we have to check if we are on the coordinates here!
function SearchSpots:searchAt(loc)
  if loc:equals(Point(Kol, 9, 6))
    then self.kol.seenByPlayer = true
  elseif loc:equals(Point(Hauksness, 18, 12))
    then self.hauksness.seenByPlayer = true
  else return
  end
end

-- TODO: i think i want to make Inns a class.
-- would just need their location and cost
-- Inn costs
  -- brecconary 6
  -- kol 20
  -- garinham 25
  -- rimuldar 55
  -- cantlin 100

