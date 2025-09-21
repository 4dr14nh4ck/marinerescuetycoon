-- ServerScriptService/Stats/PlayerStatsService.server.lua
-- Fish -> OrderedStore | Level -> Profiles:Get(player).SlotsOwned | Tickets -> TicketService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local ORDERED_STORE_NAME = "INTARC_GlobalFish_v1"

local orderedFish  = DataStoreService:GetOrderedDataStore(ORDERED_STORE_NAME)

-- TicketService (raíz o /Stats), sin WaitForChild
local function getTS()
	local mod = SSS:FindFirstChild("TicketService")
	if not mod then local stats=SSS:FindFirstChild("Stats"); if stats then mod=stats:FindFirstChild("TicketService") end end
	if not mod then warn("[PlayerStatsService] TicketService NO encontrado."); return nil end
	local ok, svc = pcall(require, mod); if not ok then warn("[PlayerStatsService] require TS falló:", svc); return nil end
	print("[PlayerStatsService] TicketService cargado desde:", mod:GetFullName())
	return svc
end
local TicketService = getTS()

-- Profiles para Level
local Profiles do
	local aq = ReplicatedStorage:FindFirstChild("Aquarium"); local mod = aq and aq:FindFirstChild("Profiles")
	if mod then local ok, res = pcall(require, mod); if ok then Profiles = res end end
end

local function ensureLeaderstats(p)
	local ls = p:FindFirstChild("leaderstats") or Instance.new("Folder")
	ls.Name = "leaderstats"; ls.Parent = p
	for _,n in ipairs({ "Fish","Tickets","Level" }) do
		if not ls:FindFirstChild(n) then Instance.new("IntValue", ls).Name = n end
	end
	return ls
end

local function toInt(n) if typeof(n) ~= "number" then return 0 end return math.max(0, math.floor(n + 0.5)) end
local function safeGet(ds,key) local ok,r=pcall(function() return ds:GetAsync(key) end); return ok and r or nil end

local function onPlayer(p)
	local ls = ensureLeaderstats(p)

	-- FISH desde OrderedStore
	do
		local uid = tostring(p.UserId)
		local keys = { uid, "Player_"..uid, "UID_"..uid, "User_"..uid, "Profile_"..uid }
		local fish = 0
		for _,k in ipairs(keys) do local v = safeGet(orderedFish,k); if type(v)=="number" then fish=v; break end end
		ls.Fish.Value = toInt(fish)
	end

	-- LEVEL = Profiles:Get(p).SlotsOwned  (ruta confirmada)
	do
		if Profiles and type(Profiles.Get)=="function" then
			local ok, prof = pcall(function() return Profiles:Get(p) end)
			if ok and type(prof)=="table" then
				local slots = tonumber(prof.SlotsOwned)
				if slots ~= nil then ls.Level.Value = toInt(slots) end
				print(("[PlayerStatsService] Level path -> Profiles:Get(player).SlotsOwned = %s"):format(tostring(slots)))
			end
		end
	end

	-- TICKETS desde TicketService (si está)
	do
		if TicketService then
			ls.Tickets.Value = toInt(TicketService.Get(p))
			TicketService.Changed(p, function(v) ls.Tickets.Value = toInt(v) end)
		else
			ls.Tickets.Value = 0
		end
	end

	print(("[PlayerStatsService] %s -> Fish=%d | Tickets=%d | Level=%d")
		:format(p.Name, ls.Fish.Value, ls.Tickets.Value, ls.Level.Value))
end

Players.PlayerAdded:Connect(onPlayer)
for _,p in ipairs(Players:GetPlayers()) do onPlayer(p) end