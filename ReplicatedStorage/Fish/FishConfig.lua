--!strict
-- ReplicatedStorage/Fish/FishConfig.lua
-- Peces con color por rareza; marcadores "burbujas" estáticas (geometría 3D)

local Config = {}

-- Nombre del muelle en Workspace
Config.PierName = "Pier"

Config.Spawn = {
	Area = {
		DefaultCenter = Vector3.new(0, 0, 0),
		RadiusMin = 40,
		RadiusMax = 85,
	},

	-- Profundidad fija bajo la superficie (sin variación en Y)
	FixedDepthBelowSurface = 2.0, -- studs

	-- Población y timing
	MaxFishAlive = 18,
	SpawnIntervalSeconds = 2.6, -- 1 pez por ciclo (con ligero jitter)

	-- Anti-solape
	MinDistanceBetweenFish = 8,

	-- Apariencia del pez (pequeño)
	FishRadius = 1.0,
	FishTransparency = 0.06,
	FishMaterial = Enum.Material.Neon,

	-- Marcador en superficie: "burbujas" estáticas (Partes 3D)
	SurfaceMarker = {
		Enabled = true,
		Color = Color3.fromRGB(240, 250, 255), -- uniforme (no revela rareza)
		Transparency = 0.0,
		Material = Enum.Material.Neon,
		CanCollide = false,
		AboveSurfaceOffset = 0.35,  -- altura de la primera burbuja sobre la lámina

		-- Burbujas apiladas
		Bubbles = {
			Count = 3,             -- cuántas esferas
			Radius = 0.35,         -- radio de cada esfera
			VerticalSpacing = 0.22, -- separación entre centros
			-- patrón de pequeña cruz para dar “cluster”
			ClusterOffset = 0.12,  -- desplazamiento horizontal leve
		}
	},
}

-- Rarezas: colores/weights para distribución; tiempos para mecánicas
Config.Rarity = {
	Common   = { Color = Color3.fromRGB(102, 204, 255), Weight = 70, CureSeconds = 20, PassivePerTick = 1 },
	Uncommon = { Color = Color3.fromRGB(135, 255, 135), Weight = 25, CureSeconds = 30, PassivePerTick = 2 },
	Rare     = { Color = Color3.fromRGB(255, 170, 85),  Weight = 5,  CureSeconds = 40, PassivePerTick = 3 },
}

return Config