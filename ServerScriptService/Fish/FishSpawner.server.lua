--!strict
-- ServerScriptService/Fish/FishSpawner.server.lua
-- Spawner: anillo pequeño alrededor del muelle, altura fija bajo superficie,
-- sin solapes, nunca bajo el muelle; 1 pez por ciclo cada pocos segundos.
-- Visual: peces con color por rareza; marcador de superficie = "burbujas" 3D estáticas.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Fish"):WaitForChild("FishConfig"))

-- Carpeta de peces en Workspace
local fishFolder: Folder = Workspace:FindFirstChild("Fish") :: Folder
if not fishFolder then
	fishFolder = Instance.new("Folder")
	fishFolder.Name = "Fish"
	fishFolder.Parent = Workspace
end

-- Cache de posiciones para evitar solapes
local fishPositions: { [BasePart]: Vector3 } = {}

-- Semilla RNG segura
do
	local seedStr = (tostring(os.clock()):gsub("%D", ""))
	local seed = tonumber(seedStr) or os.time()
	math.randomseed(seed)
	for _ = 1, 3 do math.random() end
end

-- Centro del anillo (Pier si existe; si no, default)
local function getSpawnCenter(): Vector3
	local pier = Workspace:FindFirstChild(FishConfig.PierName)
	if pier then
		if pier:IsA("Model") then
			local cf = (pier :: Model):GetBoundingBox()
			return cf.Position
		elseif pier:IsA("BasePart") then
			return (pier :: BasePart).Position
		end
	end
	return FishConfig.Spawn.Area.DefaultCenter
end

