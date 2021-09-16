require 'Class'
enum = require("enum")
require 'static_maps'

Script = class(function(a, name, body) a.name = name end)
function Script:__tostring() return self.name end

Goto = class(Script, function(a, mapId, x, y)
  Script.init(a, "Goto")
  a.location = Point(mapId, x, y)
end)

function Goto:__tostring()
  return self.name .. ": " .. tostring(self.location)
end

Actions = enum.new("Script Base Cases", {
  "DO_NOTHING",
  "OPEN_CHEST",
  "SEARCH",
  "EXIT",
  "DEATH_WARP",
  "KING_OPENING_GAME",
  "LEAVE_TANTEGEL_OPENING_GAME",
  "RESCUE_PRINCESS",
  "DRAGONLORD",
  "SAVE",
  "CAST_RETURN",
  "USE_WINGS",
  "TALK_TO_OLD_MAN"
})
ActionScript = class(Script, function(a, e)
  Script.init(a, e.name)
  a.enum = e
end)

KingOpening   = ActionScript(Actions.KING_OPENING_GAME)
LeaveTantegel = ActionScript(Actions.LEAVE_TANTEGEL_OPENING_GAME)
DoNothing     = ActionScript(Actions.DO_NOTHING)
OpenChest     = ActionScript(Actions.OPEN_CHEST)
Search        = ActionScript(Actions.SEARCH)
Exit          = ActionScript(Actions.EXIT)
DeathWarp     = ActionScript(Actions.DEATH_WARP)
SavePrincess  = ActionScript(Actions.RESCUE_PRINCESS)
DragonLord    = ActionScript(Actions.DRAGONLORD)
Save          = ActionScript(Actions.SAVE)
CastReturn    = ActionScript(Actions.CAST_RETURN)
UseWings      = ActionScript(Actions.USE_WINGS)
TalkToOldMan  = ActionScript(Actions.TALK_TO_OLD_MAN)

ConditionCases = enum.new("Condition Script Cases", {
  "LEFT_THRONEROOM",
  "HAVE_KEYS",
  "HAVE_WINGS",
  "HAVE_RETURN",
  "HAVE_HARP",
  "IS_CHEST_OPEN"
})
ConditionScript = class(Script, function(a, e) Script.init(a, e.name) end)

LeftThroneRoom = ConditionScript(ConditionCases.LEFT_THRONEROOM)
HaveKeys       = ConditionScript(ConditionCases.HAVE_KEYS)
HaveWings      = ConditionScript(ConditionCases.HAVE_WINGS)
HaveReturn     = ConditionScript(ConditionCases.HAVE_RETURN)
HaveHarp       = ConditionScript(ConditionCases.HAVE_HARP)
IsChestOpen    = class(ConditionScript, function(a, location)
  ConditionScript.init(a, ConditionCases.IS_CHEST_OPEN)
  a.location = location
end)

function IsChestOpen:__tostring()
  return self.name .. ": " .. tostring(self.location)
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
  return IfScript("Test if chest is open at " .. tostring(loc),
           IsChestOpen(Point(mapId, x, y)),
           DoNothing,
           ListScript("Opening Chest at: " .. tostring(loc), {Goto(mapId, x, y), OpenChest})
         )
end

function scripts.SearchAt(loc)
  return ListScript("Searching at: " .. tostring(loc), {Goto(mapId, x, y), Search})
end

function scripts.Consecutive(name, scripts)
  return ListScript(name, scripts)
end

function scripts.IfHaveKeys(name, t, f)
  return IfScript(name, HaveKeys, t, f)
end

function scripts.Exit()
  return Exit
end

function scripts.DeathWarp()
  return DeathWarp
end

function scripts.exploreGraveScript()
  return scripts.Consecutive("Garin's Grave", {
    scripts.OpenChestAt(GarinsGraveLv1, 13, 0),
    scripts.OpenChestAt(GarinsGraveLv1, 12, 0),
    scripts.OpenChestAt(GarinsGraveLv1, 11, 0),
    scripts.IfHaveKeys("If we have keys, Search Bottom Of Grave",
      scripts.Consecutive("Search Bottom Of Grave", {scripts.OpenChestAt(GarinsGraveLv3, 13, 6), scripts.Exit()}),
      scripts.Exit()
    ),
  })
