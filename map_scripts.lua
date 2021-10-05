require 'Class'
enum = require("enum")
require 'static_maps'

Script = class(function(a, name, body) a.name = name end)
function Script:__tostring() return self.name end

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

PressButtonScript = class(Script, function(a, button)
  Script.init(a, button.name)
  a.button = button
end)

PressA      = PressButtonScript(Buttons.A)
PressB      = PressButtonScript(Buttons.B)
PressUp     = PressButtonScript(Buttons.up)
PressDown   = PressButtonScript(Buttons.down)
PressLeft   = PressButtonScript(Buttons.left)
PressRight  = PressButtonScript(Buttons.right)
PressSelect = PressButtonScript(Buttons.select)
PressStart  = PressButtonScript(Buttons.start)

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

KingOpening   = ActionScript("KING_OPENING_GAME")
DoNothing     = ActionScript("DO_NOTHING")
OpenChest     = ActionScript("OPEN_CHEST")
Search        = ActionScript("SEARCH")
Stairs        = ActionScript("STAIRS")
DeathWarp     = ActionScript("DEATH_WARP")
SavePrincess  = ActionScript("RESCUE_PRINCESS")
DragonLord    = ActionScript("DRAGONLORD")
Save          = ActionScript("SAVE")
CastReturn    = ActionScript("CAST_RETURN")
CastOutside   = ActionScript("CAST_OUTSIDE")
UseWings      = ActionScript("USE_WINGS")
TalkToOldMan  = ActionScript("TALK_TO_OLD_MAN")
ShopKeeper    = ActionScript("TALK_TO_SHOP_KEEPER")
InnKeeper     = ActionScript("TALK_TO_INN_KEEPER")

ConditionScript = class(Script, function(a, name) Script.init(a, name) end)

LeftThroneRoom = ConditionScript("LEFT_THRONEROOM")
HaveKeys       = ConditionScript("HAVE_KEYS")
HaveWings      = ConditionScript("HAVE_WINGS")
HaveReturn     = ConditionScript("HAVE_RETURN")
HaveOutside    = ConditionScript("HAVE_OUTSIDE")
HaveHarp       = ConditionScript("HAVE_HARP")
HaveToken      = ConditionScript("HAVE_TOKEN")
HaveStones     = ConditionScript("HAVE_STONES")
HaveStaff      = ConditionScript("HAVE_STAFF")
NeedKeys       = ConditionScript("NEED_KEYS")

AtLocation    = class(ConditionScript, function(a, mapId, x, y)
  ConditionScript.init(a, "AT_LOCATION")
  a.location = Point(mapId, x, y)
end)

function AtLocation:__tostring()
  return self.name .. ": " .. tostring(self.location)
end

