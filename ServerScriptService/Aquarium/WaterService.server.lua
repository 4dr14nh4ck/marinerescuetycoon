-- ServerScriptService/Aquarium/WaterService.server.lua
-- Rellena el TankRegion de cada AquariumSlot cuando se asigna OwnerUserId.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Utils"))

local Terrain = Workspace.Terrain

local function fillWater(slot)
	local tank = slot:FindFirstChild("TankRegion")
	if not tank or not tank:IsA("BasePart") then return end
	-- Limpia primero (por si re-asignan)
	Terrain:FillBlock(tank.CFrame, tank.Size, Enum.Material.Air)
	-- Rellena con agua
	Terrain:FillBlock(tank.CFrame, tank.Size, Enum.Material.Water)
end

local function onOwnerChanged(slot)
	if slot:GetAttribute("OwnerUserId") then
		fillWater(slot)
	end
end

local function bindSlot(slot)
	if not (slot:IsA("Model") or slot:IsA("Folder")) then return end
	slot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		onOwnerChanged(slot)
	end)
	-- si ya viene asignado
	if slot:GetAttribute("OwnerUserId") then fillWater(slot) end
end

local function init()
	local root = Utils.GetAquariumsFolder() or Workspace:FindFirstChild("AquariumFarm")
	if not root then return end
	for _, s in ipairs(root:GetChildren()) do bindSlot(s) end
	root.ChildAdded:Connect(bindSlot)
end

init()
print("[WaterService] Ready")