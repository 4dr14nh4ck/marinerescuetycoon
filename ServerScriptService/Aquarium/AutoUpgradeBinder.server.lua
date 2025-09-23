-- ServerScriptService/Aquarium/AutoUpgradeBinder.server.lua
local Workspace = game:GetService("Workspace")

local function isUpgradePrompt(pp)
	if not pp or not pp:IsA("ProximityPrompt") then return false end
	local n = (pp.Name or ""):lower()
	local a = (pp.ActionText or ""):lower()
	return n:find("upgrade") or n:find("mejor") or a:find("upgrade") or a:find("mejor")
end

local function bind(pp)
	if pp:GetAttribute("UpgradeBound") then return end
	pp:SetAttribute("UpgradeBound", true)
	pp.Triggered:Connect(function(player)
		if _G.AquariumUpgrade and _G.AquariumUpgrade.TryUpgrade then
			local ok, msg = _G.AquariumUpgrade.TryUpgrade(player)
			if not ok then warn("[Upgrade] " .. tostring(msg)) end
		else
			warn("[Upgrade] _G.AquariumUpgrade.TryUpgrade no disponible")
		end
	end)
end

local function scan(container)
	for _, inst in ipairs(container:GetDescendants()) do
		if isUpgradePrompt(inst) then bind(inst) end
	end
end

local function root()
	return Workspace:FindFirstChild("Aquariums") or Workspace:FindFirstChild("Acuarios")
end

task.defer(function()
	local r = root()
	if r then scan(r) end
end)

Workspace.DescendantAdded:Connect(function(obj)
	if isUpgradePrompt(obj) then bind(obj) end
end)