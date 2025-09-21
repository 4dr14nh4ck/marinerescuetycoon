-- ServerScriptService/Stats/TicketService.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local profileStore = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local TicketService = {}
local current = {}      -- [player] = number
local listeners = {}    -- [player] = {callbacks}

local function toInt(n) if typeof(n) ~= "number" then return 0 end return math.max(0, math.floor(n + 0.5)) end
local function dsKey(userId) return "Player_" .. tostring(userId) end

local function loadTickets(p)
	local key = dsKey(p.UserId)
	local ok, data = pcall(function() return profileStore:GetAsync(key) end)
	if ok and type(data) == "table" then
		local t = tonumber(data.Tickets) or tonumber(data.Coins) or tonumber(data.Money) or tonumber(data.Currency) or 0
		return toInt(t)
	end
	return 0
end

local function saveTickets(p, value)
	local key = dsKey(p.UserId)
	local ok, err = pcall(function()
		local existing = profileStore:GetAsync(key)
		if type(existing) ~= "table" then existing = {} end
		existing.Tickets = toInt(value)
		profileStore:SetAsync(key, existing)
	end)
	if not ok then warn("[TicketService] SetAsync falló:", key, err) end
end

local function fire(p)
	if listeners[p] then
		for _, cb in ipairs(listeners[p]) do task.spawn(cb, current[p]) end
	end
end

function TicketService.Bind(p)
	if current[p] ~= nil then return end
	current[p] = loadTickets(p)
	p:SetAttribute("Tickets", current[p])
	local ls = p:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Tickets") then ls.Tickets.Value = current[p] end
	fire(p)
end

function TicketService.Unbind(p)
	if current[p] == nil then return end
	saveTickets(p, current[p])
	current[p] = nil
	listeners[p] = nil
end

function TicketService.Get(p) return toInt(current[p] or 0) end

function TicketService.Set(p, value)
	current[p] = toInt(value)
	p:SetAttribute("Tickets", current[p])
	local ls = p:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Tickets") then ls.Tickets.Value = current[p] end
	fire(p)
end

function TicketService.Add(p, delta)
	if delta and delta ~= 0 then TicketService.Set(p, TicketService.Get(p) + delta) end
end

function TicketService.Changed(p, callback)
	if not listeners[p] then listeners[p] = {} end
	table.insert(listeners[p], callback)
end

Players.PlayerAdded:Connect(TicketService.Bind)
Players.PlayerRemoving:Connect(TicketService.Unbind)
for _, p in ipairs(Players:GetPlayers()) do TicketService.Bind(p) end

return TicketService