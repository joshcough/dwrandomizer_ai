require "Class"
enum = require("enum")

SlimeId         = 0
RedSlimeId      = 1
DrakeeId        = 2
GhostId         = 3
MagicianId      = 4
MagidrakeeId    = 5
ScorpionId      = 6
DruinId         = 7
PoltergeistId   = 8
DrollId         = 9
DrakeemaId      = 10
SkeletonId      = 11
WarlockId       = 12
MetalScorpionId = 13
WolfId          = 14
WraithId        = 15
MetalSlimeId    = 16
SpecterId       = 17
WolflordId      = 18
DruinlordId     = 19
DrollmagiId     = 20
WyvernId        = 21
RogueScorpionId = 22
WraithKnightId  = 23
GolemId         = 24
GoldmanId       = 25
KnightId        = 26
MagiwyvernId    = 27
DemonKnightId   = 28
WerewolfId      = 29
GreenDragonId   = 30
StarwyvernId    = 31
WizardId        = 32
AxeKnightId     = 33
BlueDragonId    = 34
StonemanId      = 35
ArmoredKnightId = 36
RedDragonId     = 37
Dragonlord1Id   = 38
Dragonlord2Id   = 39

Enemy = class(function(a, id, name, strength, agility, hpMin, hpMax, exp,
                       gold, sleepRes, stopspellResMax, hurtRes, evasion)
  a.id = id
  a.name = name
  a.strength = strength
  a.agility = agility
  a.hpMin = hpMin
  a.hpMax = hpMax
  a.exp = exp
  a.gold = gold
  a.sleepRes = sleepRes
  a.stopspellResMax = stopspellResMax
  a.hurtRes = hurtRes
  a.evasion = evasion
  a.locations = {}
end)

