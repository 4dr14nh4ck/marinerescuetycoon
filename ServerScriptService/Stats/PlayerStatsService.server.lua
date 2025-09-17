-- ServerScriptService/Stats/PlayerStatsService.lua
-- Crea/actualiza leaderstats (Fish, Tickets), sincroniza con Profiles y OrderedDataStore de ranking global.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")

-- Ajusta estos nombres si cambian en tu proyecto
local PROFILES_STORE_NAME = "INTARC_Profiles_v1"
local ORDERED_STORE_NAME  = "INTARC_GlobalCured_v1" -- ranking por peces totales

local Profiles = require(RS:WaitForChild("Aquarium"):WaitForChild("Profiles"))

local ProfilesStore      = DataStoreService:GetDataStore(PROFILES_STORE_NAME)
local GlobalOrderedStore = DataStoreService:GetOrderedDataStore(ORDERED_STORE_NAME)

-- Pequeña cola para “flush” periódico y no escribir en cada cambio
local pendingUsers = {}  -- [userId] = true

local function ensureLeaderstats(plr, initialFish, initialTickets)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = plr
	end

	local fish = ls:FindFirstChild("Fish")
	if not fish then
		fish = Instance.new("IntValue")
		fish.Name = "Fish"
		fish.Parent = ls
	end

	local tks = ls:FindFirstChild("Tickets")
	if not tks then
		tks = Instance.new("IntValue")
		tks.Name = "Tickets"
		tks.Parent = ls
	end

	if typeof(initialFish) == "number" then fish.Value = initialFish end
	if typeof(initialTickets) == "number" then tks.Value = initialTickets end

	return fish, tks
end

local function bindStatSync(plr, fish, tickets)
	-- Cuando cambien, actualizamos el perfil en memoria y marcamos flush.
	fish:GetPropertyChangedSignal("Value"):Connect(function()
		local p = Profiles.Get(plr.UserId)
		p.fish = fish.Value
		pendingUsers[plr.UserId] = true
	end)

	tickets:GetPropertyChangedSignal("Value"):Connect(function()
		local p = Profiles.Get(plr.UserId)
		p.tickets = tickets.Value
		pendingUsers[plr.UserId] = true
	end)
end

Players.PlayerAdded:Connect(function(plr)
	-- Carga perfil y refleja en leaderstats
	local prof = Profiles.Get(plr.UserId) -- {fish, tickets, capacity, capacityLevel, totalCured?}
	local fish, tks = ensureLeaderstats(plr, prof.fish or 0, prof.tickets or 0)
	bindStatSync(plr, fish, tks)

	-- Marca para flush inicial (sube ranking con el valor actual)
	pendingUsers[plr.UserId] = true
end)

Players.PlayerRemoving:Connect(function(plr)
	-- Guardado final
	Profiles.Save(plr.UserId, true)
	-- Sube el ranking también
	local prof = Profiles.Get(plr.UserId)
	pcall(function()
		GlobalOrderedStore:SetAsync(tostring(plr.UserId), tonumber(prof.fish or 0) or 0)
	end)
	pendingUsers[plr.UserId] = nil
end)

-- Flush periódico (reduce “DataStore request queued”)
task.spawn(function()
	while true do
		for userId,_ in pairs(pendingUsers) do
			local prof = Profiles.Get(userId)
			-- Guarda el perfil (no forzado) y actualiza el ranking global
			pcall(function()
				Profiles.Save(userId, false)
			end)
			pcall(function()
				GlobalOrderedStore:SetAsync(tostring(userId), tonumber(prof.fish or 0) or 0)
			end)
			pendingUsers[userId] = nil
		end
		task.wait(10) -- cada 10 s
	end
end)