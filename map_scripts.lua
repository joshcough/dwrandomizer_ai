require 'Class'
require 'controller'
enum = require("enum")
require 'helpers'
require 'locations'
require 'player_data'
require 'static_maps'

Script = class(function(a, name) a.name = name end)
-- TODO: we need to do indent level stuff here, but right now i dont feel like it.
function Script:__tostring() return self.name end

Value = class(Script, function(a, v)
  Script.init(a, "(Value " .. tostring(v) .. ")")
  a.v = v
end)

function Value:equals(v2)
  return self.v == v2.v
end

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

WaitUntil = class(Script, function(a, msg, condition, duration)
  Script.init(a, "Wait until (" .. msg .. ", condition: "
                                .. tostring(condition) .. ", duration: "
                                .. tostring(duration) .. ")")
  a.msg = msg
  a.condition = condition
  a.duration = duration
end)

PressButtonScript = class(Script, function(a, button, waitFrames)
  Script.init(a, button.name .. "(" .. waitFrames .. ")")
  a.button = button
  a.waitFrames = waitFrames
end)

function PressA(waitFrames)      return PressButtonScript(Button.A, waitFrames) end
function PressB(waitFrames)      return PressButtonScript(Button.B, waitFrames) end
function PressUp(waitFrames)     return PressButtonScript(Button.UP, waitFrames) end
function PressDown(waitFrames)   return PressButtonScript(Button.DOWN, waitFrames) end
function PressLeft(waitFrames)   return PressButtonScript(Button.LEFT, waitFrames) end
function PressRight(waitFrames)  return PressButtonScript(Button.RIGHT, waitFrames) end
function PressSelect(waitFrames) return PressButtonScript(Button.SELECT, waitFrames) end
function PressStart(waitFrames)  return PressButtonScript(Button.START, waitFrames) end

HoldButtonScript = class(Script, function(a, button, duration)
  Script.init(a, button.name .. " for " .. duration .. " frames.")
  a.button = button
  a.duration = duration
end)

function HoldA      (duration) return HoldButtonScript(Button.A,      duration) end
function HoldB      (duration) return HoldButtonScript(Button.B,      duration) end
function HoldUp     (duration) return HoldButtonScript(Button.UP,     duration) end
function HoldDown   (duration) return HoldButtonScript(Button.DOWN,   duration) end
function HoldLeft   (duration) return HoldButtonScript(Button.LEFT,   duration) end
function HoldRight  (duration) return HoldButtonScript(Button.RIGHT,  duration) end
function HoldSelect (duration) return HoldButtonScript(Button.SELECT, duration) end
function HoldStart  (duration) return HoldButtonScript(Button.START,  duration) end

HoldButtonUntilScript = class(Script, function(a, button, condition)
  Script.init(a, button.name .. " until " .. tostring(condition))
  a.button = button
  a.condition = condition
end)

function HoldAUntil      (condition) return HoldButtonUntilScript(Button.A,      condition) end
function HoldBUntil      (condition) return HoldButtonUntilScript(Button.B,      condition) end
function HoldUpUntil     (condition) return HoldButtonUntilScript(Button.UP,     condition) end
function HoldDownUntil   (condition) return HoldButtonUntilScript(Button.DOWN,   condition) end
function HoldLeftUntil   (condition) return HoldButtonUntilScript(Button.LEFT,   condition) end
function HoldRightUntil  (condition) return HoldButtonUntilScript(Button.RIGHT,  condition) end
function HoldSelectUntil (condition) return HoldButtonUntilScript(Button.SELECT, condition) end
function HoldStartUntil  (condition) return HoldButtonUntilScript(Button.START,  condition) end

ActionScript = class(Script, function(a, name)
  Script.init(a, name)
end)

DoNothing      = ActionScript("DO_NOTHING")
OpenChest      = ActionScript("OPEN_CHEST")
Search         = ActionScript("SEARCH")
DeathWarp      = ActionScript("DEATH_WARP")
SavePrincess   = ActionScript("RESCUE_PRINCESS")
DragonLord     = ActionScript("DRAGONLORD")
ShopKeeper     = ActionScript("TALK_TO_SHOP_KEEPER")
DoBattle       = ActionScript("DO_BATTLE")
CloseCmdMenu   = ActionScript("CLOSE_CMD_MENU")

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

