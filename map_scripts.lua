require 'Class'
enum = require("enum")

Script = class(function(a, name, body) a.name = name end)
function Script:__tostring() return self.name end

Goto = class(Script, function(a, mapId, x, y)
  Script.init(a, "Goto")
  a.location = Point(mapId, x, y)
end)

function Goto:__tostring()
  return self.name .. ": " .. tostring(self.location)
end

Actions = enum.new("Script Base Cases", {"DO_NOTHING", "OPEN_CHEST", "SEARCH", "EXIT", "DEATH_WARP", "PRINCESS", "DRAGONLORD"})
ActionScript = class(Script, function(a, e)
  Script.init(a, e.name)
  a.enum = e
end)

DoNothing  = ActionScript(Actions.DO_NOTHING)
OpenChest  = ActionScript(Actions.OPEN_CHEST)
Search     = ActionScript(Actions.SEARCH)
Exit       = ActionScript(Actions.EXIT)
DeathWarp  = ActionScript(Actions.DEATH_WARP)
Princess   = ActionScript(Actions.PRINCESS)
DragonLord = ActionScript(Actions.DRAGONLORD)

ConditionCases = enum.new("Condition Script Cases", {"HAVE_KEYS", "IS_CHEST_OPEN"})
ConditionScript = class(Script, function(a, e) Script.init(a, e.name) end)

HaveKeys = ConditionScript(ConditionCases.HAVE_KEYS)

IsChestOpen = class(ConditionScript, function(a, location)
  ConditionScript.init(a, ConditionCases.IS_CHEST_OPEN)
  a.location = location
end)

function IsChestOpen:__tostring()
  return self.name .. ": " .. tostring(self.location)
end

BranchScript = class(Script, function(a, name, condition, trueBranch, falseBranch)
  Script.init(a, name)
  a.condition = condition
  a.trueBranch = trueBranch
  a.falseBranch = falseBranch
end)

-- TODO: we need to do indent level stuff here, but right now i dont feel like it.
function BranchScript:__tostring()
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

function scripts.Goto(loc)
  return Goto(loc)
end

function scripts.OpenChestAt(mapId, x, y)
  return BranchScript("Test if chest is open at " .. tostring(loc),
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
  return BranchScript(name, HaveKeys, t, f)
end

function scripts.Exit()
  return Exit
end

function scripts.DeathWarp()
  return DeathWarp
end

function scripts.exploreGraveScript()
  local s = scripts.Consecutive("Garin's Grave", {
    scripts.OpenChestAt(GarinsGraveLv1, 13, 0),
    scripts.OpenChestAt(GarinsGraveLv1, 12, 0),
    scripts.OpenChestAt(GarinsGraveLv1, 11, 0),
    scripts.IfHaveKeys("If we have keys, Search Bottom Of Grave",
      scripts.Consecutive("Search Bottom Of Grave", {scripts.OpenChestAt(GarinsGraveLv3, 13, 6), scripts.Exit()}),
      scripts.Exit()
    ),
  })
  return s
end

function scripts.exploreMountainCavecript()
  return scripts.Consecutive("Mountain Cave", {
    scripts.OpenChestAt(MountainCaveLv1, 13, 5),
    scripts.OpenChestAt(MountainCaveLv2, 3, 2),
    scripts.OpenChestAt(MountainCaveLv2, 2, 2),
    scripts.OpenChestAt(MountainCaveLv2, 10, 9),
    scripts.OpenChestAt(MountainCaveLv2, 1, 6),
    scripts.Exit()
  })
end