-- ServerScriptService/Aquarium/AutoUpgradeBinder.server.lua
-- Enlaza TODOS los ProximityPrompt del plot (horneados en UpgradeBoard) y muestra el coste real.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Utils"))

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local Profiles = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local function dsKey(uid) return "u_"..tostring(uid) end
local function toInt(n) if typeof(n)~="number" then return 0 end return math.max(0, math.floor(n+0.5)) end
local function capacityOf(data) return toInt(data.capacity or (6 + 4 * toInt(data.capacityLevel or 0))) end
local function upgradeCost(capacity) return toInt(capacity * 48) end
local function ownerOf(plot) return plot:GetAttribute("OwnerUserId") end

local function updatePromptText(pp, userId)
	if not userId then
		pp.ObjectText = "Acuario"
		pp.ActionText = "Mejorar"
		return
	end
	local ok, data = pcall(function() return Profiles:GetAsync(dsKey(userId)) end)
	data = ok and type(data)=="table" and data or {}
	local cost = upgradeCost(capacityOf(data))
	pp.ObjectText = "Acuario"
	pp.ActionText = ("Mejorar (+4) – %d tickets"):format(cost)
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = math.max(pp.MaxActivationDistance, 10)
end

local function bindOne(pp, plot)
	if pp:GetAttribute("UpgradeBound") then return end
	pp:SetAttribute("UpgradeBound", true)
	updatePromptText(pp, ownerOf(plot))
	plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		updatePromptText(pp, ownerOf(plot))
	end)
	pp.Triggered:Connect(function(player)
		if _G.AquariumUpgrade and _G.AquariumUpgrade.TryUpgrade then
			local ok, msg = _G.AquariumUpgrade.TryUpgrade(player)
			updatePromptText(pp, ownerOf(plot))
			if not ok then warn("[Upgrade] "..tostring(msg)) end
		else
			warn("[Upgrade] _G.AquariumUpgrade.TryUpgrade no disponible")
		end
	end)
end

local function scanAndBind()
	local root = Utils.GetAquariumsFolder()
	if not root then warn("[AutoUpgradeBinder] Raíz de acuarios no encontrada"); return end
	for _, plot in ipairs(Utils.GetAllSlots(root)) do
		local prompts = Utils.FindPrompts(plot)
		if #prompts == 0 then
			-- crear uno mínimo en el ancla, como fallback
			local anchor = Utils.FindAnchor(plot)
			if anchor then
				local a = Instance.new("Attachment")
				a.Name = "UpgradeAttachment"
				a.Parent = anchor
				local pp = Instance.new("ProximityPrompt")
				pp.Name = "Upgrade"
				pp.HoldDuration = 0.25
				pp.MaxActivationDistance = 10
				pp.RequiresLineOfSight = false
				pp.Parent = a
				table.insert(prompts, pp)
			end
		end
		for _, pp in ipairs(prompts) do bindOne(pp, plot) end
	end
end

task.defer(scanAndBind)
print("[AutoUpgradeBinder] Ready")