function AtLocation(mapId, x, y) return DotEq(GetLocation, Value(Point(mapId, x, y))) end

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

InBattle = class(ConditionScript, function(a)
  ConditionScript.init(a, "IN_BATTLE")
end)

BinaryOperator = class(ConditionScript, function(a, name, l, r, f)
  ConditionScript.init(a, tostring(l) .. " " .. name .. " " .. tostring(r))
  a.location = location
  a.f = f
  a.l = l
  a.r = r
end)

function Eq(l,r)    return BinaryOperator("==",  l, r, function(lv,rv) return lv == rv end) end
function DotEq(l,r) return BinaryOperator(":eq", l, r, function(lv,rv) return lv:equals(rv) end) end
function NotEq(l,r) return BinaryOperator("~=",  l, r, function(lv,rv) return lv ~= rv end) end
function Add(l,r)   return BinaryOperator("+",   l, r, function(lv,rv) return lv + rv end) end
function Sub(l,r)   return BinaryOperator("-",   l, r, function(lv,rv) return lv - rv end) end
function Mult(l,r)  return BinaryOperator("*",   l, r, function(lv,rv) return lv * rv end) end
function Div(l,r)   return BinaryOperator("/",   l, r, function(lv,rv) return lv / rv end) end
function Max(l,r)   return BinaryOperator("max", l, r, function(lv,rv) return math.max(lv,rv) end) end
function Min(l,r)   return BinaryOperator("min", l, r, function(lv,rv) return math.min(lv,rv) end) end
function Lt(l,r)    return BinaryOperator("min", l, r, function(lv,rv) return lv < rv end) end
function LtEq(l,r)  return BinaryOperator("min", l, r, function(lv,rv) return lv <= rv end) end
function Gt(l,r)    return BinaryOperator("min", l, r, function(lv,rv) return lv > rv end) end
function GtEq(l,r)  return BinaryOperator("min", l, r, function(lv,rv) return lv >= rv end) end

Any = class(ConditionScript, function(a, conditions)
  ConditionScript.init(a, "ANY")
  a.conditions = conditions
end)

function Any:__tostring()
  local res = "ANY of:\n"
  for _,s in pairs(self.conditions) do
    res = res .. "  " .. tostring(s) .. "\n"
  end
  return res
end

All = class(ConditionScript, function(a, conditions)
  ConditionScript.init(a, "ALL")
  a.conditions = conditions
end)

function All:__tostring()
  local res = "ALL of:\n"
  for _,s in pairs(self.conditions) do
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
  ConditionScript.init(a, "CONTAINS: " .. tostring(v))
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
GetLocation = PlayerDataScript("Location of player", function(pd) return pd.loc end)
GetMap      = PlayerDataScript("MAP", function(pd) return pd.loc.mapId end)
GetItems    = PlayerDataScript("Player's Items", function(pd) return pd.items end)
GetSpells   = PlayerDataScript("Player's Spells", function(pd) return pd.spells end)
GetStatuses = PlayerDataScript("Game statuses", function(pd) return pd.statuses end)

GetHP       = PlayerDataScript("Amount of HP the player has.", function(pd) return pd.stats.currentHP end)
GetMP       = PlayerDataScript("Amount of MP the player has.", function(pd) return pd.stats.currentMP end)
GetMaxHP    = PlayerDataScript("Amount of HP the player has.", function(pd) return pd.stats.maxHP end)
GetMaxMP    = PlayerDataScript("Amount of MP the player has.", function(pd) return pd.stats.maxMP end)

function CanAfford(amount)
 return GtEq(GetGold, Value(amount))
end

function CanCast(spell)
  return All({
    HaveSpell(spell),
    GtEq(GetMP, Value(spell.mp))
  })
end

PlayerDirScript = class(Script, function(a)
  Script.init(a, "HEADING")
end)

FaceUp    = HoldUpUntil   (Eq(PlayerDirScript(), Value(Heading.UP)))
FaceDown  = HoldDownUntil (Eq(PlayerDirScript(), Value(Heading.DOWN)))
FaceLeft  = HoldLeftUntil (Eq(PlayerDirScript(), Value(Heading.LEFT)))
FaceRight = HoldRightUntil(Eq(PlayerDirScript(), Value(Heading.RIGHT)))

function StatusScript(statusFld)
  return PlayerDataScript("Status: " .. statusFld, function(pd) return pd.statuses[statusFld] end)
