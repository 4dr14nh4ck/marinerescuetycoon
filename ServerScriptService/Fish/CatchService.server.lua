-- ServerScriptService/Fish/CatchService.server.lua
-- Lógica de atrapado -> UI -> Curar(20/30/40s) o Liberar(2/4/6 tickets).
-- Cura: +1 Fish (Profiles 'fish' y por rareza) + OrderedStore.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")

local Signals = require(ReplicatedStorage:WaitForChild("Fish"):FindFirstChild("FishSignals") or ReplicatedStorage:WaitForChild("FishSignals"))
local TicketService = require(SSS:WaitForChild("TicketService"))

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local ORDERED_STORE_NAME = "INTARC_GlobalFish_v1"

local Profiles = DataStoreService:GetDataStore(PROFILE_STORE_NAME)
local OrderedFish = DataStoreService:GetOrderedDataStore(ORDERED_STORE_NAME)

local DUR = { Common=20, Uncommon=30, Rare=40 }
local REL = { Common=2,  Uncommon=4,  Rare=6  }

local ACTIVE = {}  -- por jugador: { rarity=..., cancel=false }

local function dsKey(uid) return "u_"..tostring(uid) end
local function toInt(n) if typeof(n)~="number" then return 0 end return math.max(0, math.floor(n+0.5)) end

local function getProfile(uid)
	local ok, data = pcall(function() return Profiles:GetAsync(dsKey(uid)) end)
	if not ok then return {} end
	return type(data)=="table" and data or {}
end

local function setProfile(uid, data)
	pcall(function() Profiles:SetAsync(dsKey(uid), data) end)
end

local function incOrdered(uid, delta)
	pcall(function()
		local k = tostring(uid)
		local curr = OrderedFish:GetAsync(k) or 0
		OrderedFish:SetAsync(k, toInt(curr + delta))
	end)
end

-- Validación de capacidad (cap actual vs peces)
local function capacityOf(data)
	local base = tonumber(data.capacity) or (6 + 4 * (tonumber(data.capacityLevel) or 0))
	return toInt(base)
end

local function totalFishOf(data)
	return toInt((data.fish) or 0)
end

-- Mostrar UI (desde NetService o propio)
local function showCatch(p, rarity)
	if not DUR[rarity] then rarity = "Common" end
	Signals.ShowCatch:FireClient(p, { rarity = rarity })
end

-- Integración: si NetService reporta el impacto, abrimos la UI
Signals.ReportHit.OnServerEvent:Connect(function(p, rarity)
	showCatch(p, rarity)
end)

-- Release inmediato
Signals.Release.OnServerEvent:Connect(function(p, rarity)
	local reward = REL[rarity] or REL.Common
	TicketService.Add(p, reward)
end)

-- Curación con cuenta atrás
Signals.BeginCure.OnServerEvent:Connect(function(p, rarity)
	if ACTIVE[p] then
		Signals.Error:FireClient(p, "Ya estás curando un pez.")
		return
	end
	local dur = DUR[rarity] or DUR.Common
	local data = getProfile(p.UserId)
	local cap = capacityOf(data)
	local total = totalFishOf(data)
	if total >= cap then
		Signals.Error:FireClient(p, ("Acuario lleno (%d/%d)"):format(total, cap))
		return
	end

	ACTIVE[p] = { rarity = rarity, cancel = false }
	for t = dur, 1, -1 do
		if ACTIVE[p] == nil or ACTIVE[p].cancel then return end
		Signals.CureTick:FireClient(p, t)
		task.wait(1)
	end

	-- Fin de cura: +1 fish (perfil + ordered store)
	ACTIVE[p] = nil

	-- Relee por seguridad (cap pudo cambiar)
	data = getProfile(p.UserId)
	cap = capacityOf(data)
	total = totalFishOf(data)
	if total >= cap then
		Signals.Error:FireClient(p, "Capacidad alcanzada al finalizar.")
		return
	end

	data.fish = toInt((data.fish or 0) + 1)
	if rarity == "Common" then
		data.fishCommon = toInt((data.fishCommon or 0) + 1)
	elseif rarity == "Uncommon" then
		data.fishUncommon = toInt((data.fishUncommon or 0) + 1)
	elseif rarity == "Rare" then
		data.fishRare = toInt((data.fishRare or 0) + 1)
	end
	setProfile(p.UserId, data)
	incOrdered(p.UserId, 1)

	-- Aviso a cliente (cierra UI)
	Signals.CureComplete:FireClient(p, { rarity = rarity })

	-- Notifica a producción pasiva (si está cargada)
	if _G.Production and _G.Production.AddFish then
		_G.Production.AddFish(p, rarity)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	ACTIVE[p] = nil
end)

print("[CatchService] Ready")