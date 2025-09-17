-- ServerScriptService/Aquarium/VisualService.lua
local Players = game:GetService("Players")
local C = require(game.ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Config"))

local function allSlots()
	local farm = workspace:FindFirstChild("AquariumFarm")
	if not farm then return {} end
	local t = {}
	for _,m in ipairs(farm:GetChildren()) do
		if m:IsA("Model") and m.Name == "AquariumSlot" then table.insert(t, m) end
	end
	return t
end

local function fillWater(slot)
	if slot:FindFirstChild("TankWater") then return end
	local center = slot:FindFirstChild("CenterMarker"); if not center then return end
	local size = C.tankSize; local g = C.glassThickness; local half = size/2
	local waterHeight = (size.Y - g) * C.waterFillRatio
	local water = Instance.new("Part")
	water.Name = "TankWater"
	water.Anchored = true
	water.CanCollide = false
	water.Material = Enum.Material.SmoothPlastic
	water.Color = Color3.fromRGB(110,160,220)
	water.Transparency = 0.5
	water.Size = Vector3.new(size.X - g*2, waterHeight, size.Z - g*2)
	water.CFrame = center.CFrame * CFrame.new(0, -half.Y + g + waterHeight/2, 0)
	water.Parent = slot
end

local function clearWater(slot)
	local w = slot:FindFirstChild("TankWater")
	if w then w:Destroy() end
end

local function randomInWater(slot)
	local w = slot:FindFirstChild("TankWater"); if not w then return nil end
	local cf, sz = w.CFrame, w.Size
	local m = 0.9
	local half = sz/2 - Vector3.new(m,m,m)
	local function rnd(a,b) return a + math.random()*(b-a) end
	local lp = Vector3.new(rnd(-half.X,half.X), rnd(-half.Y,half.Y), rnd(-half.Z,half.Z))
	return (cf * CFrame.new(lp)).Position
end

local function spawnDisplayFish(slot, target)
	local df = slot:FindFirstChild("DisplayFish"); if not df then df = Instance.new("Folder"); df.Name="DisplayFish"; df.Parent=slot end
	local cap = slot:GetAttribute("Capacity") or C.capacityStart
	target = math.max(0, math.min(target, cap, 60))

	while #df:GetChildren() > target do
		df:GetChildren()[1]:Destroy()
	end

	local palette = {
		Color3.fromRGB(140,190,255), Color3.fromRGB(60,220,160), Color3.fromRGB(255,200,80),
		Color3.fromRGB(200,130,255), Color3.fromRGB(255,150,150),
	}

	while #df:GetChildren() < target do
		local pos = randomInWater(slot); if not pos then break end
		local p = Instance.new("Part")
		p.Name = "DisplayFish"
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(1.2,1.2,1.2)
		p.Material = Enum.Material.SmoothPlastic
		p.Color = palette[math.random(1,#palette)]
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = CFrame.new(pos)
		p.Parent = df
	end
end

local function onOwned(slot, plr)
	fillWater(slot)
	local ls = plr:FindFirstChild("leaderstats"); if not ls then return end
	local fishes = ls:FindFirstChild("Fish"); if not fishes then return end
	spawnDisplayFish(slot, fishes.Value)
	fishes:GetPropertyChangedSignal("Value"):Connect(function()
		spawnDisplayFish(slot, fishes.Value)
	end)
end

local function ownerFor(slot)
	local uid = slot:GetAttribute("OwnerUserId") or 0
	if uid == 0 then return nil end
	for _,plr in ipairs(Players:GetPlayers()) do if plr.UserId == uid then return plr end end
	return nil
end

for _,slot in ipairs(allSlots()) do
	local plr = ownerFor(slot)
	if plr then onOwned(slot, plr) else clearWater(slot) end
end

Players.PlayerAdded:Connect(function(plr)
	task.wait(0.2)
	for _,slot in ipairs(allSlots()) do
		if slot:GetAttribute("OwnerUserId") == plr.UserId then onOwned(slot, plr) end
	end
end)