Enemies = {
  --                        id               name              str  agi   min  max   xp gld  slp stp hurt evd
  [SlimeId        ] = Enemy(SlimeId        , "Slime",            5,   3,   2,   2,   1,   2,  0,  0,  0,  1),
  [RedSlimeId     ] = Enemy(RedSlimeId     , "Red Slime",        7,   3,   3,   3,   2,   4,  0,  0,  0,  1),
  [DrakeeId       ] = Enemy(DrakeeId       , "Drakee",           9,   6,   4,   5,   3,   6,  0,  0,  0,  1),
  [GhostId        ] = Enemy(GhostId        , "Ghost",           11,   8,   6,   7,   4,   8,  0,  1,  0,  4),
  [MagicianId     ] = Enemy(MagicianId     , "Magician",        11,  12,   9,  12,   8,  16,  0,  1,  0,  1),
  [MagidrakeeId   ] = Enemy(MagidrakeeId   , "Magidrakee",      14,  14,  10,  13,  12,  20,  0,  1,  0,  1),
  [ScorpionId     ] = Enemy(ScorpionId     , "Scorpion",        18,  16,  10,  13,  16,  25,  0,  2,  0,  1),
  [DruinId        ] = Enemy(DruinId        , "Druin",           20,  18,  17,  22,  14,  21,  0,  2,  0,  2),
  [PoltergeistId  ] = Enemy(PoltergeistId  , "Poltergeist",     18,  20,  18,  23,  15,  19,  0,  2,  0,  6),
  [DrollId        ] = Enemy(DrollId        , "Droll",           24,  24,  15,  20,  18,  30,  0,  3,  0,  2),
  [DrakeemaId     ] = Enemy(DrakeemaId     , "Drakeema",        22,  26,  12,  16,  20,  25,  2,  3,  0,  6),
  [SkeletonId     ] = Enemy(SkeletonId     , "Skeleton",        28,  22,  18,  24,  25,  42,  0,  3,  0,  4),
  [WarlockId      ] = Enemy(WarlockId      , "Warlock",         28,  22,  21,  28,  28,  50,  3,  4,  0,  2),
  [MetalScorpionId] = Enemy(MetalScorpionId, "Metal Scorpion",  36,  42,  14,  18,  31,  48,  0,  4,  0,  2),
  [WolfId         ] = Enemy(WolfId         , "Wolf",            40,  30,  25,  33,  40,  60,  1,  4,  0,  2),
  [WraithId       ] = Enemy(WraithId       , "Wraith",          44,  34,  30,  39,  42,  62,  7,  5,  0,  4),
  [MetalSlimeId   ] = Enemy(MetalSlimeId   , "Metal Slime",     10, 255,   3,   3, 255,   6, 15,  5, 15,  1),
  [SpecterId      ] = Enemy(SpecterId      , "Specter",         40,  38,  25,  33,  47,  75,  3,  5,  0,  4),
  [WolflordId     ] = Enemy(WolflordId     , "Wolflord",        50,  36,  28,  37,  52,  80,  4,  6,  0,  2),
  [DruinlordId    ] = Enemy(DruinlordId    , "Druinlord",       47,  40,  27,  35,  58,  95, 15,  6,  0,  4),
  [DrollmagiId    ] = Enemy(DrollmagiId    , "Drollmagi",       52,  50,  33,  44,  58, 110,  2,  6,  0,  1),
  [WyvernId       ] = Enemy(WyvernId       , "Wyvern",          56,  48,  28,  37,  64, 105,  4,  7,  0,  2),
  [RogueScorpionId] = Enemy(RogueScorpionId, "Rogue Scorpion",  60,  90,  30,  40,  70, 110,  7,  7,  0,  2),
  [WraithKnightId ] = Enemy(WraithKnightId , "Wraith Knight",   68,  56,  30,  40,  72, 120,  5,  7,  3,  4),
  [GolemId        ] = Enemy(GolemId        , "Golem",          120,  60, 115, 153, 255,  10, 15,  8, 15,  0),
  [GoldmanId      ] = Enemy(GoldmanId      , "Goldman",         48,  40,  27,  35,   6, 255, 13,  8,  0,  1),
  [KnightId       ] = Enemy(KnightId       , "Knight",          76,  78,  36,  47,  78, 150,  6,  8,  0,  1),
  [MagiwyvernId   ] = Enemy(MagiwyvernId   , "Magiwyvern",      78,  68,  36,  48,  83, 135,  2,  9,  0,  2),
  [DemonKnightId  ] = Enemy(DemonKnightId  , "Demon Knight",    79,  64,  29,  38,  90, 148, 15,  9, 15, 15),
  [WerewolfId     ] = Enemy(WerewolfId     , "Werewolf",        86,  70,  53,  70,  95, 155,  7,  9,  0,  7),
  [GreenDragonId  ] = Enemy(GreenDragonId  , "Green Dragon",    88,  74,  54,  72, 135, 160,  7, 10,  2,  2),
  [StarwyvernId   ] = Enemy(StarwyvernId   , "Starwyvern",      86,  80,  56,  74, 105, 169,  8, 10,  1,  2),
  [WizardId       ] = Enemy(WizardId       , "Wizard",          80,  70,  49,  65, 120, 185, 15, 10, 15,  2),
  [AxeKnightId    ] = Enemy(AxeKnightId    , "Axe Knight",      94,  82,  51,  67, 130, 165, 15, 11,  1,  1),
  [BlueDragonId   ] = Enemy(BlueDragonId   , "Blue Dragon",     98,  84,  74,  98, 180, 150, 15, 11,  7,  2),
  [StonemanId     ] = Enemy(StonemanId     , "Stoneman",       100,  40, 102, 135, 155, 148,  2, 11,  7,  1),
  [ArmoredKnightId] = Enemy(ArmoredKnightId, "Armored Knight", 105,  86,  75,  99, 172, 152, 15, 12,  1,  2),
  [RedDragonId    ] = Enemy(RedDragonId    , "Red Dragon",     120,  90,  80, 106, 255, 143, 15, 12, 15,  2),
  [Dragonlord1Id  ] = Enemy(Dragonlord1Id  , "Dragonlord1",     90,  75,  75, 100,   0,   0, 15, 15, 15,  0),
  [Dragonlord2Id  ] = Enemy(Dragonlord2Id  , "Dragonlord2",    140, 200, 150, 165,   0,   0, 15, 15, 15,  0),
}

