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
LeaveTantegel = ActionScript("LEAVE_TANTEGEL_OPENING_GAME")
DoNothing     = ActionScript("DO_NOTHING")
OpenChest     = ActionScript("OPEN_CHEST")
Search        = ActionScript("SEARCH")
Stairs        = ActionScript("STAIRS")
Exit          = ActionScript("EXIT")
ExitWalking   = ActionScript("EXIT_WALKING")
DeathWarp     = ActionScript("DEATH_WARP")
SavePrincess  = ActionScript("RESCUE_PRINCESS")
DragonLord    = ActionScript("DRAGONLORD")
Save          = ActionScript("SAVE")
CastReturn    = ActionScript("CAST_RETURN")
UseWings      = ActionScript("USE_WINGS")
TalkToOldMan  = ActionScript("TALK_TO_OLD_MAN")
ShopKeeper    = ActionScript("TALK_TO_SHOP_KEEPER")
InnKeeper     = ActionScript("TALK_TO_INN_KEEPER")

ConditionScript = class(Script, function(a, name) Script.init(a, name) end)

LeftThroneRoom = ConditionScript("LEFT_THRONEROOM")
HaveKeys       = ConditionScript("HAVE_KEYS")
HaveWings      = ConditionScript("HAVE_WINGS")
HaveReturn     = ConditionScript("HAVE_RETURN")
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

scripts = {}

function scripts.OpenChestAt(mapId, x, y)
  local loc = Point(mapId, x, y)
  return IfScript("Test if chest is open at " .. tostring(loc),
     IsChestOpen(loc),
     DoNothing,
     ListScript("Opening Chest at: " .. tostring(loc), {Goto(mapId, x, y), OpenChest})
   )
end

function scripts.VisitShop(mapId, x, y)
  return ListScript("Visiting shop at: " .. tostring(Point(mapId, x, y)), {Goto(mapId, x, y), ShopKeeper})
end

function scripts.VisitInn(mapId, x, y)
  return ListScript("Visiting inn at: " .. tostring(Point(mapId, x, y)), {Goto(mapId, x, y), InnKeeper})
end

function scripts.SearchAt(mapId, x, y)
  return ListScript("Searching at: " .. tostring(Point(mapId, x, y)), {Goto(mapId, x, y), Search})
end

function scripts.Consecutive(name, scripts)
  return ListScript(name, scripts)
end

function scripts.IfHaveKeys(name, t, f)
  return IfScript(name, HaveKeys, t, f)
end

scripts.openMenu = scripts.Consecutive("Open Menu", { HoldA(30), WaitFrames(10) })
scripts.talk = scripts.Consecutive("Talk", { HoldA(30), WaitFrames(10), PressA })

scripts.exploreGraveScript =
  scripts.Consecutive("Garin's Grave", {
    scripts.OpenChestAt(GarinsGraveLv1, 13, 0),
    scripts.OpenChestAt(GarinsGraveLv1, 12, 0),
    scripts.OpenChestAt(GarinsGraveLv1, 11, 0),
    scripts.IfHaveKeys("If we have keys, Search Bottom Of Grave",
      scripts.Consecutive("Search Bottom Of Grave", {scripts.OpenChestAt(GarinsGraveLv3, 13, 6), Exit}),
      Exit
    ),
  })

scripts.exploreMountainCaveScript =
  scripts.Consecutive("Mountain Cave", {
    scripts.OpenChestAt(MountainCaveLv1, 13, 5),
    scripts.OpenChestAt(MountainCaveLv2, 3, 2),
    scripts.OpenChestAt(MountainCaveLv2, 2, 2),
    scripts.OpenChestAt(MountainCaveLv2, 10, 9),
    scripts.OpenChestAt(MountainCaveLv2, 1, 6),
    Exit
  })

scripts.exploreErdricksCaveScript =
  scripts.Consecutive("Erdrick's Cave", {
    scripts.OpenChestAt(ErdricksCaveLv2, 9, 3),
    Exit
  })

