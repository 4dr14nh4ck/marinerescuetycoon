-- ServerScriptService/Aquarium/Production.server.lua
-- Genera tickets pasivamente cada 5s: Common=+1, Uncommon=+2, Rare=+3
-- Desfase: escalonado para que la sensación sea continua.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")

local TicketService = require(SSS:WaitForChild("TicketService"))

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local Profiles = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local function dsKey(uid) return "u_"..tostring(uid) end
local function toInt(n) if typeof(n)~="number" then return 0 end return math.max(0, math.floor(n+0.5)) end

local LIVE = {} -- por jugador: { loops = {RBXScriptConnection...}, counts = {Common=..,Uncommon=..,Rare=..} }

local function fetchCounts(p)
	local ok, data = pcall(function() return Profiles:GetAsync(dsKey(p.UserId)) end)
	data = ok and type(data)=="table" and data or {}
	return {
		Common   = toInt(data.fishCommon   or 0),
		Uncommon = toInt(data.fishUncommon or 0),
		Rare     = toInt(data.fishRare     or 0),
	}
end

local REWARD = { Common=1, Uncommon=2, Rare=3 }

local function startLoops(p, counts)
	-- limpia anteriores
	if LIVE[p] and LIVE[p].loops then
		for _, th in ipairs(LIVE[p].loops) do
			if typeof(th) == "RBXScriptConnection" then th:Disconnect() end
		end
	end
	LIVE[p] = { loops = {}, counts = counts }

	local idx = 0
	for rarity, count in pairs(counts) do
		for i = 1, count do
			idx += 1
			-- escalonado: offsets 0..4 segundos
			local offset = (idx - 1) % 5
			-- cada "loop" es un simple task.spawn + while true do wait(5)
			task.spawn(function()
				task.wait(offset)
				while LIVE[p] and LIVE[p].counts and LIVE[p].counts[rarity] and i <= LIVE[p].counts[rarity] do
					TicketService.Add(p, REWARD[rarity])
					task.wait(5)
				end
			end)
		end
	end
end

local function initPlayer(p)
	local counts = fetchCounts(p)
	startLoops(p, counts)
end

local function cleanup(p)
	LIVE[p] = nil
end

-- API para CatchService (+1 fish tras curar)
_G.Production = _G.Production or {}
function _G.Production.AddFish(p, rarity)
	if not LIVE[p] then initPlayer(p) return end
	local counts = LIVE[p].counts
	counts[rarity] = toInt((counts[rarity] or 0) + 1)
	startLoops(p, counts)
end

Players.PlayerAdded:Connect(initPlayer)
Players.PlayerRemoving:Connect(cleanup)
for _, plr in ipairs(Players:GetPlayers()) do initPlayer(plr) end

print("[Production] Ready")