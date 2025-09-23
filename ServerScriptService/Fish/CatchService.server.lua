-- ServerScriptService/Fish/CatchService.server.lua
-- Abre UI, permite Curar (20/30/40s) o Liberar (2/4/6). +1 pez tras curar (DB + OrderedStore).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")

local Signals = require((ReplicatedStorage:FindFirstChild("Fish") and ReplicatedStorage.Fish:FindFirstChild("FishSignals")) or ReplicatedStorage:WaitForChild("FishSignals"))
local TicketService = require(SSS:WaitForChild("TicketService"))

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local ORDERED_STORE_NAME = "INTARC_GlobalFish_v1"

local Profiles = DataStoreService:GetDataStore(PROFILE_STORE_NAME)
local OrderedFish = DataStoreService:GetOrderedDataStore(ORDERED_STORE_NAME)

local DUR = { Common=20, Uncommon=30, Rare=40 }
local REL = { Common=2,  Uncommon=4,  Rare=6  }

local ACTIVE: {[Player]: {rarity:string, cancel:boolean}} = {}

local function dsKey(uid) return "u_"..tostring(uid) end
local function toInt(n) if typeof(n)~="number" then return 0 end return math.max(0, math.floor(n+0.5)) end

local function getProfile(uid)
	local ok, data = pcall(function() return Profiles:GetAsync(dsKey(uid)) end)
	if not ok then return {} end
	return type(data)=="table" and data or {}
end
local function setProfile(uid, data) pcall(function() Profiles:SetAsync(dsKey(uid), data) end) end
local function incOrdered(uid, delta)
	pcall(function()
		local k = tostring(uid)
		local curr = OrderedFish:GetAsync(k) or 0
		OrderedFish:SetAsync(k, toInt(curr + delta))
	end)
end

local function capacityOf(data)
	local base = tonumber(data.capacity) or (6 + 4 * (tonumber(data.capacityLevel) or 0))
	return toInt(base)
end
local function totalFishOf(data) return toInt(data.fish or 0) end

-- Compatibilidad: permitir abrir UI desde NetService vía CatchPrompt o ShowCatch
Signals.CatchPrompt.OnServerEvent:Connect(function() end) -- sólo para que exista el Remote en servidor
Signals.ReportHit.OnServerEvent:Connect(function(p, rarity) -- si ReportHit se usa desde Net, abrimos UI
	Signals.ShowCatch:FireClient(p, { rarity = rarity or "Common" })
end)

Signals.Release.OnServerEvent:Connect(function(p, rarity)
	local reward = REL[rarity] or REL.Common
	TicketService.Add(p, reward)
end)

Signals.BeginCure.OnServerEvent:Connect(function(p, rarity)
	if ACTIVE[p] then Signals.Error:FireClient(p, "Ya estás curando un pez."); return end
	local dur = DUR[rarity] or DUR.Common
	local data = getProfile(p.UserId)
	if totalFishOf(data) >= capacityOf(data) then
		Signals.Error:FireClient(p, ("Acuario lleno (%d/%d)"):format(totalFishOf(data), capacityOf(data)))
		return
	end

	ACTIVE[p] = { rarity = rarity or "Common", cancel = false }
	for t = dur, 1, -1 do
		if not ACTIVE[p] or ACTIVE[p].cancel then return end
		Signals.CureTick:FireClient(p, t)
		task.wait(1)
	end
	local r = ACTIVE[p].rarity
	ACTIVE[p] = nil

	-- Relee y aplica
	data = getProfile(p.UserId)
	if totalFishOf(data) >= capacityOf(data) then
		Signals.Error:FireClient(p, "Capacidad alcanzada al finalizar.")
		return
	end

	data.fish = toInt((data.fish or 0) + 1)
	if r == "Common" then
		data.fishCommon = toInt((data.fishCommon or 0) + 1)
	elseif r == "Uncommon" then
		data.fishUncommon = toInt((data.fishUncommon or 0) + 1)
	else
		data.fishRare = toInt((data.fishRare or 0) + 1)
	end
	setProfile(p.UserId, data)
	incOrdered(p.UserId, 1)

	Signals.CureComplete:FireClient(p, { rarity = r })

	-- Notificar producción pasiva y visual
	if _G.Production and _G.Production.AddFish then _G.Production.AddFish(p, r) end
	if _G.Visual and _G.Visual.RefreshForPlayer then _G.Visual.RefreshForPlayer(p) end
end)

Players.PlayerRemoving:Connect(function(p) ACTIVE[p] = nil end)
print("[CatchService] Ready")