-- ServerScriptService/Fish/FishSpawner
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Carpetas esperadas (ajústalas si en tu repo se llaman distinto)
local ZONES = Workspace:WaitForChild("WaterZones") -- Parts/Models que marcan agua
local MODELS = ReplicatedStorage:WaitForChild("FishModels") -- Modelos de peces listos para clonar

local MAX_FISH = 60
local INTERVAL = 6

local function getZones(): {BasePart}
	local t = {}
	for _, obj in ipairs(ZONES:GetDescendants()) do
		if obj:IsA("BasePart") then table.insert(t, obj) end
	end
	return t
end

local zones = getZones()
local function randomPosIn(part: BasePart): Vector3
	local size = part.Size
	local cf = part.CFrame
	local x = (math.random() - 0.5) * (size.X - 2)
	local z = (math.random() - 0.5) * (size.Z - 2)
	local y = (math.random() - 0.5) * math.max(2, math.min(6, size.Y)) -- ligera variación en Y
	return (cf * CFrame.new(x, y, z)).Position
end

local function spawnOne()
	if #Workspace:GetChildren() > 8_000 then return end -- seguridad
	local fishFolder = Workspace:FindFirstChild("Fish") or Instance.new("Folder")
	fishFolder.Name = "Fish"
	fishFolder.Parent = Workspace

	if #fishFolder:GetChildren() >= MAX_FISH then return end
	if #zones == 0 then return end

	-- Modelo aleatorio
	local candidates = {}
	for _, m in ipairs(MODELS:GetChildren()) do
		if m:IsA("Model") then table.insert(candidates, m) end
	end
	if #candidates == 0 then return end

	local model = candidates[math.random(1, #candidates)]:Clone()
	model:SetAttribute("Spawner", true)

	-- Zona aleatoria
	local zonePart = zones[math.random(1, #zones)]
	model:PivotTo(CFrame.new(randomPosIn(zonePart)))
	model.Parent = fishFolder

	-- Movimiento simple (si no tienes IA, baja gravedad/flotación)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.AssemblyLinearVelocity = Vector3.new( math.random(-2,2), math.random(-1,1), math.random(-2,2) )
		end
	end
end

task.spawn(function()
	while true do
		task.wait(INTERVAL)
		spawnOne()
	end
end)