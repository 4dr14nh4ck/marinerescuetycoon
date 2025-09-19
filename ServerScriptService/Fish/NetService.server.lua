--!strict
-- Lógica autoritativa de la Tool "Net": cooldown, alcance y detección de peces.
-- Envía CatchFeedback como STRINGS (compat con tu CatchUI) y CatchPrompt en acierto.
-- También envía ThrowResult con la posición de impacto para feedback visual cliente.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FishSignals = require(ReplicatedStorage:WaitForChild("Fish"):WaitForChild("FishSignals"))

-- Ajustes
local DEBUG      = true
local COOLDOWN   = 1.2      -- s
local MAX_RANGE  = 60.0     -- studs
local NET_RADIUS = 2.0      -- “grosor” del rayo

local FISH_FOLDER = Workspace:FindFirstChild("Fish") or Instance.new("Folder")
if not FISH_FOLDER.Parent then
	FISH_FOLDER.Name = "Fish"
	FISH_FOLDER.Parent = Workspace
end

local function dbg(...) if DEBUG then print("[NetService]", ...) end end

-- Sube por ancestros hasta encontrar el BasePart del pez con atributo "Rarity"
local function getFishRoot(inst: Instance?): (BasePart?, string?)
	local cur: Instance? = inst
	while cur do
		if cur:IsA("BasePart") and (cur :: BasePart):GetAttribute("Rarity") ~= nil then
			return cur :: BasePart, (cur :: BasePart):GetAttribute("Rarity")
		end
		cur = cur.Parent
	end
	return nil, nil
end

-- ¿la instancia pertenece a un pez en Workspace/Fish?
local function isInFishFamily(inst: Instance?): boolean
	return inst ~= nil and inst:IsDescendantOf(FISH_FOLDER)
end

-- Raycast con “grosor” y devuelve (pezPart, rarity, hitPosition)
local function castForFish(origin: Vector3, direction: Vector3): (BasePart?, string?, Vector3)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.IgnoreWater = false
	params.FilterDescendantsInstances = {}

	-- rayo principal
	local res = Workspace:Raycast(origin, direction, params)
	if res then
		if isInFishFamily(res.Instance) then
			local root, rarity = getFishRoot(res.Instance)
			if root then return root, rarity, res.Position end
		end
	end

	-- grosor (cruz alrededor del rayo)
	local dir = direction
	local perpA = Vector3.new(0,1,0):Cross(dir)
	if perpA.Magnitude < 0.001 then perpA = Vector3.new(1,0,0) end
	perpA = perpA.Unit
	local perpB = dir:Cross(perpA).Unit
	for _, off in ipairs({ perpA*NET_RADIUS, -perpA*NET_RADIUS, perpB*NET_RADIUS, -perpB*NET_RADIUS }) do
		local res2 = Workspace:Raycast(origin + off, dir, params)
		if res2 and isInFishFamily(res2.Instance) then
			local root2, rarity2 = getFishRoot(res2.Instance)
			if root2 then return root2, rarity2, res2.Position end
		end
	end

	-- Sin pez: devolvemos un punto de impacto del mundo para feedback
	if res then
		return nil, nil, res.Position
	else
		return nil, nil, origin + direction
	end
end

local lastThrow: {[Player]: number} = {}

local function onThrowRequest(player: Player, payload: any)
	dbg("ThrowRequest from", player and player.Name or "?", payload)

	-- Cooldown
	local now = time()
	if now - (lastThrow[player] or 0) < COOLDOWN then
		local left = COOLDOWN - (now - (lastThrow[player] or 0))
		dbg("Cooldown", string.format("%.2fs left", left))
		-- opcional: notificar al cliente si quieres bloquear inputs
		return
	end

	-- Validación payload
	if type(payload) ~= "table" or typeof(payload.origin) ~= "Vector3" or typeof(payload.direction) ~= "Vector3" then
		dbg("Invalid payload")
		return
	end

	-- Clamp rango
	local dir = payload.direction
	if dir.Magnitude <= 0 then return end
	local clamped = dir.Unit * math.min(dir.Magnitude, MAX_RANGE)

	-- Raycast autoritativo
	local fishPart, rarity, hitPos = castForFish(payload.origin, clamped)
	lastThrow[player] = now

	if fishPart then
		dbg("HIT", fishPart:GetFullName(), "rarity:", rarity)
		-- Feedback técnico + posición (cliente hará visual)
		FishSignals.ThrowResult:FireClient(player, { ok = true, hit = true, pos = hitPos, cooldown = COOLDOWN })
		-- Compat con tu CatchUI: strings, no tablas
		FishSignals.CatchFeedback:FireClient(player, "Hit", "¡Has atrapado un pez!")
		-- Abrir UI de decisión
		FishSignals.CatchPrompt:FireClient(player, {
			Fish = fishPart,
			Rarity = rarity,
		})
	else
		dbg("MISS")
		FishSignals.ThrowResult:FireClient(player, { ok = true, hit = false, pos = hitPos, cooldown = COOLDOWN })
		-- Compat con tu CatchUI: strings
		FishSignals.CatchFeedback:FireClient(player, "Miss", "Fallaste la captura.")
	end
end

Players.PlayerRemoving:Connect(function(plr) lastThrow[plr] = nil end)
FishSignals.ThrowRequest.OnServerEvent:Connect(onThrowRequest)

dbg(string.format("Ready (cooldown=%.1fs, range=%.0f, thickness=%.1f)", COOLDOWN, MAX_RANGE, NET_RADIUS))