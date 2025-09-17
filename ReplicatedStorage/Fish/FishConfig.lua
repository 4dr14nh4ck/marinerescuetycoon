local Config = {
	-- ===== Spawn =====
	spawnRadius = 60,
	spawnOffsetForward = -50,
	waterLevelY = -8,
	fishHover = 2,
	spawnInterval = 4.0,
	maxFishInWorld = 12,

	-- Evitar muelle
	avoidUnderPier = true,
	deckPadding = 2,

	-- Rarezas (ocultas hasta captura)
	rarityWeights = {
		Common   = {70, Color3.fromRGB(140,190,255)},
		Uncommon = {25, Color3.fromRGB(60,220,160)},
		Rare     = {5,  Color3.fromRGB(255,200,80)},
	},

	-- ===== Red (click-to-throw) =====
	maxThrowDistance = 120,
	captureRadius = 5.0,
	netCooldown = 0.6,

	-- ===== Curación / Tickets =====
	recoveryTime = 30,
	ticketInterval = 10,
	ticketsPerFish = 1,

	-- ===== Burbujas superficiales (visibles) =====
	bubbleHeight = 1.2,
	bubbleRate = 12,                             -- más partículas
	bubbleLifetime = NumberRange.new(1.0, 1.6),
	bubbleSpeed = NumberRange.new(1.0, 1.6),
	bubbleTexture = "",                          -- vacío = textura por defecto (confiable)
	bubbleSize = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.65),
		NumberSequenceKeypoint.new(1, 0.15),
	}),
	bubbleColor = ColorSequence.new(Color3.fromRGB(220,240,255)),

	-- Carpetas / nombres
	folderName = "Fish",
	eventsFolderName = "FishEvents",
	toolName = "Net",

	-- ===== Debug =====
	debugShowFish = true,      -- déjalo true para verificar; luego pásalo a false
	waitForDeckSeconds = 8,
}
return Config