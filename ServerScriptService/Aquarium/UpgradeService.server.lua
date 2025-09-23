-- ServerScriptService/Aquarium/UpgradeService.server.lua
-- Coste de mejora: capacity * 48  (Common 1 ticket / 5s durante 4 min = 48 ticks)
-- Cada mejora: capacity += 4, capacityLevel += 1
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")

local TicketService = require(SSS:WaitForChild("TicketService"))

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local Profiles = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local function dsKey(uid) return "u_" .. tostring(uid) end
local function toInt(n) if typeof(n) ~= "number" then return 0 end return math.max(0, math.floor(n+0.5)) end
local function getData(uid)
	local ok, data = pcall(function() return Profiles:GetAsync(dsKey(uid)) end)
	if not ok or type(data) ~= "table" then data = {} end
	data.capacityLevel = toInt(data.capacityLevel or 0)
	data.capacity = toInt(data.capacity or (6 + 4 * data.capacityLevel))
	data.tickets = toInt(data.tickets or 0)
	return data
end
local function saveData(uid, data) pcall(function() Profiles:SetAsync(dsKey(uid), data) end) end
local function upgradeCost(capacity) return toInt(capacity * 48) end

_G.AquariumUpgrade = _G.AquariumUpgrade or {}
function _G.AquariumUpgrade.TryUpgrade(p: Player)
	local data = getData(p.UserId)
	local cost = upgradeCost(data.capacity)
	if TicketService.Get(p) < cost then
		return false, ("Necesitas %d tickets"):format(cost)
	end

	-- Cobro
	TicketService.Add(p, -cost)

	-- Aplicación
	data.capacityLevel = data.capacityLevel + 1
	data.capacity = data.capacity + 4
	saveData(p.UserId, data)

	-- Reflejar en HUD (Level = capacityLevel)
	local ls = p:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Level") then ls.Level.Value = data.capacityLevel end

	-- Refrescar rótulos del acuario si el servicio visual está cargado
	if _G.Visual and _G.Visual.RefreshForPlayer then _G.Visual.RefreshForPlayer(p) end

	return true, ("Capacidad nueva: %d (Lv.%d)"):format(data.capacity, data.capacityLevel)
end

print("[UpgradeService] Ready")