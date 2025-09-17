-- ServerScriptService/Fish/CatchService.lua
-- CURE/RELEASE con capacidad, ocupación y perfil por rareza

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RS = game:GetService("ReplicatedStorage")

local Profiles = require(RS:WaitForChild("Aquarium"):WaitForChild("Profiles"))

-- Events
local evFolder = ReplicatedStorage:FindFirstChild("FishEvents") or Instance.new("Folder")
evFolder.Name = "FishEvents"; evFolder.Parent = ReplicatedStorage
local CatchPrompt   = evFolder:FindFirstChild("CatchPrompt")   or Instance.new("RemoteEvent"); CatchPrompt.Name="CatchPrompt";   CatchPrompt.Parent=evFolder
local CatchDecision = evFolder:FindFirstChild("CatchDecision") or Instance.new("RemoteEvent"); CatchDecision.Name="CatchDecision"; CatchDecision.Parent=evFolder
local CatchFeedback = evFolder:FindFirstChild("CatchFeedback") or Instance.new("RemoteEvent"); CatchFeedback.Name="CatchFeedback"; CatchFeedback.Parent=evFolder

local RECOVERY_TIME = 30
local CAPACITY_START = 6

local function allSlots()
	local farm = workspace:FindFirstChild("AquariumFarm"); if not farm then return {} end
	local t = {}
	for _,m in ipairs(farm:GetChildren()) do
		if m:IsA("Model") and m.Name == "AquariumSlot" then table.insert(t, m) end
	end
	return t
end

local function playerSlot(plr)
	for _,slot in ipairs(allSlots()) do
		if slot:GetAttribute("OwnerUserId") == plr.UserId then return slot end
	end
	return nil
end

local function recoveringCount(plr)
	local rec = plr:FindFirstChild("Recovery")
	return rec and #rec:GetChildren() or 0
end

local function ensureStats(plr)
	local ls = plr:FindFirstChild("leaderstats"); if not ls then
		ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	end
	local fish = ls:FindFirstChild("Fish") or Instance.new("IntValue"); fish.Name="Fish"; fish.Parent=ls
	local tickets = ls:FindFirstChild("Tickets") or Instance.new("IntValue"); tickets.Name="Tickets"; tickets.Parent=ls

	local rec = plr:FindFirstChild("Recovery"); if not rec then
		rec = Instance.new("Folder"); rec.Name = "Recovery"; rec.Parent = plr
	end
	if plr:GetAttribute("HasActiveCatch") == nil then plr:SetAttribute("HasActiveCatch", false) end
	return fish, tickets, rec
end

local function capacityOf(slot)
	if not slot then return 0 end
	local cap = slot:GetAttribute("Capacity")
	if (cap == nil) or (cap <= 0) then slot:SetAttribute("Capacity", CAPACITY_START); cap = CAPACITY_START end
	if slot:GetAttribute("CapacityLevel") == nil then slot:SetAttribute("CapacityLevel", 0) end
	if slot:GetAttribute("Occupancy") == nil then slot:SetAttribute("Occupancy", 0) end
	return cap
end

CatchDecision.OnServerEvent:Connect(function(player, decision, rarity, recoveryTimeOverride)
	local fishLS, _, rec = ensureStats(player)
	local slot = playerSlot(player)

	if player:GetAttribute("HasActiveCatch") ~= true then return end
	local myRecoveryTime = tonumber(recoveryTimeOverride) or RECOVERY_TIME
	rarity = rarity or "Common"

	if decision == "CURE" then
		local cap = capacityOf(slot)
		local occ = slot and (slot:GetAttribute("Occupancy") or 0) or 0
		local used = occ + recoveringCount(player)

		if used >= cap then
			CatchFeedback:FireClient(player, { type="ERROR", code="TANK_FULL", message="Tank is full — upgrade capacity to cure more fish." })
			player:SetAttribute("HasActiveCatch", false)
			return
		end

		local marker = Instance.new("StringValue")
		marker.Name = "Recovering_" .. rarity
		marker.Value = tostring(os.time())
		marker:SetAttribute("Rarity", rarity)
		marker:SetAttribute("EndsAt", os.time() + myRecoveryTime)
		marker.Parent = rec

		task.delay(myRecoveryTime, function()
			if marker and marker.Parent then marker:Destroy() end

			-- Perfil por rareza + totales
			Profiles.AddFishByRarity(player.UserId, rarity, 1)
			Profiles.Save(player.UserId) -- debounced

			-- Sincroniza leaderstats (Fish total)
			local p = Profiles.Get(player.UserId)
			fishLS.Value = p.fish

			-- Ocupación visible del slot
			if slot and slot.Parent then
				slot:SetAttribute("Occupancy", (slot:GetAttribute("Occupancy") or 0) + 1)
			end
		end)

	elseif decision == "RELEASE" or decision == "TIMEOUT" then
		-- sin recompensa por ahora
	end

	player:SetAttribute("HasActiveCatch", false)
end)
