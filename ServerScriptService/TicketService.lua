-- ServerScriptService/TicketService.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local profileStore = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local M, _cur, _subs = {}, {}, {}

local function toInt(n) if typeof(n) ~= "number" then return 0 end return math.max(0, math.floor(n + 0.5)) end
local function key(uid) return "Player_"..tostring(uid) end

local function load(p)
	local k = key(p.UserId)
	local ok, data = pcall(function() return profileStore:GetAsync(k) end)
	if ok and type(data) == "table" then
		local t = tonumber(data.Tickets) or tonumber(data.Coins) or tonumber(data.Money) or tonumber(data.Currency) or 0
		return toInt(t)
	end
	return 0
end

local function save(p, v)
	local k = key(p.UserId)
	pcall(function()
		local existing = profileStore:GetAsync(k)
		if type(existing) ~= "table" then existing = {} end
		existing.Tickets = toInt(v)
		profileStore:SetAsync(k, existing)
	end)
end

local function fire(p) if _subs[p] then for _, cb in ipairs(_subs[p]) do task.spawn(cb, _cur[p]) end end end

function M.Bind(p)
	if _cur[p] ~= nil then return end
	_cur[p] = load(p)
	p:SetAttribute("Tickets", _cur[p])
	local ls = p:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Tickets") then ls.Tickets.Value = _cur[p] end
	fire(p)
end

function M.Unbind(p) if _cur[p] ~= nil then save(p,_cur[p]) end _cur[p],_subs[p]=nil,nil end
function M.Get(p) return toInt(_cur[p] or 0) end
function M.Set(p,value) _cur[p]=toInt(value) p:SetAttribute("Tickets",_cur[p]) local ls=p:FindFirstChild("leaderstats"); if ls and ls:FindFirstChild("Tickets") then ls.Tickets.Value=_cur[p] end fire(p) end
function M.Add(p,delta) if delta and delta~=0 then M.Set(p, M.Get(p)+delta) end end
function M.Changed(p,cb) _subs[p]=_subs[p] or {} table.insert(_subs[p],cb) end

Players.PlayerAdded:Connect(M.Bind)
Players.PlayerRemoving:Connect(M.Unbind)
for _,p in ipairs(Players:GetPlayers()) do M.Bind(p) end

return M