require 'Class'
enum = require("enum")
require 'player_data'
require 'static_maps'

Script = class(function(a, name, body) a.name = name end)
function Script:__tostring() return self.name end

Value = class(Script, function(a, v)
  Script.init(a, "(Value " .. tostring(i) .. ")")
  a.v = v
end)

DebugScript = class(Script, function(a, msg) Script.init(a, msg) end)

Goto = class(Script, function(a, mapId, x, y)
  Script.init(a, "Goto")
  a.location = Point(mapId, x, y)
end)

function Goto:__tostring()
  return self.name .. ": " .. tostring(self.location)
end

Buttons = enum.new("Scripts to press buttons", {
  "A",
  "B",
  "up",
  "down",
  "left",
  "right",
  "select",
  "start",
})

WaitFrames = class(Script, function(a, duration)
  Script.init(a, "Wait frames (" .. duration .. ")")
  a.duration = duration
end)

PressButtonScript = class(Script, function(a, button, waitFrames)
  Script.init(a, button.name)
  a.button = button
  a.waitFrames = waitFrames
end)

function PressA(waitFrames)      return PressButtonScript(Buttons.A, waitFrames) end
function PressB(waitFrames)      return PressButtonScript(Buttons.B, waitFrames) end
function PressUp(waitFrames)     return PressButtonScript(Buttons.up, waitFrames) end
function PressDown(waitFrames)   return PressButtonScript(Buttons.down, waitFrames) end
function PressLeft(waitFrames)   return PressButtonScript(Buttons.left, waitFrames) end
function PressRight(waitFrames)  return PressButtonScript(Buttons.right, waitFrames) end
function PressSelect(waitFrames) return PressButtonScript(Buttons.select, waitFrames) end
function PressStart(waitFrames)  return PressButtonScript(Buttons.start, waitFrames) end

HoldButtonScript = class(Script, function(a, button, duration)
  Script.init(a, button.name)
  a.button = button
  a.duration = duration
end)

function HoldA     (duration) return HoldButtonScript(Buttons.A, duration) end
function HoldB     (duration) return HoldButtonScript(Buttons.B, duration) end
function HoldUp    (duration) return HoldButtonScript(Buttons.up, duration) end
function HoldDown  (duration) return HoldButtonScript(Buttons.down, duration) end
function HoldLeft  (duration) return HoldButtonScript(Buttons.left, duration) end
function HoldRight (duration) return HoldButtonScript(Buttons.right, duration) end
function HoldSelect(duration) return HoldButtonScript(Buttons.select, duration) end
function HoldStart (duration) return HoldButtonScript(Buttons.start, duration) end

ActionScript = class(Script, function(a, name)
  Script.init(a, name)
end)

DoNothing      = ActionScript("DO_NOTHING")
OpenChest      = ActionScript("OPEN_CHEST")
Search         = ActionScript("SEARCH")
DeathWarp      = ActionScript("DEATH_WARP")
SavePrincess   = ActionScript("RESCUE_PRINCESS")
DragonLord     = ActionScript("DRAGONLORD")
TalkToOldMan   = ActionScript("TALK_TO_OLD_MAN")
ShopKeeper     = ActionScript("TALK_TO_SHOP_KEEPER")
InnKeeper      = ActionScript("TALK_TO_INN_KEEPER")

SaveUnlockedDoor = class(ActionScript, function(a, loc)
  ActionScript.init(a, "SAVE_UNLOCKED_DOOR: " .. tostring(loc))
  a.loc = loc
end)

UseItem = class(ActionScript, function(a, item)
  ActionScript.init(a, "UseItem: " .. tostring(item))
  a.item = item
end)

CastSpell = class(ActionScript, function(a, spell)
  ActionScript.init(a, "CastSpell: " .. tostring(spell))
  a.spell = spell
end)

ConditionScript = class(Script, function(a, name) Script.init(a, name) end)

function AtLocation(location) return DotEq(GetLocation, location) end

IsChestOpen = class(ConditionScript, function(a, location)
  ConditionScript.init(a, "IS_CHEST_OPEN")
  a.location = location
end)

function IsChestOpen:__tostring()
  return self.name .. ": " .. tostring(self.location)
end

HasChestEverBeenOpened = class(ConditionScript, function(a, location)
  ConditionScript.init(a, "HAS_CHEST_EVER_BEEN_OPENED")
  a.location = location
end)

function HasChestEverBeenOpened:__tostring()
  return self.name .. ": " .. tostring(self.location)
end

