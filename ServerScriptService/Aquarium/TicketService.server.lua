-- ServerScriptService/Aquarium/TicketService.lua
-- Producción de tickets:
-- - Cada pez produce cada 5s
-- - Desfase de 1s entre peces (offset 0,1,2,...)
-- - Common = +1, Uncommon = +2, Rare = +3

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Profiles= require(RS:WaitForChild("Aquarium"):WaitForChild("Profiles"))

local PERIOD = 5 -- s
local VALUE = { Common = 1, Uncommon = 2, Rare = 3 }

-- Mapa por jugador: offset base (persistente en runtime) para escalonar
local Offsets = {} -- [userId] = next offset to assign (we'll just enumerate fish each tick)

local function ensureLeaderstats(plr)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = plr
	end
	local fish = ls:FindFirstChild("Fish") or Instance.new("IntValue"); fish.Name="Fish"; fish.Parent=ls
	local tks  = ls:FindFirstChild("Tickets") or Instance.new("IntValue"); tks.Name="Tickets"; tks.Parent=ls
	-- Inicializa con perfil actual
	local p = Profiles.Get(plr.UserId)
	fish.Value = p.fish or 0
	tks.Value  = p.tickets or 0
end

local function produceForPlayer(plr, nowSec)
	local uid = plr.UserId
	local p = Profiles.Get(uid)

	-- Lee conteos por rareza
	local cU,cN,cR = p.fishCommon or 0, p.fishUncommon or 0, p.fishRare or 0
	local total = (cU + cN + cR)
	if total <= 0 then return end

	-- Asegura offsets
	local base = Offsets[uid] or 0
	-- Vamos a enumerar peces en orden: primero Common, luego Uncommon, luego Rare
	-- Offsets: 0..total-1 (mod PERIOD para calcular fase)
	local idx = 0
	local gained = 0

	local function tickGroup(count, val)
		local g = 0
		for i=1,count do
			local offset = (base + idx) -- desfase único por pez
			if (nowSec - offset) % PERIOD == 0 then
				g += val
			end
			idx += 1
		end
		return g
	end

	gained += tickGroup(cU, VALUE.Common)
	gained += tickGroup(cN, VALUE.Uncommon)
	gained += tickGroup(cR, VALUE.Rare)

	if gained > 0 then
		Profiles.Inc(uid, "tickets", gained)
		-- sync leaderstats
		local ls = plr:FindFirstChild("leaderstats")
		local tks = ls and ls:FindFirstChild("Tickets")
		if tks then tks.Value = Profiles.Get(uid).tickets end
	end

	-- Ajusta base para que el patrón vaya "corriendo" lentamente y se vea fluido
	Offsets[uid] = (base + 1) % PERIOD
end

-- Loop maestro (cada 1s)
task.spawn(function()
	while true do
		local now = math.floor(os.time())
		for _,plr in ipairs(Players:GetPlayers()) do
			produceForPlayer(plr, now)
		end
		task.wait(1)
	end
end)

Players.PlayerAdded:Connect(function(plr)
	ensureLeaderstats(plr)
	Offsets[plr.UserId] = 0
end)

for _,plr in ipairs(Players:GetPlayers()) do
	ensureLeaderstats(plr)
	Offsets[plr.UserId] = 0
end

Players.PlayerRemoving:Connect(function(plr)
	Offsets[plr.UserId] = nil
	Profiles.Save(plr.UserId) -- guardar por si había tickets pendientes
end)