function Enemy:oneRoundDamageRange(playerData)
  local atkPwr = playerData.stats.attackPower
  local enemyAgility = self.agility
  local agiDiv2 = enemyAgility / 2
  local z = math.max(0, atkPwr - agiDiv2)
  return {math.floor(z / 4), math.floor(z / 2)}
end

-- true if the enemy can be defeated (on average) in 3 turns or less.
function Enemy:canBeDefeatedByPlayer(playerData)
  local oneRoundDamageRange = self:oneRoundDamageRange(playerData)
  local minDamage = oneRoundDamageRange[1]
  local avgDamage = minDamage * 1.5
  return (self.hpMin + self.hpMax) / 2 < avgDamage * 3
end


Grind = class(function(a, location, enemy)
  a.location = location
  a.enemy = enemy
end)

function Grind:__tostring()
  return "Grinding: at: " .. tostring(self.location) .. ", vs: " .. tostring(self.enemy)
end

-- have we seen any enemies that we can kill (or have killed) ?
-- does that enemy give "good" experience (where good is 10% or more of what it takes to get to the next level)
--        hmmm.... .10% of the amount remaining? or 10% of the whole?
--    if that is true, then walk to one of the locs where we've seen that enemy and just walk back and forth
--    fighting it (and others) until we get to the next level
function getGrindInfo(playerData)
  local bestEnemy = nil
  for _, enemy in ipairs(Enemies) do
    if enemy:canBeDefeatedByPlayer(playerData) and
      #(enemy.locations) > 0 and
      (bestEnemy == nil or bestEnemy.exp < enemy.exp) and
      enemy.exp > playerData:totalXpToNextLevelFromCurrentLevel() * 0.1
    then bestEnemy = enemy
    end
  end
  if bestEnemy ~= nil
  then return Grind(chooseClosestTile(playerData.loc, bestEnemy.locations), bestEnemy)
  else return nil
  end
end

function chooseClosestTile(playerLoc, enemyLocations)
  print("picking closest tile to the player for grinding")
  local d = list.min(enemyLocations, function(t)
    return math.abs(t.x - playerLoc.x) + math.abs(t.y - playerLoc.y)
  end)
  return d
end

function Enemy:executeBattle(game)

  if not table.containsUsingDotEquals(self.locations, game:getLocation()) then
    table.insert(self.locations, game:getLocation())
    -- print("have now seen " .. self.name .. " at: ", tostring(self.locations))
  end

  function battleStarted() return game.inBattle end
  function battleEnded()
    -- print("self.enemyKilled", self.enemyKilled, "self.dead", self.dead, "self.inBattle: ", self.inBattle)
    return game.enemyKilled  -- i killed the enemy
      or   game.dead         -- the enemy killed me
      or   not game.inBattle -- the enemy ran
  end

  waitUntil(battleStarted, 120, "battle has started")

  local enemyCanBeDefeated =
    self:canBeDefeatedByPlayer(game:readPlayerData()) or self.id == MetalSlimeId

  print("canBeDefeatedByPlayer", enemyCanBeDefeated, "oneRoundDamageRange", self:oneRoundDamageRange(game:readPlayerData()))

  if enemyCanBeDefeated then
    holdAUntil(battleEnded, "battle has ended")
    waitFrames(180)
    pressA(10)
  else
    while not game.runSuccess and not game.dead do
      pressDown(2)
      pressA(60)
    end
  end

  print("xpToNextLevel: ", game:readPlayerData():xpToNextLevel(), "self.stats.level", game:readPlayerData().stats.level)
end