end

IfThenScript = class(Script, function(a, name, condition, trueBranch, falseBranch)
  Script.init(a, name)
  a.condition = condition
  a.trueBranch = trueBranch
  a.falseBranch = falseBranch
end)

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

-- repeat the given script `n` times.
NTimes = class(Script, function(a, n, script)
  Script.init(a, "NTimes(" .. tostring(n) .. "," .. tostring(script) .. ")")
  a.n = n
  a.script = script
end)

-- TODO: this isn't used yet, but, I feel like it can be really useful
-- repeat the given script until the given function returns true
-- RepeatUntil = class(Script, function(a, f, script)
--   Script.init(a, "NTimes(" .. tostring(n) .. "," .. tostring(script) .. ")")
--   a.n = n
--   a.script = script
-- end)


function Consecutive:__tostring()
  local res = self.name .. ":\n"
  for _,s in pairs(self.scripts) do
    res = res .. "  " .. tostring(s) .. "\n"
  end
  return res
end

OnStaticMap = All({Gt(GetMap, Value(1)), LtEq(GetMap, Value(29))})
function OnMap(m) return Eq(GetMap, Value(m)) end

Scripts = class(function(a,entrances)

  charlockLocation = entrances[Charlock][1]
  a.tantegelLocation = entrances[Tantegel][1]
  -- log.debug("charlockLocation", charlockLocation)
  -- log.debug("tantegelLocation", a.tantegelLocation)

  OpenMenu = Consecutive("Open Menu", { HoldA(30), WaitFrames(10) })
  OpenItemMenu = Consecutive("Open Item Menu", { OpenMenu, PressRight(2), PressDown(2), PressA(2), WaitFrames(30) })
  OpenSpellMenu = Consecutive("Open Spell Menu", { OpenMenu, PressRight(2), PressA(2), WaitFrames(30) })
  Talk = Consecutive("Talk", { HoldA(30), WaitFrames(10), PressA(2) })
  TakeStairs = Consecutive("Take Stairs", { OpenMenu, PressDown(2), PressDown(2), PressA(60), CloseCmdMenu })

  function VisitShop(mapId, x, y, dir)
    return Consecutive("Visiting shop at: " .. tostring(Point(mapId, x, y)), {
      Goto(mapId, x, y),
      dir,
      Talk,
      WaitFrames(30),
      PressA(30),
      ShopKeeper
    })
  end

  function VisitInn(p, cost, directionScript)
    return IfThenScript(
      "If we can afford the inn, use it.",
      CanAfford(cost),
      Consecutive("Visiting inn at: " .. tostring(p), {
        CanAfford(53),
        GotoPoint(p),
        directionScript,
        Talk,
        PressA(30),
        PressA(300),
        PressA(30),
        PressB(2)
      }),
      DoNothing
    )
  end

  function OpenDoor(loc)
   return IfThenScript(
      "If the door closed at: " .. tostring(loc) .. ", then open it.",
      IsDoorOpen(loc),
      DoNothing,
      Consecutive("Open Door", {
        OpenMenu, PressDown(2), PressDown(2), PressRight(2), PressA(20), SaveUnlockedDoor(loc)
      })
    )
  end

  function SearchAtWith(mapId, x, y, script)
    return Consecutive("Searching at: " .. tostring(Point(mapId, x, y)), {
      Goto(mapId, x, y),
      script,
      OpenMenu,
      PressUp(2),
      PressA(40),
      PressA(10),
      Search
    })
  end

  function SearchSpikeTile(mapId, x, y)
    return SearchAtWith(mapId, x, y,
      Consecutive("Fighting monster on spike tile.", {
        WaitUntil("In Battle", InBattle(), 240),
        DoBattle,
        WaitUntil("Not in Battle", Not(InBattle()), 240),
      })
    )
  end

  function SearchAt(mapId, x, y)
    return SearchAtWith(mapId, x, y, DoNothing)
  end

  function IfHaveKeys(name, t, f)
    return IfThenScript(name, Gt(GetNrKeys, Value(2)), t, f)
  end

  openChestMenuing = Consecutive("Menuing for opening Chest at",
    -- TODO: see if we can reduce this 90 to 60 or 75. I don't remember.
    { OpenMenu, PressUp(10), PressRight(10), HoldA(90), OpenChest }
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
    local p = entrances[fromMap][1].from
    if p.mapId ~= OverWorldId then p = entrances[p.mapId][1].from end
    return Goto(p.mapId, p.x, p.y)
  end

  function LeaveDungeon(mapId)
    return IfThenScript(
      "Figure out how to leave map: " .. tostring(mapId),
      CanCast(Outside),
      CastSpell(Outside),
      GotoOverworld(mapId)
    )
  end

  function BuyKeysAt(loc, dir)
    return Consecutive("Buy Keys", {
      GotoPoint(loc),
      dir,
      Talk,
      WaitFrames(30),
      NTimes(Sub(Value(6), GetNrKeys), PressA(60)),
      PressB(2),
      PressB(30)
    })
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

  InnScripts = {
    [Kol]        = VisitInn(Point(Kol,       19,  2),  20, FaceDown),
    [Brecconary] = VisitInn(Point(Brecconary, 8, 21),   6, FaceRight),
    [Garinham]   = VisitInn(Point(Garinham,  15, 15),  25, FaceRight),
    [Cantlin]    = VisitInn(Point(Cantlin,    8,  5), 100, FaceUp),
    [Rimuldar]   = VisitInn(Point(Rimuldar,  18, 18),  55, FaceLeft),
  }

  saveWithKingScript =
    Consecutive("Save with the king", {
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
      SearchSpikeTile(Hauksness, 18, 12),
      GotoOverworld(Hauksness)
    })

  EnterCharlock =
    IfThenScript(
      "Have we already created the rainbow bridge?",
      StatusScript("rainbowBridge"),
      GotoPoint(charlockLocation.to),
      IfThenScript(
        "Do we have the rainbow drop?",
        HaveItem(RainbowDrop),
        Consecutive("Enter Charlock", {
          Goto(OverWorldId, charlockLocation.from.x + 3, charlockLocation.from.y),
          UseItem(RainbowDrop),
          GotoPoint(charlockLocation.from),
          WaitUntil("In Charlock", OnMap(Charlock), 240)
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
        Consecutive("Talk to old man", { Talk, HoldA(60), PressB(2) }),
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
        Consecutive("Talk to old man", { Talk, HoldA(60), PressB(2) }),
        GotoOverworld(SouthernShrine)
      }),
      TakeStairs
    )

  -- TODO: ok something is busted here...
  -- we get into the grave... and then i think we are trying to go to this shop
  -- but its all wrong because we are inside the fucking grave man. wtf.
  garinhamScript =
    Consecutive("Garinham", {
      VisitShop(Garinham, 10, 16, FaceDown),
      InnScripts[Garinham],
      -- TODO: we need a way to ask like... are all the chests in garinham and the grave already opened?
      -- if so, we dont need to do this step at all.
      IfHaveKeys("If we have keys...",
        Consecutive("Get chests and go down stairs in Garinham.", {
          OpenChestAt(Garinham, 8, 6),
          OpenChestAt(Garinham, 8, 5),
          OpenChestAt(Garinham, 9, 5),
          Goto(Garinham, 19, 0),
          TakeStairs,
          -- TODO: might need something like "explore static map" here.
        }),
        GotoOverworld(Garinham)
      )
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
      Consecutive("Talk to king after dying", {
        HoldA(250),
        leaveTantegalOnFoot
      })
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
      -- TODO: dont search if we already have
      -- unless we are doing a ghetto grind
      SearchAt(Kol, 9, 6),
      VisitShop(Kol, 20, 12, FaceRight),
      InnScripts[Kol],
      -- TODO: we can't go to this one yet
      -- because its not a weapon and armor shop
      -- and thats currently all we know how to handle
      -- VisitShop(Kol, 12, 21),
      GotoOverworld(Kol)
    })

  rimuldar =
    Consecutive("Rimuldar", {
      IfThenScript("Do we need keys?", All({Lt(GetNrKeys,Value(6)), CanAfford(53)}),
        BuyKeysAt(Point(Rimuldar, 4, 5), FaceDown),
        DoNothing
      ),
      IfThenScript("Open the chest in Rimuldar?", All({GtEq(GetNrKeys, Value(2)), Not(HasChestEverBeenOpened(Point(Rimuldar, 24, 23)))}),
        Consecutive("Get chest Rimuldar", {OpenChestAt(Rimuldar, 24, 23)}),
        DoNothing
      ),
      VisitShop(Rimuldar, 23, 9, FaceUp),
      InnScripts[Rimuldar],
      GotoOverworld(Rimuldar)
    })

  -- TODO: a lot of work needs to be done on this script
  swampCave =
    IfThenScript(
      "Are we at swamp north?",
      AtLocation(SwampCave, 0, 0),
      -- TODO: we can keep track of if weve ever been at swamp south
      -- if we have, then it might not make any sense to go there
      Consecutive("Go to swamp south and exit", {
        Goto(SwampCave, 0, 29), TakeStairs
      }),
      -- TODO: we could just cast Outside from here.
      Consecutive("Go to swamp north and exit", {
        Goto(SwampCave, 0, 0), TakeStairs
      })
    )

  cantlin = Consecutive( "Cantlin", {
    VisitShop(Cantlin, 25, 26, FaceRight),
    -- TODO: this one we can only do if we have keys:
    -- VisitShop(Cantlin, 26, 12),
    -- TODO: this one has the guy that moves around:
    -- WeaponAndArmorShop({Point(Cantlin, 20, 3), Point(Cantlin, 20, 4), Point(Cantlin, 20, 5), Point(Cantlin, 20, 6)}, getShopItems(c1))
    InnScripts[Cantlin],
    GotoOverworld(Cantlin)
  })

  brecconary = Consecutive("Brecconary", {
    VisitShop(Brecconary, 5, 6, FaceUp),
    InnScripts[Brecconary],
    GotoOverworld(Brecconary)
  })

  tantegel = Consecutive("Tantegel", {
    IfHaveKeys("If we have keys, do all the things in Tantegel",
      Consecutive("Do all the things in Tantegel with a key", {
        BuyKeysAt(Point(Tantegel, 24, 3), FaceUp),
        Goto(Tantegel, 29, 29), -- basement
        OpenChestAt(Tantegel, 1, 13),
        OpenChestAt(Tantegel, 1, 15),
        OpenChestAt(Tantegel, 2, 14),
        OpenChestAt(Tantegel, 3, 15)
      }),
      leaveTantegalOnFoot
    )
  })

  -- TODO: we might want to bring this back.
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
    [Tantegel] = leaveTantegalOnFoot,
    [TantegelThroneRoom] = throneRoomScript,
    [CharlockThroneRoom] = exploreCharlockThroneRoom,
    [Kol] = kol,
    [Brecconary] = brecconary,
    [Garinham] = garinhamScript,
    [Cantlin] = cantlin,
    [Rimuldar] = rimuldar,
    [TantegelBasement] = tantegelBasementShrine,
    [NorthernShrine] = northernShrineScript,
    [SouthernShrine] = southernShrineScript,
    [CharlockCaveLv1] = LeaveDungeon(Charlock),
    [CharlockCaveLv2] = LeaveDungeon(Charlock),
    [CharlockCaveLv3] = LeaveDungeon(Charlock),
    [CharlockCaveLv4] = LeaveDungeon(Charlock),
    [CharlockCaveLv5] = LeaveDungeon(Charlock),
    [CharlockCaveLv6] = LeaveDungeon(Charlock),
    [SwampCave] = swampCave,
    [MountainCaveLv1] = exploreMountainCaveScript,
    [MountainCaveLv2] = LeaveDungeon(MountainCaveLv1),
    [GarinsGraveLv1] = exploreGraveScript,
    [GarinsGraveLv2] = LeaveDungeon(GarinsGraveLv1),
    [GarinsGraveLv3] = LeaveDungeon(GarinsGraveLv1),
    [GarinsGraveLv4] = LeaveDungeon(GarinsGraveLv1),
    [ErdricksCaveLv1] = exploreErdricksCaveScript,
    [ErdricksCaveLv2] = LeaveDungeon(ErdricksCaveLv1),
  }

  a.InnScripts = InnScripts
  a.OpenMenu = OpenMenu
  a.OpenItemMenu = OpenItemMenu
  a.OpenSpellMenu = OpenSpellMenu
  a.OpenChestAt = OpenChestAt
  a.OpenDoor = OpenDoor
  a.TakeStairs = TakeStairs
  a.EnterCharlock = EnterCharlock
  a.GameStartMenuScript = GameStartMenuScript
  a.throneRoomScript = throneRoomScript
  a.GotoPoint = GotoPoint
  a.Talk = Talk
end)