IsDoorOpen = class(ConditionScript, function(a, location)
  ConditionScript.init(a, "IS_DOOR_OPEN")
  a.location = location
end)

function IsDoorOpen:__tostring()
  return self.name .. ": " .. tostring(self.location)
end

BinaryOperator = class(ConditionScript, function(a, name, l, r)
  ConditionScript.init(a, tostring(l) .. " " .. name .. " " .. tostring(r))
  a.location = location
  a.l = l
  a.r = r
end)

Eq = class(BinaryOperator, function(a, l, r)
  BinaryOperator.init(a, "==", l, r)
  a.l = l
  a.r = r
end)

DotEq = class(BinaryOperator, function(a, l, r)
  BinaryOperator.init(a, "equals", l, r)
  a.l = l
  a.r = r
end)

NotEq = class(BinaryOperator, function(a, l, r)
  BinaryOperator.init(a, "!=", l, r)
  a.l = l
  a.r = r
end)

Lt = class(BinaryOperator, function(a, l, r)
  BinaryOperator.init(a, "<", l, r)
  a.l = l
  a.r = r
end)

LtEq = class(BinaryOperator, function(a, l, r)
  BinaryOperator.init(a, "<=", l, r)
  a.l = l
  a.r = r
end)

Gt = class(BinaryOperator, function(a, l, r)
  BinaryOperator.init(a, ">", l, r)
  a.l = l
  a.r = r
end)

GtEq = class(BinaryOperator, function(a, l, r)
  BinaryOperator.init(a, ">=", l, r)
  a.l = l
  a.r = r
end)

Any = class(ConditionScript, function(a, conditions)
  ConditionScript.init(a, "ANY")
  a.conditions = conditions
end)

function Any:__tostring()
  local res = "ANY of:\n"
  for i,s in pairs(self.conditions) do
    res = res .. "  " .. tostring(s) .. "\n"
  end
  return res
end

All = class(ConditionScript, function(a, conditions)
  ConditionScript.init(a, "ALL")
  a.conditions = conditions
end)

function All:__tostring()
  local res = "All of:\n"
  for i,s in pairs(self.conditions) do
    res = res .. "  " .. tostring(s) .. "\n"
  end
  return res
end

Not = class(ConditionScript, function(a, condition)
  ConditionScript.init(a, "NOT")
  a.condition = condition
end)

function Not:__tostring()
  return "NOT: " .. tostring(self.condition)
end

Contains = class(ConditionScript, function(a, container, v)
  ConditionScript.init(a, "CONTAINS" .. tostring(v))
  a.container = container
  a.v = v
end)

function HaveItem(i) return Contains(GetItems, i) end
function HaveSpell(s) return Contains(GetSpells, s) end

PlayerDataScript = class(Script, function(a, name, playerDataF)
  Script.init(a, name)
  a.playerDataF = playerDataF
end)

GetNrKeys   = PlayerDataScript("Number of magic keys player has.", function(pd) return pd.items.nrKeys end)
GetGold     = PlayerDataScript("Amount of gold player has.", function(pd) return pd.stats.gold end)
GetLocation = PlayerDataScript("Location of player", function(pd) return pd.stats.gold end)
GetItems    = PlayerDataScript("Player's Items", function(pd) return pd.items end)
GetSpells   = PlayerDataScript("Player's Spells", function(pd) return pd.spells end)
GetStatuses = PlayerDataScript("Game statuses", function(pd) return pd.statuses end)

function StatusScript(statusFld)
  return PlayerDataScript("Status: " .. statusFld, function(pd) return pd.statuses[statusFld] end)
end

IfThenScript = class(Script, function(a, name, condition, trueBranch, falseBranch)
  Script.init(a, name)
  a.condition = condition
  a.trueBranch = trueBranch
  a.falseBranch = falseBranch
end)

-- TODO: we need to do indent level stuff here, but right now i dont feel like it.
function IfThenScript:__tostring()
  local res = self.name .. ":\n"
  res = res .. "  Condition " .. tostring(self.condition) .. "\n"
  res = res .. "    True Branch: "  .. tostring(self.trueBranch) .. "\n"
  res = res .. "    False Branch: " .. tostring(self.falseBranch) .. "\n"
  return res
end

Consecutive = class(Script, function(a, name, scripts)
  Script.init(a, name)
  a.scripts = scripts
end)

-- TODO: we need to do indent level stuff here, but right now i dont feel like it.
function Consecutive:__tostring()
  local res = self.name .. ":\n"
  for i,s in pairs(self.scripts) do
    res = res .. "  " .. tostring(s) .. "\n"
  end
  return res
