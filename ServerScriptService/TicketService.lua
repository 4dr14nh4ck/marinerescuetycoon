-- ServerScriptService/TicketService.lua
-- Autoridad de Tickets. Refleja a leaderstats y persiste en INTARC_Profiles_v2
-- Formato correcto (según Creator Hub): key = "u_<userId>", campo = "tickets" (lowercase)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local profileStore = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local M, _cur, _subs = {}, {}, {}

local function toInt(n)
	if typeof(n) ~= "number" then return 0 end
	return math.max(0, math.floor(n + 0.5))
end

local function dsKey(userId) return "u_" .. tostring(userId) end

local function loadTickets(p)
	local key = dsKey(p.UserId)
	local ok, data = pcall(function() return profileStore:GetAsync(key) end)
	if ok and type(data) == "table" then
		-- campo correcto 'tickets' + alias por compatibilidad
		local t = tonumber(data.tickets)
			or tonumber(data.Tickets)
			or tonumber(data.coins) or tonumber(data.Coins)
			or tonumber(data.money) or tonumber(data.Money)
			or 0
		return toInt(t)
	end
	return 0
end

local function saveTickets(p, value)
	local key = dsKey(p.UserId)
	local ok, err = pcall(function()
		local existing = profileStore:GetAsync(key)
		if type(existing) ~= "table" then existing = {} end
		existing.tickets = toInt(value)      -- ESCRIBE EN 'tickets' (lowercase) como en tu DB
		profileStore:SetAsync(key, existing)
	end)
	if not ok then
		warn("[TicketService] SetAsync falló:", key, err)
	end
end

local function fire(p)
	if _subs[p] then
		for _, cb in ipairs(_subs[p]) do task.spawn(cb, _cur[p]) end
	end
end

function M.Bind(p)
	if _cur[p] ~= nil then return end
	_cur[p] = loadTickets(p)
	p:SetAttribute("Tickets", _cur[p])
	local ls = p:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Tickets") then
		ls.Tickets.Value = _cur[p]
	end
	fire(p)
end

function M.Unbind(p)
	if _cur[p] ~= nil then saveTickets(p, _cur[p]) end
	_cur[p], _subs[p] = nil, nil
end

function M.Get(p) return toInt(_cur[p] or 0) end

function M.Set(p, value)
	_cur[p] = toInt(value)
	p:SetAttribute("Tickets", _cur[p])
	local ls = p:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Tickets") then
		ls.Tickets.Value = _cur[p]
	end
	fire(p)
end

function M.Add(p, delta)
	if delta and delta ~= 0 then M.Set(p, M.Get(p) + delta) end
end

function M.Changed(p, cb)
	_subs[p] = _subs[p] or {}
	table.insert(_subs[p], cb)
end

Players.PlayerAdded:Connect(M.Bind)
Players.PlayerRemoving:Connect(M.Unbind)
for _, p in ipairs(Players:GetPlayers()) do M.Bind(p) end

return M