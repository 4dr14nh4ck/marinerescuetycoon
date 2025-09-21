-- ServerScriptService/Player/PlayerStatsService.server.lua
-- Versión con DIAGNÓSTICO para Tickets. Fish (OrderedStore) y Level (Profiles.SlotsOwned) ya correctos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local ORDERED_STORE_NAME = "INTARC_GlobalFish_v1"

local orderedFish  = DataStoreService:GetOrderedDataStore(ORDERED_STORE_NAME)
local profileStore = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local Profiles do
	local aq = ReplicatedStorage:FindFirstChild("Aquarium")
	local mod = aq and aq:FindFirstChild("Profiles")
	if mod then
		local ok, res = pcall(require, mod)
		if ok then Profiles = res else warn("[PlayerStatsService] require Profiles.lua falló:", res) end
	else
		warn("[PlayerStatsService] No existe ReplicatedStorage/Aquarium/Profiles.lua")
	end
end

local STAT_NAMES = { "Fish", "Tickets", "Level" }

-- ---------- Helpers ----------
local function ensureLeaderstats(player)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player
	end
	for _, n in ipairs(STAT_NAMES) do
		if not ls:FindFirstChild(n) then
			local v = Instance.new("IntValue"); v.Name = n; v.Value = 0; v.Parent = ls
		end
	end
	return ls
end

local function toInt(n) if typeof(n) ~= "number" then return 0 end return math.max(0, math.floor(n + 0.5)) end
local function safeGet(ds, key)
	local ok, result = pcall(function() return ds:GetAsync(key) end)
	if not ok then warn("[PlayerStatsService] GetAsync falló:", ds.Name, key, result); return nil end
	return result
end

local function deepFindNumberByKey(tbl, wantedKey, path, depth, maxDepth)
	if type(tbl) ~= "table" then return nil end
	path = path or ""; depth = depth or 0; maxDepth = maxDepth or 8
	if depth > maxDepth then return nil end
	for k, v in pairs(tbl) do
		local thisPath = (path == "" and tostring(k)) or (path .. "." .. tostring(k))
		if tostring(k) == wantedKey and tonumber(v) then return tonumber(v), thisPath end
		if type(v) == "table" then
			local found, fp = deepFindNumberByKey(v, wantedKey, thisPath, depth + 1, maxDepth)
			if found ~= nil then return found, fp end
		end
	end
	return nil
end

local function shallowKeys(t, max)
	if type(t) ~= "table" then return tostring(t) end
	max = max or 20
	local r, n = {}, 0
	for k, v in pairs(t) do
		n += 1; if n > max then break end
		table.insert(r, string.format("%s:%s", tostring(k), typeof(v)))
	end
	return table.concat(r, ", ")
end

-- Mirrors runtime para Tickets/Level si aparecen como Attributes/Values
local function bindRuntimeMirrors(player, leaderstats)
	local watching = { Tickets = false, Level = false }
	local function tryBindInstance(desc)
		if not (desc:IsA("IntValue") or desc:IsA("NumberValue")) then return end
		if desc.Parent and desc.Parent.Name == "leaderstats" then return end
		local name = desc.Name
		if (name ~= "Tickets" and name ~= "Level") or watching[name] then return end
		watching[name] = true
		print("[PlayerStatsService] Mirror runtime ->", name, desc:GetFullName(), "=", desc.Value)
		leaderstats[name].Value = toInt(desc.Value)
		desc:GetPropertyChangedSignal("Value"):Connect(function()
			leaderstats[name].Value = toInt(desc.Value)
		end)
	end
	for _, d in ipairs(player:GetDescendants()) do tryBindInstance(d) end
	player.DescendantAdded:Connect(tryBindInstance)
	player.AttributeChanged:Connect(function(attr)
		if attr == "Tickets" or attr == "Level" then
			local val = player:GetAttribute(attr)
			print("[PlayerStatsService] Mirror Attribute ->", attr, "=", val)
			leaderstats[attr].Value = toInt(val)
		end
	end)
end
-- -----------------------------

