-- ServerScriptService/Aquarium/UpgradeService (ModuleScript)
-- Refresca cartel/prompt y procesa upgrades con nuevo coste = capacidad_actual * 60

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("Aquarium"):WaitForChild("Config"))

local M = {}

-- Nuevo coste: 5 min (300s) * (1 ticket cada 5s por pez common) = 60 por pez
local function capacityCostFor(capacityNow)
	capacityNow = math.max(0, tonumber(capacityNow) or 0)
	return capacityNow * 60
end

local function farm() return workspace:FindChild("AquariumFarm") or workspace:FindFirstChild("AquariumFarm") end

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

local function slotOwner(slot)
	local uid = slot:GetAttribute("OwnerUserId") or 0
	if uid == 0 then return nil end
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr.UserId == uid then return plr end
	end
	return nil
end

local function applyTexts(slot, plr)
	local meta = slot:FindFirstChild("Meta"); if not meta then return end
	local lvl  = slot:GetAttribute("CapacityLevel") or 0
	local cap  = slot:GetAttribute("Capacity") or (C and C.capacityStart) or 6
	local cost = capacityCostFor(cap)

	-- Nombre/estado
	local nameLbl = meta:FindFirstChild("NameLabel")
	nameLbl = nameLbl and nameLbl.Value
	if nameLbl and nameLbl:IsA("TextLabel") then
		if plr then
			nameLbl.Text = string.format("%s", plr.DisplayName or plr.Name) -- sin Lv. X como pediste
		else
			nameLbl.Text = string.format("Free • Lv.%d", lvl)
		end
	end

	-- Caras del cartel
	local function setBoard(ref)
		local lbl = ref and ref.Value
		if lbl and lbl:IsA("TextLabel") then
			lbl.Text = ("UPGRADE CAPACITY\nCost: %d (+%d cap)"):format(cost, (C and C.upgradeStep) or 4)
		end
	end
	setBoard(meta:FindFirstChild("BoardFrontText"))
	setBoard(meta:FindFirstChild("BoardBackText"))

	-- Prompt
	local prRef  = meta:FindFirstChild("UpgradePrompt")
	local prompt = prRef and prRef.Value
	if prompt and prompt:IsA("ProximityPrompt") then
		pcall(function() prompt.PromptText = ("Cost: %d (+%d cap)"):format(cost, (C and C.upgradeStep) or 4) end)
		prompt.ActionText = "Upgrade"
		prompt.ObjectText = "Aquarium"
	end
end

local function bindPrompt(slot)
	local meta = slot:FindFirstChild("Meta"); if not meta then return end
	local prRef = meta:FindFirstChild("UpgradePrompt")
	local prompt = prRef and prRef.Value
	if not (prompt and prompt:IsA("ProximityPrompt")) then return end
	if prompt:GetAttribute("Bound") then
		M.Apply(slot, slotOwner(slot))
		return
	end

	prompt.Triggered:Connect(function(plr)
		if slot:GetAttribute("OwnerUserId") ~= plr.UserId then return end

		local lvl = slot:GetAttribute("CapacityLevel") or 0
		local cap = slot:GetAttribute("Capacity") or (C and C.capacityStart) or 6
		local maxCap = (C and C.capacityMax) or 9999
		if cap >= maxCap then return end

		local ls = plr:FindFirstChild("leaderstats"); if not ls then return end
		local tickets = ls:FindFirstChild("Tickets"); if not tickets then return end

		local cost = capacityCostFor(cap)
		if tickets.Value < cost then return end

		tickets.Value -= cost
		slot:SetAttribute("CapacityLevel", lvl + 1)
		slot:SetAttribute("Capacity", math.min(maxCap, cap + ((C and C.upgradeStep) or 4)))

		M.Apply(slot, plr)
	end)

	prompt:SetAttribute("Bound", true)
	M.Apply(slot, slotOwner(slot))
end

function M.Apply(slot, plr)
	applyTexts(slot, plr)
end

function M.BindAll()
	for _,slot in ipairs(allSlots()) do
		bindPrompt(slot)
	end
end

function M.BindSlot(slot)
	bindPrompt(slot)
end

-- safety: rebind
task.defer(function() M.BindAll() end)
workspace.ChildAdded:Connect(function(ch)
	if ch.Name == "AquariumFarm" then
		task.wait(0.1)
		M.BindAll()
	end
end)

return M