IsChestOpen    = class(ConditionScript, function(a, location)
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

HaveGold = class(ConditionScript, function(a, minAmountOfGold)
  ConditionScript.init(a, "HAVE_N_GOLD")
  a.minAmountOfGold = minAmountOfGold
end)

function HaveGold:__tostring()
  return self.name .. ": " .. tostring(self.minAmountOfGold)
end

HaveKeys = class(ConditionScript, function(a, minAmountOfKeys)
  ConditionScript.init(a, "HAVE_N_KEYS")
  a.minAmountOfKeys = minAmountOfKeys
end)

function HaveKeys:__tostring()
  return self.name .. ": " .. tostring(self.minAmountOfKeys)
end

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

IfScript = class(Script, function(a, name, condition, trueBranch, falseBranch)
  Script.init(a, name)
  a.condition = condition
  a.trueBranch = trueBranch
  a.falseBranch = falseBranch
end)

-- TODO: we need to do indent level stuff here, but right now i dont feel like it.
function IfScript:__tostring()
  local res = self.name .. ":\n"
  res = res .. "  Condition " .. tostring(self.condition) .. "\n"
  res = res .. "    True Branch: "  .. tostring(self.trueBranch) .. "\n"
  res = res .. "    False Branch: " .. tostring(self.falseBranch) .. "\n"
  return res
end

ListScript = class(Script, function(a, name, scripts)
  Script.init(a, name)
  a.scripts = scripts
end)

-- TODO: we need to do indent level stuff here, but right now i dont feel like it.
function ListScript:__tostring()
  local res = self.name .. ":\n"
  for i,s in pairs(self.scripts) do
    res = res .. "  " .. tostring(s) .. "\n"
  end
  return res
end

Scripts = class(function(a,mem)

  coordinates = getAllOverworldCoordinates(mem)

  function VisitShop(mapId, x, y)
    return ListScript("Visiting shop at: " .. tostring(Point(mapId, x, y)), {Goto(mapId, x, y), ShopKeeper})
  end

  function VisitInn(mapId, x, y)
    return ListScript("Visiting inn at: " .. tostring(Point(mapId, x, y)), {Goto(mapId, x, y), InnKeeper})
  end

  function SearchAt(mapId, x, y)
    return ListScript("Searching at: " .. tostring(Point(mapId, x, y)), {Goto(mapId, x, y), Search})
  end

  function Consecutive(name, scripts)
    return ListScript(name, scripts)
  end

  function IfHaveKeys(name, t, f)
    return IfScript(name, HaveKeys, t, f)
  end

  function OpenChestAt(mapId, x, y)
    local loc = Point(mapId, x, y)
    return IfScript("Test if chest is open at " .. tostring(loc),
       IsChestOpen(loc),
       DoNothing,
       ListScript("Opening Chest at: " .. tostring(loc), {Goto(mapId, x, y), OpenChest})
     )
  end

  function GotoPoint(p)
    return Goto(p.mapId, p.x, p.y)
  end

  function GotoOverworld(fromMap)
    local p = coordinates[fromMap][1]
    return Goto(p.mapId, p.x, p.y)
  end

  openMenu = Consecutive("Open Menu", { HoldA(30), WaitFrames(10) })
  talk = Consecutive("Talk", { HoldA(30), WaitFrames(10), PressA })

  function LeaveDungeon(mapId)
    return IfScript(
      "Figure out how to leave map: " .. tostring(mapId),
      HaveOutside,
      CastOutside,
      GotoOverworld(mapId)
    )
  end

  saveWithKingScript =
    Consecutive("Leaving Throne room via wings", {
      Goto(TantegelThroneRoom, 3, 4), Save
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
      Goto(Hauksness, 18, 12),
      Search,
      GotoOverworld(Hauksness)
    })

  exploreCharlockThroneRoom =
    Consecutive("Charlock Throne Room", {
      Goto(CharlockThroneRoom, 17, 24),
      DragonLord
    })

  exploreCharlock =
    Consecutive("Charlock", {
      Goto(Charlock, 10, 1),
      Search,
      Stairs,
      Goto(CharlockThroneRoom, 10, 29),
      exploreCharlockThroneRoom
    })

  northernShrineScript =
    IfScript(
      "Do we have the harp?",
      HaveHarp,
      Consecutive("Get Staff", {
        Goto(NorthernShrine, 5, 4),
        Consecutive("Talk to old man", { talk, HoldA(60), PressB }),
        OpenChestAt(NorthernShrine, 3, 4),
        Goto(NorthernShrine, 4, 9),
        Stairs
      }),
      Stairs
    )

  southernShrineScript =
    IfScript(
      "Do we have the staff, stones and token?",
      All ({ HaveStaff, HaveStones, HaveToken }),
      Consecutive("Talk to old man", {
        Goto(SouthernShrine, 3, 5),
        TalkToOldMan,
        GotoOverworld(SouthernShrine)
      }),
      Stairs
    )

  garinhamScript =
    Consecutive("Garinham", {
      IfHaveKeys("If we have keys...",
        Consecutive("Get chests and go down stairs in Garinham.", {
          OpenChestAt(Garinham, 8, 6),
          OpenChestAt(Garinham, 8, 5),
          OpenChestAt(Garinham, 9, 5),
          Goto(Garinham, 19, 0),
          Stairs
        })
      ),
    })

  leaveTantegalOnFoot =
    Consecutive("Leaving Throne room via legs", {GotoOverworld(Tantegel)})

  leaveThroneRoomScript =
    IfScript(
      "Figure out how to leave throne room",
      HaveReturn,
      Consecutive("Leaving Throne room via return", {aveWithKingScript, CastReturn}),
      IfScript(
        "Check to leave throne room with wings",
        HaveWings,
        Consecutive("Leaving Throne room via wings", {saveWithKingScript, UseWings}),
        leaveTantegalOnFoot
      )
    )

  throneRoomScript =
    IfScript(
      "Have we ever left the throne room? If not, must be starting the game.",
      Not(LeftThroneRoom),
      Consecutive("Tantagel Throne Room Opening Game", {
        -- we should already be here...but, when i monkey around its better to have this.
        Goto(TantegelThroneRoom, 3, 4),
        HoldUp(30),
        KingOpening,
        OpenChestAt(TantegelThroneRoom, 4, 4),
        OpenChestAt(TantegelThroneRoom, 5, 4),
        OpenChestAt(TantegelThroneRoom, 6, 1),
        leaveThroneRoomScript
      }),
      -- We probably died, and need to resume doing whatever it was we were last doing.
      -- So it seems like we need some sort of goal system in order to be able to resume.
      leaveTantegalOnFoot
    )

  -- TODO: add static  npc to basement and fix this up
  tantegelBasementShrine =
    Consecutive("TantegelBasement (Free cave)", {
      Goto(TantegelBasement, 5, 7),
      Goto(TantegelBasement, 5, 5),
      OpenChestAt(TantegelBasement, 4, 5),
      Goto(TantegelBasement, 5, 5),
      Goto(TantegelBasement, 5, 7),
      Goto(TantegelBasement, 0, 4),
      Stairs
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
      IfScript("Do we need keys?", All(NeedKeys, HaveGold(53)),
        Consecutive("Buy Keys in Rimuldar", {Goto(Rimuldar, 4, 5), ShopKeeper}),
        DoNothing
      ),
      IfScript("Do we have two?", All(HaveKeys(2), HasChestEverBeenOpened(Rimuldar, 24, 23)),
        Consecutive("Get chest Rimuldar", {Goto(Rimuldar, 24, 23), OpenChest}),
        DoNothing
      )
    })

  -- TODO: a lot of work needs to be done on this script
  swampCave =
    IfScript(
      "Are we at swamp north?",
      AtLocation(SwampCave, 0, 0),
      Consecutive("Go to swamp south and exit", {
        Goto(SwampCave, 0, 29), Stairs
      }),
      -- TODO: we could just cast Outside from here.
      Consecutive("Go to swamp north and exit", {
        Goto(SwampCave, 0, 0), Stairs
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
end)