local function getProfileFor(player)
	if not Profiles then return nil end
	local calls = {
		function() return type(Profiles.Get) == "function" and Profiles:Get(player) end,
		function() return type(Profiles.Get) == "function" and Profiles.Get(player) end,
		function() return type(Profiles.Get) == "function" and Profiles:Get(player.UserId) end,
		function() return type(Profiles.Get) == "function" and Profiles.Get(player.UserId) end,
		function() return type(Profiles.Get) == "function" and Profiles:Get(tostring(player.UserId)) end,
		function() return type(Profiles.Get) == "function" and Profiles.Get(tostring(player.UserId)) end,
	}
	for _, call in ipairs(calls) do
		local ok, res = pcall(call)
		if ok and type(res) == "table" then return res end
	end
	return nil
end

local function onPlayerAdded(player)
	local ls = ensureLeaderstats(player)

	-- 1) FISH (OrderedStore)
	do
		local uid = tostring(player.UserId)
		local keys = { uid, "Player_"..uid, "UID_"..uid, "User_"..uid, "Profile_"..uid }
		local fish = 0
		for _, key in ipairs(keys) do
			local v = safeGet(orderedFish, key)
			if type(v) == "number" then fish = v; break end
		end
		ls.Fish.Value = toInt(fish)
	end

	-- 2) LEVEL (Profiles -> SlotsOwned)
	do
		local prof = getProfileFor(player)
		if type(prof) == "table" then
			local lvl = tonumber(prof.SlotsOwned) or select(1, deepFindNumberByKey(prof, "SlotsOwned"))
			if lvl ~= nil then ls.Level.Value = toInt(lvl) end
			print("[PlayerStatsService] Perfil keys:", shallowKeys(prof))
			if type(prof.Data) == "table" then print("[PlayerStatsService] Perfil.Data keys:", shallowKeys(prof.Data)) end
			if type(prof.Stats) == "table" then print("[PlayerStatsService] Perfil.Stats keys:", shallowKeys(prof.Stats)) end
		end
	end

	-- 3) TICKETS: perfil activo → ProfileStore → mirrors runtime
	do
		local prof = getProfileFor(player)
		local tickets, path

		if type(prof) == "table" then
			-- directos y anidados
			tickets = tonumber(prof.Tickets) or tonumber(prof.Coins) or tonumber(prof.Money) or tonumber(prof.Currency)
			if not tickets then
				tickets, path = deepFindNumberByKey(prof, "Tickets")
				if not tickets then tickets, path = deepFindNumberByKey(prof, "Coins") end
				if not tickets then tickets, path = deepFindNumberByKey(prof, "Money") end
				if not tickets then tickets, path = deepFindNumberByKey(prof, "Currency") end
			end
			if tickets then
				print(("[PlayerStatsService] Tickets en perfil (%s) = %s"):format(tostring(path), tostring(tickets)))
			else
				print("[PlayerStatsService] Tickets NO están en Profiles:Get(...)")
			end
		end

		-- ProfileStore fallback
		if not tickets then
			local uid = tostring(player.UserId)
			local keys = { uid, "Player_"..uid, "UID_"..uid, "User_"..uid, "Profile_"..uid, "p_"..uid }
			local data, usedKey
			for _, key in ipairs(keys) do
				local v = safeGet(profileStore, key)
				if v ~= nil then data = v; usedKey = key; break end
			end
			if type(data) == "table" then
				print(("[PlayerStatsService] ProfileStore key=%s keys=%s"):format(tostring(usedKey), shallowKeys(data)))
				tickets = tonumber(data.Tickets) or tonumber(data.Coins) or tonumber(data.Money) or tonumber(data.Currency)
				if not tickets then
					tickets, path = deepFindNumberByKey(data, "Tickets")
					if not tickets then tickets, path = deepFindNumberByKey(data, "Coins") end
					if not tickets then tickets, path = deepFindNumberByKey(data, "Money") end
					if not tickets then tickets, path = deepFindNumberByKey(data, "Currency") end
					if tickets then
						print(("[PlayerStatsService] Tickets en store (%s) = %s"):format(tostring(path), tostring(tickets)))
					end
				end
			else
				print("[PlayerStatsService] ProfileStore no devolvió tabla.")
			end
		end

		if tickets then ls.Tickets.Value = toInt(tickets) end
	end

	-- 4) Mirrors runtime
	bindRuntimeMirrors(player, ls)

	print(("[PlayerStatsService] %s -> Fish=%d | Tickets=%d | Level=%d")
		:format(player.Name, ls.Fish.Value, ls.Tickets.Value, ls.Level.Value))
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end