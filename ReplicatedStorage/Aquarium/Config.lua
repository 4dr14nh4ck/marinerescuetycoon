-- ReplicatedStorage/Aquarium/Config (ModuleScript)
local C = {

  -- Layout (relative to Pier/Deck forward/right)
  pathWidth = 6,
  pathThickness = 1,

  mainPierExtraLength = 160,  -- length after pier's tip along Deck Z

  branchEvery = 40,           -- spacing between left/right branches along main path
  branchLength = 42,          -- length of each branch from main path
  branchGapFromCenter = 3,    -- lateral gap from main path center to start of branch

  plotOffsetFromBranchEnd = 10,     -- distance from end of branch to plot/tank center
  plotSize = Vector3.new(30, 1, 22),

  tankSize = Vector3.new(18, 10, 12),
  glassThickness = 0.4,
  waterFillRatio = 0.65,

  -- pillars
  pillarMaterial = Enum.Material.Wood,
  pillarColor = Color3.fromRGB(128, 84, 44),
  pillarSize = Vector3.new(1.6, 12, 1.6),
  pillarSpacingAlong = 8,
  pillarInsetFromEdge = 1,

  -- upgrade sign
  signPostHeight = 5,
  signPostOffset  = 3,                         -- distance from tank side
  signBoardSize   = Vector3.new(6, 3, 0.2),
  signPromptDistance = 14,

  -- capacity / upgrades
  capacityStart = 6,
  capacityMax   = 60,
  upgradeBaseCost = 25,
  upgradeCostMul  = 1.6,
  upgradeStep     = 4,

  -- count
  useMaxPlayers   = true,
  maxSlotsOverride = 0,

  -- labels
  labelYOffset = 2, -- billboard over tank top

}
return C