scripts.exploreHauksness =
  scripts.Consecutive("Hauksness", {
    Goto(Hauksness, 18, 12),
    Search,
    Exit -- TODO: need to use the warp point here because Outside doesn't work
         -- I think this will force us to figure out how to leave towns from many different locations.
         -- the good news is that when you leave, you end up on top of the town.
         -- so we can say something similar to: Goto(OverWorldId, town.x, town.y)
         -- but how it chooses to leave from inside the town is still unknown.
  })

scripts.exploreCharlock =
  scripts.Consecutive("Charlock", {
    Goto(Charlock, 10, 1),
    Search,
    Stairs,
    Goto(CharlockThroneRoom, 10, 29),
    scripts.exploreCharlockThroneRoom
  })

scripts.exploreCharlockThroneRoom =
  scripts.Consecutive("Charlock Throne Room", {
    Goto(CharlockThroneRoom, 17, 24),
    DragonLord
  })

scripts.northernShrineScript =
  IfScript(
    "Do we have the harp?",
    HaveHarp,
    scripts.Consecutive("Get Staff", {
      Goto(NorthernShrine, 5, 4),
      scripts.Consecutive("Talk to old man", { scripts.talk, HoldA(60), PressB }),
      scripts.OpenChestAt(NorthernShrine, 3, 4),
      Goto(NorthernShrine, 4, 9),
      Stairs
    }),
    Stairs
  )

scripts.southernShrineScript =
  IfScript(
    "Do we have the staff, stones and token?",
    All ({ HaveStaff, HaveStones, HaveToken }),
    scripts.Consecutive("Talk to old man", {
      Goto(SouthernShrine, 3, 5),
      TalkToOldMan,
      ExitWalking
    }),
    Stairs
  )

scripts.garinhamScript =
  scripts.Consecutive("Garinham", {
    scripts.IfHaveKeys("If we have keys...",
      scripts.Consecutive("Get chests and go down stairs in Garinham.", {
        scripts.OpenChestAt(Garinham, 8, 6),
        scripts.OpenChestAt(Garinham, 8, 5),
        scripts.OpenChestAt(Garinham, 9, 5),
        Goto(Garinham, 19, 0),
        Stairs
      })
    ),
  })

scripts.leaveTantegalOnFoot =
  scripts.Consecutive("Leaving Throne room via legs", {Goto(Tantegel, 0, 9), LeaveTantegel})

scripts.leaveThroneRoomOpeningGameScript =
  IfScript(
    "Figure out how to leave throne room",
    HaveReturn,
    scripts.Consecutive("Leaving Throne room via return", {scripts.saveWithKingScript, CastReturn}),
    IfScript(
      "Check to leave throne room with wings",
      HaveWings,
      scripts.Consecutive("Leaving Throne room via wings", {scripts.saveWithKingScript, UseWings}),
      scripts.leaveTantegalOnFoot
    )
  )

scripts.throneRoomOpeningGameScript =
  IfScript(
    "Have we ever left the throne room? If not, must be starting the game.",
    Not(LeftThroneRoom),
    scripts.Consecutive("Tantagel Throne Room Opening Game", {
      -- we should already be here...but, when i monkey around its better to have this.
      Goto(TantegelThroneRoom, 3, 4),
      HoldUp(30),
      KingOpening,
      scripts.OpenChestAt(TantegelThroneRoom, 4, 4),
      scripts.OpenChestAt(TantegelThroneRoom, 5, 4),
      scripts.OpenChestAt(TantegelThroneRoom, 6, 1),
      scripts.leaveThroneRoomOpeningGameScript
    }),
    -- We probably died, and need to resume doing whatever it was we were last doing.
    -- So it seems like we need some sort of goal system in order to be able to resume.
    scripts.leaveTantegalOnFoot
  )

scripts.saveWithKingScript =
  scripts.Consecutive("Leaving Throne room via wings", {
    Goto(TantegelThroneRoom, 3, 4), Save
  })

