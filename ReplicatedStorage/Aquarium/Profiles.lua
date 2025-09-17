-- ReplicatedStorage/Aquarium/Profiles.lua
-- Perfil v2: fish, tickets, capacity, capacityLevel + conteo por rareza
local DataStoreService = game:GetService("DataStoreService")

local MAIN_STORE    = "INTARC_Profiles_v2"
local ORDERED_STORE = "INTARC_GlobalFish_v1"

local ProfilesStore      = DataStoreService:GetDataStore(MAIN_STORE)
local GlobalOrderedStore = DataStoreService:GetOrderedDataStore(ORDERED_STORE)

local DEFAULT = {
	fish = 0,             -- total peces curados (persistente) = ocupación del tanque
	tickets = 0,
	capacity = 6,
	capacityLevel = 0,

	-- NUEVO: contadores por rareza (persistentes)
	fishCommon   = 0,
	fishUncommon = 0,
	fishRare     = 0,
}

local Cache = {}        -- [userId] = table(profile)
local Dirty = {}        -- [userId] = true/false
local LastSaveAt = {}   -- [userId] = os.clock()
local MIN_SAVE_INTERVAL = 10

local M = {}

local function mergeDefaults(p)
	p = p or {}
	for k,v in pairs(DEFAULT) do
		if p[k] == nil then p[k] = v end
	end
	-- Migración suave: si no hay desgloses pero sí total, asumimos Common
	if (p.fishCommon == 0 and p.fishUncommon == 0 and p.fishRare == 0) and (p.fish or 0) > 0 then
		p.fishCommon = p.fish
	end
	-- Garantiza coherencia total = suma desglose
	local sum = (p.fishCommon or 0) + (p.fishUncommon or 0) + (p.fishRare or 0)
	if sum ~= (p.fish or 0) then
		p.fish = sum
	end
	return p
end

function M.Load(userId)
	if Cache[userId] then return Cache[userId] end
	local ok, data = pcall(function()
		return ProfilesStore:GetAsync("u_"..tostring(userId))
	end)
	local prof = (ok and type(data)=="table") and data or nil
	prof = mergeDefaults(prof)

	Cache[userId] = prof
	Dirty[userId] = false
	LastSaveAt[userId] = 0
	return prof
end

function M.Get(userId)
	return M.Load(userId)
end

local function saveNow(userId)
	if not Cache[userId] then return end
	local prof = Cache[userId]

	pcall(function()
		ProfilesStore:UpdateAsync("u_"..tostring(userId), function(old)
			old = old or {}
			for k,v in pairs(prof) do old[k] = v end
			return old
		end)
	end)

	pcall(function()
		GlobalOrderedStore:SetAsync(tostring(userId), tonumber(prof.fish) or 0)
	end)

	Dirty[userId] = false
	LastSaveAt[userId] = os.clock()
end

function M.Save(userId, force)
	if not Cache[userId] then return end
	if not Dirty[userId] and not force then return end
	if (os.clock() - (LastSaveAt[userId] or 0)) < MIN_SAVE_INTERVAL and not force then
		return
	end
	saveNow(userId)
end

function M.MarkDirty(userId)
	Dirty[userId] = true
end

-- Helpers genéricos
function M.Inc(userId, field, delta)
	local p = M.Get(userId)
	p[field] = math.max(0, (tonumber(p[field]) or 0) + (delta or 0))
	M.MarkDirty(userId)
end

function M.Set(userId, field, value)
	local p = M.Get(userId)
	p[field] = value
	M.MarkDirty(userId)
end

-- ===== NUEVOS HELPERS POR RAREZA =====
local rarityMap = {
	Common = "fishCommon",
	Uncommon = "fishUncommon",
	Rare = "fishRare",
}

function M.AddFishByRarity(userId, rarity, amount)
	amount = amount or 1
	local p = M.Get(userId)
	local key = rarityMap[rarity] or "fishCommon"
	p[key] = math.max(0, (p[key] or 0) + amount)
	p.fish = (p.fishCommon or 0) + (p.fishUncommon or 0) + (p.fishRare or 0)
	M.MarkDirty(userId)
end

function M.GetRarityCounts(userId)
	local p = M.Get(userId)
	return p.fishCommon or 0, p.fishUncommon or 0, p.fishRare or 0
end

-- Auto-saver
task.spawn(function()
	while true do
		task.wait(15)
		for uid,_ in pairs(Dirty) do
			if Dirty[uid] then M.Save(uid) end
		end
	end
end)

return M