end

function scripts.exploreMountainCaveScript()
  return scripts.Consecutive("Mountain Cave", {
    scripts.OpenChestAt(MountainCaveLv1, 13, 5),
    scripts.OpenChestAt(MountainCaveLv2, 3, 2),
    scripts.OpenChestAt(MountainCaveLv2, 2, 2),
    scripts.OpenChestAt(MountainCaveLv2, 10, 9),
    scripts.OpenChestAt(MountainCaveLv2, 1, 6),
    scripts.Exit()
  })
end

function scripts.exploreErdricksCaveScript()
  return scripts.Consecutive("Erdrick's Cave", {
    scripts.OpenChestAt(ErdricksCaveLv2, 9, 3),
    scripts.Exit()
  })
end

function scripts.northernShrineScript()
  return IfScript(
    "Do we have the harp?",
    HaveHarp,
    scripts.Consecutive("Talk to old man", {
      Goto(NorthernShrine, 5, 4),
      TalkToOldMan,
      scripts.Exit()
    }),
    scripts.Exit()
  )
end

-- this might be able to be done more interestingly with the flags that are stored
-- in the ram or wherever. i think there was a "left_throneroom" flag or something like it anyway.
function scripts.throneRoomOpeningGameScript()
  return scripts.Consecutive("Tantagel Throne Room Opening Game", {
    KingOpening,
    scripts.OpenChestAt(TantegelThroneRoom, 4, 4),
    scripts.OpenChestAt(TantegelThroneRoom, 5, 4),
    scripts.OpenChestAt(TantegelThroneRoom, 6, 1),
    scripts.leaveThroneRoomOpeningGameScript()
  })
end

function scripts.leaveThroneRoomOpeningGameScript()
  local save = scripts.saveWithKingScript()
  return IfScript(
    "Figure out how to leave throne room",
    HaveReturn,
    scripts.Consecutive("Leaving Throne room via return", {save, CastReturn}),
    IfScript(
      "Check to leave throne room with wings",
      HaveWings,
      scripts.Consecutive("Leaving Throne room via wings", {save, UseWings}),
      Goto(Tantegel, 0, 9)
    )
  )
end

function scripts.saveWithKingScript()
  scripts.Consecutive("Leaving Throne room via wings", {
    Goto(TantegelThroneRoom, 3, 4), Save
  })
end

scripts.MapScripts = {
  [Charlock] = nil,
  [Hauksness] = nil,
  [Tantegel] = nil,
  -- todo this one is kinda broken. i need to see why im in the room
  -- is it my first time there? or did i walk in there to save? or did i just die?
  [TantegelThroneRoom] = scripts.throneRoomOpeningGameScript(),
  [CharlockThroneRoom] = nil,
  [Kol] = nil,
  [Brecconary] = nil,
  [Garinham] = nil,
  [Cantlin] = nil,
  [Rimuldar] = nil,
  [TantegelBasement] = nil,
  [NorthernShrine] = scripts.northernShrineScript(),
  [SouthernShrine] = nil,
  [CharlockCaveLv1] = nil,
  [CharlockCaveLv2] = nil,
  [CharlockCaveLv3] = nil,
  [CharlockCaveLv4] = nil,
  [CharlockCaveLv5] = nil,
  [CharlockCaveLv6] = nil,
  [SwampCave] = nil,
  [MountainCaveLv1] = scripts.exploreMountainCaveScript(),
  [MountainCaveLv2] = nil,
  [GarinsGraveLv1] = scripts.exploreGraveScript(),
  [GarinsGraveLv2] = nil,
  [GarinsGraveLv3] = nil,
  [GarinsGraveLv4] = nil,
  [ErdricksCaveLv1] = scripts.exploreErdricksCaveScript(),
  [ErdricksCaveLv2] = nil,
}