-- TODO: add static  npc to basement and fix this up
scripts.tantegelBasementShrine =
  scripts.Consecutive("TantegelBasement (Free cave)", {
    Goto(TantegelBasement, 5, 7),
    Goto(TantegelBasement, 5, 5),
    scripts.OpenChestAt(TantegelBasement, 4, 5),
    Goto(TantegelBasement, 5, 5),
    Goto(TantegelBasement, 5, 7),
    Goto(TantegelBasement, 0, 4),
    Stairs
  })

scripts.kol =
  scripts.Consecutive("Kol", {
    scripts.VisitShop(Kol, 20, 12),
    scripts.SearchAt(Kol, 9, 6),
    scripts.VisitInn(Kol, 19, 2),
    scripts.VisitShop(Kol, 12, 21)
  })

scripts.rimuldar =
  scripts.Consecutive("Rimuldar", {
    IfScript("Do we need keys?", All(NeedKeys, HaveGold(53)),
      scripts.Consecutive("Buy Keys in Rimuldar", {Goto(Rimuldar, 4, 5), ShopKeeper}),
      DoNothing
    ),
    IfScript("Do we have two?", All(HaveKeys(2), HasChestEverBeenOpened(Rimuldar, 24, 23)),
      scripts.Consecutive("Get chest Rimuldar", {Goto(Rimuldar, 24, 23), OpenChest}),
      DoNothing
    )
  })

-- TODO: a lot of work needs to be done on this script
scripts.swampCave =
  IfScript(
    "Are we at swamp north?",
    AtLocation(SwampCave, 0, 0),
    scripts.Consecutive("Go to swamp south and exit", {
      Goto(SwampCave, 0, 29), Stairs
    }),
    -- TODO: we could just cast Outside from here.
    scripts.Consecutive("Go to swamp north and exit", {
      Goto(SwampCave, 0, 0), Stairs
    })
  )

-- scripts.cantlin = scripts.VisitShop(Cantlin, 25, 26)

-- This is for maps that we don't really need a script for
-- because they are handled by the first floor of the map, basically.
-- for example in ErdricksCaveLv1, we just say { OpenChestAt(ErdricksCaveLv2, 9, 3), Exit }
-- there just isn't a case were we need a script for ErdricksCaveLv2
-- the only reason i could potentially ever needing one is like...
-- the script crashes, and we have to restart it and we happen to be in an NA map.
-- but... eh.
NA = nil

scripts.MapScripts = {
  [Charlock] = scripts.exploreCharlock,
  [Hauksness] = scripts.exploreHauksness,
  -- TODO we will need to have more here, but its not terrible for now.
  [Tantegel] = scripts.leaveTantegalOnFoot,
  -- todo this one is kinda broken. i need to see why im in the room
  -- is it my first time there? or did i walk in there to save? or did i just die?
  [TantegelThroneRoom] = scripts.throneRoomOpeningGameScript,
  [CharlockThroneRoom] = scripts.exploreCharlockThroneRoom,
  [Kol] = scripts.kol,
  [Brecconary] = nil,
  [Garinham] = scripts.garinhamScript,
  [Cantlin] = scripts.VisitShop(Cantlin, 25, 26),
  [Rimuldar] = scripts.rimuldar,
  [TantegelBasement] = scripts.tantegelBasementShrine,
  [NorthernShrine] = scripts.northernShrineScript,
  [SouthernShrine] = scripts.southernShrineScript,
  [CharlockCaveLv1] = NA,
  [CharlockCaveLv2] = NA,
  [CharlockCaveLv3] = NA,
  [CharlockCaveLv4] = NA,
  [CharlockCaveLv5] = NA,
  [CharlockCaveLv6] = NA,
  [SwampCave] = scripts.swampCave,
  [MountainCaveLv1] = scripts.exploreMountainCaveScript,
  [MountainCaveLv2] = NA,
  [GarinsGraveLv1] = scripts.exploreGraveScript,
  [GarinsGraveLv2] = NA,
  [GarinsGraveLv3] = NA,
  [GarinsGraveLv4] = NA,
  [ErdricksCaveLv1] = scripts.exploreErdricksCaveScript,
  [ErdricksCaveLv2] = NA,
}
