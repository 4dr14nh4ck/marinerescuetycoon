-- ServerScriptService/Aquarium/OwnershipService.lua
if _G.__OWNERSHIP_RUNNING then return end
_G.__OWNERSHIP_RUNNING = true

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local Profiles  = require(RS:WaitForChild("Aquarium"):WaitForChild("Profiles"))
local UpgradeService = require(game.ServerScriptService.Aquarium.UpgradeService)

local function farm() return workspace:FindFirstChild("AquariumFarm") end

local function allSlots()
	local f = farm(); if not f then return {} end
	local t = {}
	for _,m in ipairs(f:GetChildren()) do
		if m:IsA("Model") and m.Name == "AquariumSlot" then
			table.insert(t, m)
		end
	end
	return t
end

local function sortedSlots()
	local t = allSlots()
	table.sort(t, function(a,b)
		local ia = a:GetAttribute("SlotIndex") or 10^9
		local ib = b:GetAttribute("SlotIndex") or 10^9
		if ia ~= ib then return ia < ib end
		return (a.Name or "") < (b.Name or "")
	end)
	return t
end

local function playerSlot(plr)
	for _,s in ipairs(allSlots()) do
		if s:GetAttribute("OwnerUserId") == plr.UserId then return s end
	end
	return nil
end

local function findFreeSlot()
	for _,s in ipairs(sortedSlots()) do
		if (s:GetAttribute("OwnerUserId") or 0) == 0 then
			return s
		end
	end
	return nil
end

-- visuals
local function setBillboard(slot, text)
	local c  = slot:FindFirstChild("CenterMarker")
	local bb = c and c:FindFirstChild("OwnerBillboard")
	local lbl = bb and bb:FindFirstChildOfClass("TextLabel")
	if lbl then lbl.Text = text end
end

local function setUpgradePrompt(slot, enabled)
	local board = slot:FindFirstChild("UpgradeBoard", true)
	if not board then return end
	local prompt = board:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Enabled   = enabled
		prompt.ActionText = "Upgrade"
		prompt.ObjectText = "Aquarium"
	end
end

local function fillWater(slot)
	if slot:FindFirstChild("TankWater") then return end
	local center = slot:FindFirstChild("CenterMarker"); if not center then return end
	local size = Vector3.new(18,10,12)
	local g = 0.4
	local h = (size.Y - g) * 0.65
	local w = Instance.new("Part")
	w.Name = "TankWater"
	w.Size = Vector3.new(size.X - g*2, h, size.Z - g*2)
	w.Anchored = true
	w.CanCollide = false
	w.Material = Enum.Material.SmoothPlastic
	w.Color = Color3.fromRGB(110,160,220)
	w.Transparency = 0.5
	w.CFrame = center.CFrame * CFrame.new(0, -size.Y/2 + g + h/2, 0)
	w.Parent = slot
end

local function clearVisuals(slot)
	local w = slot:FindFirstChild("TankWater"); if w then w:Destroy() end
	local df = slot:FindFirstChild("DisplayFish"); if df then
		for _,c in ipairs(df:GetChildren()) do c:Destroy() end
	end
end

-- leaderstats (inglés)
local function ensureLeaderstats(plr, fishValue, ticketsValue)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr end

	local fish = ls:FindFirstChild("Fish") or Instance.new("IntValue"); fish.Name = "Fish"; fish.Parent = ls
	local tks  = ls:FindFirstChild("Tickets") or Instance.new("IntValue"); tks.Name = "Tickets"; tks.Parent = ls

	local old = ls:FindFirstChild("Peces")
	if old then if fish.Value == 0 then fish.Value = old.Value end; old:Destroy() end

	if typeof(fishValue) == "number"    then fish.Value = fishValue end
	if typeof(ticketsValue) == "number" then tks.Value  = ticketsValue end
end

-- core apply
local function applyProfileToSlot(slot, prof, plr)
	slot:SetAttribute("Capacity",      tonumber(prof.capacity) or 6)
	slot:SetAttribute("CapacityLevel", tonumber(prof.capacityLevel) or 0)
	slot:SetAttribute("Occupancy",     tonumber(prof.fish) or 0)

	if plr then
		slot:SetAttribute("OwnerUserId", plr.UserId)
		fillWater(slot)
		-- SIN LV en el label
		setBillboard(slot, (plr.DisplayName or plr.Name))
		setUpgradePrompt(slot, true)
	else
		slot:SetAttribute("OwnerUserId", 0)
		clearVisuals(slot)
		setBillboard(slot, "Free") -- sin Lv
		setUpgradePrompt(slot, false)
	end

	UpgradeService.BindSlot(slot)
	UpgradeService.Apply(slot, plr)
end

local function setOwner(slot, plr)
	local p = Profiles.Get(plr.UserId)
	applyProfileToSlot(slot, p, plr)
	ensureLeaderstats(plr, p.fish, p.tickets)
end

local function clearOwner(slot)
	applyProfileToSlot(slot, {
		fish = 0,
		capacity = slot:GetAttribute("Capacity") or 6,
		capacityLevel = slot:GetAttribute("CapacityLevel") or 0
	}, nil)
end

local function enforceSingleSlot(plr)
	local owned = {}
	for _,s in ipairs(allSlots()) do
		if s:GetAttribute("OwnerUserId") == plr.UserId then table.insert(owned, s) end
	end
	if #owned > 1 then
		table.sort(owned, function(a,b)
			return (a:GetAttribute("SlotIndex") or 10^9) < (b:GetAttribute("SlotIndex") or 10^9)
		end)
		for i = 2, #owned do clearOwner(owned[i]) end
	end
end

-- startup normalize
task.defer(function()
	for _,s in ipairs(allSlots()) do
		local uid = s:GetAttribute("OwnerUserId") or 0
		if uid ~= 0 then
			if not Players:GetPlayerByUserId(uid) then
				clearOwner(s)
			else
				local plr = Players:GetPlayerByUserId(uid)
				UpgradeService.BindSlot(s)
				UpgradeService.Apply(s, plr)
			end
		else
			applyProfileToSlot(s, {
				fish = 0,
				capacity = s:GetAttribute("Capacity") or 6,
				capacityLevel = s:GetAttribute("CapacityLevel") or 0
			}, nil)
		end
	end
end)

-- lifecycle
Players.PlayerAdded:Connect(function(plr)
	task.defer(function()
		local _ = Profiles.Get(plr.UserId)
		local slot = playerSlot(plr)
		if slot then setOwner(slot, plr) else
			local free = findFreeSlot(); if free then setOwner(free, plr) end
		end
		enforceSingleSlot(plr)
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	local s = playerSlot(plr)
	if s then clearOwner(s) end
	Profiles.Save(plr.UserId, true)
end)

task.spawn(function()
	while true do
		for _,plr in ipairs(Players:GetPlayers()) do
			enforceSingleSlot(plr)
		end
		task.wait(5)
	end
end)