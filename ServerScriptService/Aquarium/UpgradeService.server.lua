-- ServerScriptService/Aquarium/UpgradeService.server.lua
-- Coste de mejora: capacity * 48  (Common 1/5s durante 4 minutos)
-- Cada mejora: capacity += 4, capacityLevel += 1
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")

local TicketService = require(SSS:WaitForChild("TicketService"))

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local Profiles = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local function dsKey(uid) return "u_"..tostring(uid) end
local function toInt(n) if typeof(n)~="number" then return 0 end return math.max(0, math.floor(n+0.5)) end

local function getData(uid)
	local ok, data = pcall(function() return Profiles:GetAsync(dsKey(uid)) end)
	if not ok or type(data)~="table" then data = {} end
	data.capacityLevel = toInt(data.capacityLevel or 0)
	data.capacity = toInt(data.capacity or (6 + 4 * data.capacityLevel))
	data.tickets = toInt(data.tickets or 0)
	return data
end

local function saveData(uid, data)
	pcall(function() Profiles:SetAsync(dsKey(uid), data) end)
end

local function upgradeCost(capacity)
	return toInt(capacity * 48)
end

-- Lógica: expón una API pública para que el cartel/Prompt la llame
_G.AquariumUpgrade = {}
function _G.AquariumUpgrade.TryUpgrade(p)
	local data = getData(p.UserId)
	local cost = upgradeCost(data.capacity)
	if TicketService.Get(p) < cost then
		return false, ("Necesitas %d tickets"):format(cost)
	end

	-- cobra
	TicketService.Add(p, -cost)

	-- aplica
	data.capacityLevel = data.capacityLevel + 1
	data.capacity = data.capacity + 4
	saveData(p.UserId, data)

	-- refleja Level al momento (HUD ya creado por PlayerStatsService)
	local ls = p:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Level") then
		ls.Level.Value = data.capacityLevel
	end

	return true, ("Capacidad nueva: %d (Lv.%d)"):format(data.capacity, data.capacityLevel)
end

print("[UpgradeService] Ready")