end

Scripts = class(function(a,mem)

  coordinates = getAllOverworldCoordinates(mem)

  charlockLocation = coordinates[Charlock][1]
  a.tantegelLocation = coordinates[Tantegel][1]
--   print("charlockLocation", charlockLocation)
--   print("tantegelLocation", a.tantegelLocation)


  function VisitShop(mapId, x, y)
    return Consecutive("Visiting shop at: " .. tostring(Point(mapId, x, y)), {Goto(mapId, x, y), ShopKeeper})
  end

  function VisitInn(mapId, x, y)
    return Consecutive("Visiting inn at: " .. tostring(Point(mapId, x, y)), {Goto(mapId, x, y), InnKeeper})
  end

  OpenMenu = Consecutive("Open Menu", { HoldA(30), WaitFrames(10) })
  OpenItemMenu = Consecutive("Open Item Menu", { OpenMenu, PressRight(2), PressDown(2), PressA(2), WaitFrames(30) })
  OpenSpellMenu = Consecutive("Open Spell Menu", { OpenMenu, PressRight(2), PressA(2), WaitFrames(30) })
  Talk = Consecutive("Talk", { HoldA(30), WaitFrames(10), PressA(2) })
  TakeStairs = Consecutive("Take Stairs", { OpenMenu, HoldDown(2), HoldDown(2), HoldA(60) })

  function OpenDoor(loc)
   return IfThenScript(
      "If the door open at: " .. tostring(loc) .. ", then open it.",
      IsDoorOpen(loc),
      DoNothing,
      Consecutive("Open Door", {
        OpenMenu, PressDown(2), PressDown(2), PressRight(2), PressA(20), SaveUnlockedDoor(loc)
      })
    )
  end

  function SearchAt(mapId, x, y)
    return Consecutive("Searching at: " .. tostring(Point(mapId, x, y)), {
      Goto(mapId, x, y),
      OpenMenu,
      PressUp(2),
      PressA(40),
      Search
    })
  end

  TakeStairs = Consecutive("Taking stairs", {
    OpenMenu,
    PressDown(2),
    PressDown(2),
    PressA(60),
  })

  function IfHaveKeys(name, t, f)
    return IfThenScript(name, Gt(GetNrKeys, Value(2)), t, f)
  end

  openChestMenuing = Consecutive("Menuing for opening Chest at",
    { OpenMenu, PressUp(2), PressRight(2), HoldA(40), OpenChest }
  )

  function OpenChestAt(mapId, x, y)
    local loc = Point(mapId, x, y)
    return IfThenScript("Test if chest is open at " .. tostring(loc),
       IsChestOpen(loc),
       DoNothing,
       Consecutive("Opening Chest at: " .. tostring(loc), { Goto(mapId, x, y), openChestMenuing })
     )
  end

  function GotoPoint(p)
    return Goto(p.mapId, p.x, p.y)
  end

  function GotoOverworld(fromMap)
    local p = coordinates[fromMap][1]
    return Goto(p.mapId, p.x, p.y)
  end

  function LeaveDungeon(mapId)
    return IfThenScript(
      "Figure out how to leave map: " .. tostring(mapId),
      HaveSpell(Outside),
      CastSpell(Outside),
      GotoOverworld(mapId)
    )
  end

  GameStartMenuScript = Consecutive("Game start menu", {
    PressStart(30),
    PressStart(30),
    PressA(30),
    PressA(30),
    PressDown(10),
    PressDown(10),
    PressRight(10),
    PressRight(10),
    PressRight(10),
    PressA(30),
    PressDown(10),
    PressDown(10),
    PressDown(10),
    PressRight(10),
    PressRight(10),
    PressRight(10),
    PressRight(10),
    PressA(30),
    PressUp(30),
    PressA(30),
  })

  saveWithKingScript =
    Consecutive("Leaving Throne room via wings", {
      Goto(TantegelThroneRoom, 3, 4), OpenMenu, HoldA(180), PressB(2)
    })

  exploreGraveScript =
    Consecutive("Garin's Grave", {
      OpenChestAt(GarinsGraveLv1, 13, 0),
      OpenChestAt(GarinsGraveLv1, 12, 0),
      OpenChestAt(GarinsGraveLv1, 11, 0),
      IfHaveKeys("If we have keys, Search Bottom Of Grave",
        Consecutive("Search Bottom Of Grave", {OpenChestAt(GarinsGraveLv3, 13, 6), LeaveDungeon(GarinsGraveLv1)}),
        LeaveDungeon(GarinsGraveLv1)
      ),
    })

  exploreMountainCaveScript =
    Consecutive("Mountain Cave", {
      OpenChestAt(MountainCaveLv1, 13, 5),
      OpenChestAt(MountainCaveLv2, 3, 2),
      OpenChestAt(MountainCaveLv2, 2, 2),
      OpenChestAt(MountainCaveLv2, 10, 9),
      OpenChestAt(MountainCaveLv2, 1, 6),
      LeaveDungeon(MountainCaveLv1)
    })

  exploreErdricksCaveScript =
    Consecutive("Erdrick's Cave", {
      OpenChestAt(ErdricksCaveLv2, 9, 3),
      LeaveDungeon(ErdricksCaveLv1)
    })

  exploreHauksness =
    Consecutive("Hauksness", {
      SearchAt(Hauksness, 18, 12),
      GotoOverworld(Hauksness)
    })

  EnterCharlock =
    IfThenScript(
      "Have we already created the rainbow bridge?",
      StatusScript("rainbowBridge"),
      GotoPoint(charlockLocation),
      IfThenScript(
        "Do we have the rainbow drop?",
        HaveItem(RainbowDrop),
        Consecutive("Enter Charlock", {
          Goto(OverWorldId, charlockLocation.x + 3, charlockLocation.y),
          UseItem(RainbowDrop),
          GotoPoint(charlockLocation)
        }),
        DoNothing
      )
    )

  exploreCharlockThroneRoom =
    Consecutive("Charlock Throne Room", {
      Goto(CharlockThroneRoom, 17, 24),
      DragonLord
    })

  exploreCharlock =
    Consecutive("Charlock", {
      SearchAt(Charlock, 10, 1),
      TakeStairs,
      Goto(CharlockThroneRoom, 10, 29),
      exploreCharlockThroneRoom
    })

  northernShrineScript =
    IfThenScript(
      "Do we have the harp?",
      HaveItem(SilverHarp),
      Consecutive("Get Staff", {
        Goto(NorthernShrine, 5, 4),
        Consecutive("Talk to old man", { Talk, HoldA(60), PressB }),
        OpenChestAt(NorthernShrine, 3, 4),
        Goto(NorthernShrine, 4, 9),
        TakeStairs
      }),
      TakeStairs
    )

  southernShrineScript =
    IfThenScript(
      "Do we have the staff, stones and token?",
      All ({ HaveItem(StaffOfRain), HaveItem(StonesOfSunlight), HaveItem(ErdricksToken) }),
      Consecutive("Talk to old man", {
        Goto(SouthernShrine, 3, 5),
        TalkToOldMan,
        GotoOverworld(SouthernShrine)
      }),
      TakeStairs
    )

  garinhamScript =
    Consecutive("Garinham", {
      IfHaveKeys("If we have keys...",
        Consecutive("Get chests and go down stairs in Garinham.", {
          OpenChestAt(Garinham, 8, 6),
          OpenChestAt(Garinham, 8, 5),
          OpenChestAt(Garinham, 9, 5),
          Goto(Garinham, 19, 0),
          TakeStairs
        })
      ),
    })

  leaveTantegalOnFoot =
    Consecutive("Leaving Throne room via legs", {GotoOverworld(Tantegel)})

  leaveThroneRoomScript =
    IfThenScript(
      "Figure out how to leave throne room",
      HaveSpell(Return),
      Consecutive("Leaving Throne room via return", {saveWithKingScript, CastSpell(Return)}),
      IfThenScript(
        "Check to leave throne room with wings",
        HaveItem(Wings),
        Consecutive("Leaving Throne room via wings", {saveWithKingScript, UseItem(Wings)}),
        leaveTantegalOnFoot
      )
    )

  throneRoomScript =
    IfThenScript(
      "Have we ever left the throne room? If not, must be starting the game.",
      Not(StatusScript("leftThroneRoom")),
      Consecutive("Tantagel Throne Room Opening Game", {
        -- we should already be here...but, when i monkey around its better to have this.
        Goto(TantegelThroneRoom, 3, 4),
        HoldUp(30), -- this makes sure we are looking at the king
        HoldA(250), -- this talks to the king
        OpenChestAt(TantegelThroneRoom, 4, 4),
        OpenChestAt(TantegelThroneRoom, 5, 4),
        OpenChestAt(TantegelThroneRoom, 6, 1),
        leaveThroneRoomScript
      }),
      -- We probably died, and need to resume doing whatever it was we were last doing.
      -- So it seems like we need some sort of goal system in order to be able to resume.
      leaveTantegalOnFoot
    )

  -- TODO: add static npc to basement and fix this up
  tantegelBasementShrine =
    Consecutive("TantegelBasement (Free cave)", {
      Goto(TantegelBasement, 5, 7),
      Goto(TantegelBasement, 5, 5),
      OpenChestAt(TantegelBasement, 4, 5),
      Goto(TantegelBasement, 5, 5),
      Goto(TantegelBasement, 5, 7),
      Goto(TantegelBasement, 0, 4),
      TakeStairs
    })

  kol =
    Consecutive("Kol", {
      VisitShop(Kol, 20, 12),
      SearchAt(Kol, 9, 6),
      VisitInn(Kol, 19, 2),
      VisitShop(Kol, 12, 21)
    })

  rimuldar =
    Consecutive("Rimuldar", {
      IfThenScript("Do we need keys?", All(NeedKeys, GtEq(GetGold, Value(53))),
        Consecutive("Buy Keys in Rimuldar", {Goto(Rimuldar, 4, 5), ShopKeeper}),
        DoNothing
      ),
      IfThenScript("Do we have two keys?", All(GtEq(GetNrKeys, Value(2)), Not(HasChestEverBeenOpened(Rimuldar, 24, 23))),
        Consecutive("Get chest Rimuldar", {Goto(Rimuldar, 24, 23), OpenChest}),
        DoNothing
      )
    })

  -- TODO: a lot of work needs to be done on this script
  swampCave =
    IfThenScript(
      "Are we at swamp north?",
      AtLocation(SwampCave, 0, 0),
      Consecutive("Go to swamp south and exit", {
        Goto(SwampCave, 0, 29), TakeStairs
      }),
      -- TODO: we could just cast Outside from here.
      Consecutive("Go to swamp north and exit", {
        Goto(SwampCave, 0, 0), TakeStairs
      })
    )

  cantlin = VisitShop(Cantlin, 25, 26)

  -- This is for maps that we don't really need a script for
  -- because they are handled by the first floor of the map, basically.
  -- for example in ErdricksCaveLv1, we just say { OpenChestAt(ErdricksCaveLv2, 9, 3), Exit }
  -- there just isn't a case were we need a script for ErdricksCaveLv2
  -- the only reason i could potentially ever needing one is like...
  -- the script crashes, and we have to restart it and we happen to be in an NA map.
  -- but... eh.
  NA = nil

  a.MapScripts = {
    [Charlock] = exploreCharlock,
    [Hauksness] = exploreHauksness,
    -- TODO we will need to have more here, but its not terrible for now.
    [Tantegel] = leaveTantegalOnFoot,
    -- todo this one is kinda broken. i need to see why im in the room
    -- is it my first time there? or did i walk in there to save? or did i just die?
    [TantegelThroneRoom] = throneRoomScript,
    [CharlockThroneRoom] = exploreCharlockThroneRoom,
    [Kol] = kol,
    [Brecconary] = nil,
    [Garinham] = garinhamScript,
    [Cantlin] = cantlin,
    [Rimuldar] = rimuldar,
    [TantegelBasement] = tantegelBasementShrine,
    [NorthernShrine] = northernShrineScript,
    [SouthernShrine] = southernShrineScript,
    [CharlockCaveLv1] = NA,
    [CharlockCaveLv2] = NA,
    [CharlockCaveLv3] = NA,
    [CharlockCaveLv4] = NA,
    [CharlockCaveLv5] = NA,
    [CharlockCaveLv6] = NA,
    [SwampCave] = swampCave,
    [MountainCaveLv1] = exploreMountainCaveScript,
    [MountainCaveLv2] = NA,
    [GarinsGraveLv1] = exploreGraveScript,
    [GarinsGraveLv2] = NA,
    [GarinsGraveLv3] = GotoOverworld(GarinsGraveLv1),
    [GarinsGraveLv4] = NA,
    [ErdricksCaveLv1] = exploreErdricksCaveScript,
    [ErdricksCaveLv2] = NA,
  }

  a.OpenMenu = OpenMenu
  a.OpenItemMenu = OpenItemMenu
  a.OpenSpellMenu = OpenSpellMenu
  a.OpenChestAt = OpenChestAt
  a.OpenDoor = OpenDoor
  a.TakeStairs = TakeStairs
  a.EnterCharlock = EnterCharlock
  a.GameStartMenuScript = GameStartMenuScript
end)
