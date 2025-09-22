-- ServerScriptService/Stats/PlayerStatsService.server.lua
-- HUD (leaderstats) alineado con la base de datos real:
--   Fish    -> OrderedStore "INTARC_GlobalFish_v1"
--   Tickets -> ServerScriptService.TicketService (clave "u_<userId>", campo "tickets")
--   Level   -> DataStore INTARC_Profiles_v2 campo "capacityLevel"  (mismo que leaderboard)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")

local ORDERED_STORE_NAME = "INTARC_GlobalFish_v1"
local PROFILE_STORE_NAME = "INTARC_Profiles_v2"

local orderedFish   = DataStoreService:GetOrderedDataStore(ORDERED_STORE_NAME)
local profileStore  = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

-- TicketService (módulo raíz o en /Stats). Sin yields:
local function getTicketService()
	local mod = SSS:FindFirstChild("TicketService")
	if not mod then
		local stats = SSS:FindFirstChild("Stats")
		if stats then mod = stats:FindFirstChild("TicketService") end
	end
	if not mod then
		warn("[PlayerStatsService] TicketService NO encontrado. Tickets=0 (solo lectura de DB al spawn).")
		return nil
	end
	local ok, svc = pcall(require, mod)
	if not ok then warn("[PlayerStatsService] require TicketService falló:", svc); return nil end
	print("[PlayerStatsService] TicketService cargado desde:", mod:GetFullName())
	return svc
end
local TicketService = getTicketService()

local function dsKey(userId) return "u_" .. tostring(userId) end
local function toInt(n) if typeof(n) ~= "number" then return 0 end return math.max(0, math.floor(n + 0.5)) end
local function safeGet(ds, key) local ok, r = pcall(function() return ds:GetAsync(key) end); return ok and r or nil end

local function ensureLeaderstats(p)
	local ls = p:FindFirstChild("leaderstats")
	if not ls then ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = p end
	for _, n in ipairs({ "Fish","Tickets","Level" }) do
		if not ls:FindFirstChild(n) then Instance.new("IntValue", ls).Name = n end
	end
	return ls
end

local function onPlayer(p)
	local ls = ensureLeaderstats(p)

	-- FISH (OrderedStore, igual que GlobalLeaderboard)
	do
		local uid = tostring(p.UserId)
		local fish = 0
		for _, k in ipairs({ uid, "Player_"..uid, "UID_"..uid, "User_"..uid, "Profile_"..uid }) do
			local v = safeGet(orderedFish, k)
			if type(v) == "number" then fish = v; break end
		end
		ls.Fish.Value = toInt(fish)
	end

	-- LEVEL (de la misma DB que usa el leaderboard): capacityLevel
	do
		local data = safeGet(profileStore, dsKey(p.UserId))
		local lvl = 0
		if type(data) == "table" then
			lvl = tonumber(data.capacityLevel) or 0  -- <= clave confirmada por Creator Hub
		end
		ls.Level.Value = toInt(lvl)
	end

	-- TICKETS
	do
		if TicketService then
			-- autoridad runtime
			ls.Tickets.Value = toInt(TicketService.Get(p))
			TicketService.Changed(p, function(v) ls.Tickets.Value = toInt(v) end)
		else
			-- lectura directa de la DB si no hay módulo cargado
			local data = safeGet(profileStore, dsKey(p.UserId))
			local t = 0
			if type(data) == "table" then
				t = tonumber(data.tickets) or tonumber(data.Tickets)
					or tonumber(data.coins) or tonumber(data.Coins)
					or tonumber(data.money) or tonumber(data.Money)
					or 0
			end
			ls.Tickets.Value = toInt(t)
		end
	end

	print(("[PlayerStatsService] %s -> Fish=%d | Tickets=%d | Level=%d")
		:format(p.Name, ls.Fish.Value, ls.Tickets.Value, ls.Level.Value))
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end