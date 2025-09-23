-- ServerScriptService/Aquarium/AutoUpgradeBinder.server.lua
-- Reutiliza prompts horneados si existen; si no, crea uno en el ancla.
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Config"))

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local Profiles = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local function dsKey(uid) return "u_"..tostring(uid) end
local function toInt(n) if typeof(n)~="number" then return 0 end return math.max(0, math.floor(n+0.5)) end
local function capacityOf(data) return toInt(data.capacity or (6 + 4 * toInt(data.capacityLevel or 0))) end
local function upgradeCost(capacity) return toInt(capacity * 48) end

local function root()
	for _, n in ipairs(Config.ROOT_CANDIDATES) do
		local r = Workspace:FindFirstChild(n)
		if r then return r end
	end
	return nil
end

local function findAnchor(plot)
	local b = plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
	if b then return b end
	for _, name in ipairs(Config.ANCHOR_CANDIDATES) do
		local obj = plot:FindFirstChild(name, true)
		if obj and obj:IsA("BasePart") then return obj end
	end
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

local function ownerOf(plot) return plot:GetAttribute("OwnerUserId") end

local function findExistingPrompt(plot)
	for _, name in ipairs(Config.PROMPT_CANDIDATES) do
		local obj = plot:FindFirstChild(name, true)
		if obj and obj:IsA("ProximityPrompt") then return obj end
	end
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("ProximityPrompt") then return d end
	end
	return nil
end

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
end

local function ensurePrompt(plot)
	local pp = findExistingPrompt(plot)
	if pp then return pp end
	local anchor = findAnchor(plot) if not anchor then return nil end
	local a = Instance.new("Attachment")
	a.Name = "UpgradeAttachment"
	a.Parent = anchor
	pp = Instance.new("ProximityPrompt")
	pp.Name = "Upgrade"
	pp.HoldDuration = 0.25
	pp.MaxActivationDistance = 10
	pp.RequiresLineOfSight = false
	pp.Parent = a
	return pp
end

local function bind(pp, plot)
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

local function scan()
	local r = root() if not r then return end
	for _, plot in ipairs(r:GetChildren()) do
		if plot:IsA("Model") or plot:IsA("Folder") then
			local pp = ensurePrompt(plot)
			if pp then bind(pp, plot) end
		end
	end
end

task.defer(scan)
Workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("ProximityPrompt") then
		local plot = obj:FindFirstAncestorWhichIsA("Model") or obj:FindFirstAncestorWhichIsA("Folder")
		local r = root()
		if plot and r and plot:IsDescendantOf(r) then bind(obj, plot) end
	end
end)

print("[AutoUpgradeBinder] Ready")