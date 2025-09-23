-- ServerScriptService/Player/PlayerStatsService.server.lua
-- Fuente única para poblar Player.leaderstats.
-- Lee Fish del OrderedStore global y busca Tickets/Level en el ProfileStore,
-- cubriendo estructuras comunes (incluida ProfileService). Refleja también
-- fuentes de runtime (Attributes/IntValue/NumberValue) si aparecen.
-- No crea nuevas variables de juego ni escribe en DataStores.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Deben coincidir con GlobalLeaderboard
local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local ORDERED_STORE_NAME = "INTARC_GlobalFish_v1"

local profileStore = DataStoreService:GetDataStore(PROFILE_STORE_NAME)
local orderedFish  = DataStoreService:GetOrderedDataStore(ORDERED_STORE_NAME)

local STAT_NAMES = { "Fish", "Tickets", "Level" }

-- ---------- Helpers ----------
local function ensureLeaderstats(player)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	for _, n in ipairs(STAT_NAMES) do
		if not ls:FindFirstChild(n) then
			local v = Instance.new("IntValue")
			v.Name = n
			v.Value = 0
			v.Parent = ls
		end
	end
	return ls
end

local function toInt(n)
	if typeof(n) ~= "number" then return 0 end
	return math.max(0, math.floor(n + 0.5))
end

local function safeGet(ds, key)
	local ok, result = pcall(function() return ds:GetAsync(key) end)
	if not ok then
		warn("[PlayerStatsService] GetAsync falló:", ds.Name, key, result)
		return nil
	end
	return result
end

local function deepFindNumberByKey(tbl, wantedKey, path, depth, maxDepth)
	if type(tbl) ~= "table" then return nil end
	path = path or ""
	depth = depth or 0
	maxDepth = maxDepth or 8
	if depth > maxDepth then return nil end
	for k, v in pairs(tbl) do
		local thisPath = (path == "" and tostring(k)) or (path .. "." .. tostring(k))
		if tostring(k) == wantedKey and tonumber(v) then
			return tonumber(v), thisPath
		end
		if type(v) == "table" then
			local found, fp = deepFindNumberByKey(v, wantedKey, thisPath, depth + 1, maxDepth)
			if found ~= nil then return found, fp end
		end
	end
	return nil
end

-- si en runtime aparecen Attributes o Values con Tickets/Level, reflejarlos
local function bindRuntimeMirrors(player, leaderstats)
	local watching = { Tickets = false, Level = false }

	local function tryBindInstance(desc)
		if not (desc:IsA("IntValue") or desc:IsA("NumberValue")) then return end
		if desc.Parent and desc.Parent.Name == "leaderstats" then return end
		local name = desc.Name
		if name ~= "Tickets" and name ~= "Level" then return end
		if watching[name] then return end
		watching[name] = true

		leaderstats[name].Value = toInt(desc.Value)
		desc:GetPropertyChangedSignal("Value"):Connect(function()
			leaderstats[name].Value = toInt(desc.Value)
		end)
	end

	for _, d in ipairs(player:GetDescendants()) do
		tryBindInstance(d)
	end
	player.DescendantAdded:Connect(tryBindInstance)

	player.AttributeChanged:Connect(function(attr)
		if attr == "Tickets" or attr == "Level" then
			leaderstats[attr].Value = toInt(player:GetAttribute(attr))
		end
	end)
end
-- -----------------------------

local function onPlayerAdded(player)
	local ls = ensureLeaderstats(player)

	-- 1) FISH desde el OrderedStore (coincide con GlobalLeaderboard)
	do
		local uid = tostring(player.UserId)
		local candidateKeys = {
			uid, "Player_"..uid, "UID_"..uid, "User_"..uid, "Profile_"..uid
		}
		local fish = 0
		for _, key in ipairs(candidateKeys) do
			local v = safeGet(orderedFish, key)
			if type(v) == "number" then fish = v; break end
		end
		ls.Fish.Value = toInt(fish)
	end

	-- 2) TICKETS y LEVEL desde el ProfileStore (estructura desconocida -> búsqueda profunda)
	do
		local uid = tostring(player.UserId)
		local candidateKeys = {
			uid, "Player_"..uid, "UID_"..uid, "User_"..uid, "Profile_"..uid, "p_"..uid
		}
		local profileData
		for _, key in ipairs(candidateKeys) do
			local v = safeGet(profileStore, key)
			if v ~= nil then profileData = v; break end
		end

		local function extractTicketsLevel(data)
			if type(data) ~= "table" then return nil, nil end

			-- Casos directos
			local t = tonumber(data.Tickets)
			local l = tonumber(data.Level)
			if t or l then return t, l end

			-- Casos ProfileService típicos
			--   { Data = { Tickets=, Level= } }
			if type(data.Data) == "table" then
				local t2 = tonumber(data.Data.Tickets)
				local l2 = tonumber(data.Data.Level)
				if t2 or l2 then return t2, l2 end
			end

			--   { Data = { Stats = { Tickets=, Level= } } }
			if type(data.Data) == "table" and type(data.Data.Stats) == "table" then
				local t3 = tonumber(data.Data.Stats.Tickets)
				local l3 = tonumber(data.Data.Stats.Level)
				if t3 or l3 then return t3, l3 end
			end

			-- Búsqueda profunda final por nombre de clave
			local tDeep = deepFindNumberByKey(data, "Tickets")
			local lDeep = deepFindNumberByKey(data, "Level")
			return tDeep, lDeep
		end

		local tickets, level = 0, 0
		if type(profileData) == "table" then
			local t, l = extractTicketsLevel(profileData)
			if tonumber(t) then tickets = t end
			if tonumber(l) then level   = l end
		end

		-- IMPORTANTE: si no se encuentran en el store, no pisamos valores
		-- que puedan llegar de runtime (Attributes/Values). Solo asignamos si >0
		if tickets and tickets > 0 then ls.Tickets.Value = toInt(tickets) end
		if level   and level   > 0 then ls.Level.Value   = toInt(level)   end
	end

	-- 3) Reflejar cambios en runtime (Attributes/Values) si aparecen más tarde
	bindRuntimeMirrors(player, ls)

	print(("[PlayerStatsService] %s -> Fish=%d | Tickets=%d | Level=%d")
		:format(player.Name, ls.Fish.Value, ls.Tickets.Value, ls.Level.Value))
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end