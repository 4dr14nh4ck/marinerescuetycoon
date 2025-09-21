-- ServerScriptService/Debug/ScanProfiles.server.lua
-- Objetivo: detectar cómo expone datos el módulo ReplicatedStorage/Aquarium/Profiles.lua
-- y localizar las rutas reales de Tickets/Level para cada jugador.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function safeRequire(inst)
	local ok, res = pcall(require, inst)
	if not ok then
		warn("[ScanProfiles] require falló:", inst and inst:GetFullName(), res)
		return nil
	end
	return res
end

local Profiles
do
	local aq = ReplicatedStorage:FindFirstChild("Aquarium")
	local mod = aq and aq:FindFirstChild("Profiles")
	if not mod then
		warn("[ScanProfiles] NO existe ReplicatedStorage/Aquarium/Profiles.lua")
	else
		Profiles = safeRequire(mod)
	end
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

local function tryCall(fn, ...)
	if type(fn) ~= "function" then return false, "not a function" end
	local ok, res = pcall(fn, ...)
	if not ok then return false, res end
	return true, res
end

local candidateFuncs = {
	"Get", "GetProfile", "GetPlayerProfile", "GetByPlayer", "GetByUserId",
	"GetProfileByUserId", "GetData", "GetPlayerData", "GetOrCreate", "GetOrCreateProfile"
}

local function inspectForPlayer(p)
	print(("[ScanProfiles] >>> %s (%d)"):format(p.Name, p.UserId))

	if not Profiles then
		warn("[ScanProfiles] Profiles module no cargado.")
		return
	end

	-- 1) Inspección superficial del módulo
	print("[ScanProfiles] type(Profiles) =", typeof(Profiles))
	if typeof(Profiles) == "table" then
		print("[ScanProfiles] keys:", shallowKeys(Profiles))
	end

	-- 2) Intentar funciones comunes
	local results = {}
	for _, fname in ipairs(candidateFuncs) do
		local fn = Profiles[fname]
		if type(fn) == "function" then
			local ok1, res1 = tryCall(fn, Profiles, p)      -- método estilo :Get(p)
			local ok2, res2 = tryCall(fn, p)                -- función libre Get(p)
			local ok3, res3 = tryCall(fn, Profiles, p.UserId)
			local ok4, res4 = tryCall(fn, p.UserId)
			local bestOK, bestRes = nil, nil
			for _, pair in ipairs({{ok1,res1},{ok2,res2},{ok3,res3},{ok4,res4}}) do
				if pair[1] and pair[2] ~= nil then bestOK, bestRes = pair[1], pair[2]; break end
			end
			if bestOK then
				results[fname] = bestRes
				print("[ScanProfiles] "..fname.." ->", typeof(bestRes), shallowKeys(bestRes))
			end
		end
	end

	-- 3) Si el módulo expone una tabla de perfiles activa, intentar indexación por Player/UserId/Name
	local candidates = {}
	if typeof(Profiles) == "table" then
		table.insert(candidates, Profiles)
		for k, v in pairs(Profiles) do
			if type(v) == "table" then table.insert(candidates, v) end
		end
	end

	local function probeTable(t, label)
		-- mirar por player, userId y nombre como keys
		local hits = {}
		for _, key in ipairs({ p, p.UserId, tostring(p.UserId), p.Name, "Player_"..p.UserId, "UID_"..p.UserId }) do
			local v = t[key]
			if v ~= nil then
				print(("[ScanProfiles] índice %s[%s] -> %s %s"):format(label, tostring(key), typeof(v), shallowKeys(v)))
				table.insert(hits, v)
			end
		end
		return hits
	end

	local buckets = {}
	for idx, t in ipairs(candidates) do
		for _, hit in ipairs(probeTable(t, "Candidates["..idx.."]")) do
			table.insert(buckets, hit)
		end
	end

	-- 4) Buscar Tickets/Level en cualquiera de los objetos/tablitas halladas
	local function searchIn(obj, tag)
		if type(obj) ~= "table" then return end
		local tv, tpath = deepFindNumberByKey(obj, "Tickets")
		local lv, lpath = deepFindNumberByKey(obj, "Level")
		if tv ~= nil or lv ~= nil then
			print(("[ScanProfiles] %s -> TicketsPath=%s (%s) | LevelPath=%s (%s)")
				:format(tag, tostring(tpath), tostring(tv), tostring(lpath), tostring(lv)))
		end
	end

	for i, obj in ipairs(buckets) do
		searchIn(obj, "bucket"..i)
	end

	-- 5) En último caso, si alguna función devolvió algo, examinarlo
	for fname, res in pairs(results) do
		searchIn(res, "fn:"..fname)
	end
end

Players.PlayerAdded:Connect(inspectForPlayer)
for _, p in ipairs(Players:GetPlayers()) do inspectForPlayer(p) end