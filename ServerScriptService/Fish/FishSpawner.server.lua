--!strict
-- Spawner que ubica peces sobre agua de Terrain (Material.Water)
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage.Fish:WaitForChild("FishConfig"))

local fishFolder = Workspace:FindFirstChild("Fish") or Instance.new("Folder")
fishFolder.Name = "Fish"
fishFolder.Parent = Workspace

local params = RaycastParams.new()
params.IgnoreWater = false
params.FilterType = Enum.RaycastFilterType.Blacklist
params.FilterDescendantsInstances = {fishFolder}

local function randomXZ(radius: number): (number, number)
	return math.random(-radius, radius), math.random(-radius, radius)
end

local function findWaterPosition(radius: number): Vector3?
	for _ = 1, 40 do
		local rx, rz = randomXZ(radius)
		local origin = Vector3.new(rx, 500, rz)
		local dir = Vector3.new(0, -1000, 0)
		local hit = Workspace:Raycast(origin, dir, params)
		if hit and hit.Material == Enum.Material.Water then
			return hit.Position + Vector3.new(0, 1.5, 0)
		end
	end
	return nil
end

local function spawnOne()
	if #fishFolder:GetChildren() >= FishConfig.MaxFishInWorld then return end
	local pos = findWaterPosition(FishConfig.WorldRadius)
	if not pos then return end

	-- Si en el futuro usas modelos, reemplaza este Part por un Model clon.
	local fish = Instance.new("Part")
	fish.Name = "Fish"
	fish.Size = Vector3.new(1,1,2)
	fish.Anchored = false
	fish.CanCollide = false
	fish.Position = pos
	fish.Parent = fishFolder
	fish.AssemblyLinearVelocity = Vector3.new(math.random(-3,3), math.random(-1,1), math.random(-3,3))
end

task.spawn(function()
	while true do
		task.wait(FishConfig.SpawnInterval)
		spawnOne()
	end
end)