-- ¿Hay muelle sobre este punto?
local function isUnderPier(pos: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.IgnoreWater = true
	params.FilterDescendantsInstances = { fishFolder }

	local result = Workspace:Raycast(pos, Vector3.new(0, 300, 0), params)
	if not result or not result.Instance then
		return false
	end
	local inst = result.Instance
	while inst do
		if inst.Name == FishConfig.PierName then
			return true
		end
		inst = inst.Parent
	end
	return false
end

-- Y de la superficie del agua en (x, z). Nil si no hay agua en ese XZ.
local function getWaterSurfaceY(x: number, z: number): number?
	local params = RaycastParams.new()
	params.IgnoreWater = false
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { fishFolder }

	local origin = Vector3.new(x, 1000, z)
	local dir = Vector3.new(0, -2000, 0)
	local hit = Workspace:Raycast(origin, dir, params)
	if hit and hit.Material == Enum.Material.Water then
		return hit.Position.Y
	end
	return nil
end

local function violatesMinDistance(candidate: Vector3): boolean
	local minDist = FishConfig.Spawn.MinDistanceBetweenFish
	for _, p in pairs(fishPositions) do
		if (p - candidate).Magnitude < minDist then
			return true
		end
	end
	return false
end

local function pickRarity(): string
	local weights = {
		{ name = "Common",   w = FishConfig.Rarity.Common.Weight },
		{ name = "Uncommon", w = FishConfig.Rarity.Uncommon.Weight },
		{ name = "Rare",     w = FishConfig.Rarity.Rare.Weight },
	}
	local total = 0
	for _, r in ipairs(weights) do total += r.w end
	local pick = math.random(1, total)
	local acc = 0
	for _, r in ipairs(weights) do
		acc += r.w
		if pick <= acc then
			return r.name
		end
	end
	return "Common"
end

-- Crea "burbujas" estáticas (3D) sobre la superficie: varias esferas apiladas
local function createStaticBubbleMarker(parentPart: BasePart, surfacePos: Vector3)
	if not FishConfig.Spawn.SurfaceMarker.Enabled then return end

	local conf = FishConfig.Spawn.SurfaceMarker
	local bconf = conf.Bubbles

	-- Contenedor para mantener todo unido (hijo del pez)
	local group = Instance.new("Folder")
	group.Name = "SurfaceBubbles"
	group.Parent = parentPart

	local baseY = surfacePos.Y + conf.AboveSurfaceOffset
	local radius = bconf.Radius
	local spacing = bconf.VerticalSpacing
	local cluster = bconf.ClusterOffset

	-- Pequeño patrón en cruz (↑, →, ←) para dar “cluster”
	local positions = {
		Vector3.new(surfacePos.X, baseY, surfacePos.Z),                                -- centro
		Vector3.new(surfacePos.X + cluster, baseY + spacing, surfacePos.Z),            -- derecha
		Vector3.new(surfacePos.X - cluster, baseY + spacing * 2, surfacePos.Z),        -- izquierda
	}

	-- Si Count < 3, recortamos; si > 3, extendemos verticalmente
	local count = math.max(1, bconf.Count)
	for i = 1, count do
		local idx = math.min(i, #positions)
		local pos = positions[idx]
		if i > #positions then
			pos = Vector3.new(surfacePos.X, baseY + spacing * (i - 1), surfacePos.Z)
		end

		local bubble = Instance.new("Part")
		bubble.Name = "Bubble_" .. i
		bubble.Shape = Enum.PartType.Ball
		bubble.Anchored = true
		bubble.CanCollide = conf.CanCollide
		bubble.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
		bubble.Material = conf.Material
		bubble.Color = conf.Color
		bubble.Transparency = conf.Transparency
		bubble.CastShadow = false
		bubble.CFrame = CFrame.new(pos)
		bubble.Parent = group
	end
end

local function trySpawnOne(): boolean
	-- Límite de población
	if #fishFolder:GetChildren() >= FishConfig.Spawn.MaxFishAlive then
		return false
	end

	local center = getSpawnCenter()
	local area = FishConfig.Spawn.Area

	-- Uniforme en anillo [RadiusMin, RadiusMax)
	local angle = math.random() * math.pi * 2
	local radius = area.RadiusMin + math.random() * (area.RadiusMax - area.RadiusMin)
	local x = center.X + math.cos(angle) * radius
	local z = center.Z + math.sin(angle) * radius

	-- Superficie del agua en este XZ
	local surfaceY = getWaterSurfaceY(x, z)
	if not surfaceY then
		return false
	end

	-- Altura fija: misma profundidad bajo la superficie
	local depth = FishConfig.Spawn.FixedDepthBelowSurface
	local fishPos = Vector3.new(x, surfaceY - depth, z)

	-- Seguridad
	if isUnderPier(fishPos) then return false end
	if violatesMinDistance(fishPos) then return false end

	-- Pez con color por rareza
	local rarity = pickRarity()
	local rarityData = FishConfig.Rarity[rarity]

	local part = Instance.new("Part")
	part.Name = "Fish_" .. rarity
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(FishConfig.Spawn.FishRadius * 2, FishConfig.Spawn.FishRadius * 2, FishConfig.Spawn.FishRadius * 2)
	part.Material = FishConfig.Spawn.FishMaterial
	part.Color = rarityData.Color
	part.Transparency = FishConfig.Spawn.FishTransparency
	part.CastShadow = false
	part.CFrame = CFrame.new(fishPos)
	part:SetAttribute("Rarity", rarity)
	part.Parent = fishFolder

	-- Guardar posición (anti-solape) y limpiar
	fishPositions[part] = fishPos
	part.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			fishPositions[part] = nil
		end
	end)

	-- Marcador de "burbujas" 3D estáticas (uniforme, no revela rareza)
	createStaticBubbleMarker(part, Vector3.new(x, surfaceY, z))

	return true
end

-- Bucle de spawn, 1 intento por tick, con jitter leve
task.spawn(function()
	local base = FishConfig.Spawn.SpawnIntervalSeconds
	while true do
		local spawned = trySpawnOne()
		local dt = math.max(0.4, base + (math.random() - 0.5) * 0.6) -- ±0.3s
		if not spawned then
			dt = math.max(0.2, dt * 0.5)
		end
		task.wait(dt)
	end
end)