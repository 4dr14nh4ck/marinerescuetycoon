--!strict
-- Handles Release (instant tickets) and Cure (authoritative countdown).
-- Updates leaderstats and pushes progress.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishSignals = require(ReplicatedStorage:WaitForChild("Fish"):WaitForChild("FishSignals"))
local FishConfig  = require(ReplicatedStorage:WaitForChild("Fish"):WaitForChild("FishConfig"))

local DEBUG = true
local function dbg(...) if DEBUG then print("[CatchService]", ...) end end

local function getLeaderstats(plr: Player)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then return nil end
	return {
		root    = ls,
		Fish    = (ls:FindFirstChild("Fish")    or ls:FindFirstChild("Fishes")) :: NumberValue?,
		Tickets = (ls:FindFirstChild("Tickets") or ls:FindFirstChild("Coins"))  :: NumberValue?,
		Level   = (ls:FindFirstChild("Level")   or ls:FindFirstChild("Lv"))     :: NumberValue?,
	}
end

local function rarityOfPart(p: BasePart?): string?
	if not p then return nil end
	local r = p:GetAttribute("Rarity")
	if typeof(r) == "string" then return r end
	return nil
end

local function ticketsForRelease(rarity: string): number
	if rarity == "Common" then return 2 end
	if rarity == "Uncommon" then return 4 end
	if rarity == "Rare" then return 6 end
	return 0
end

local function cureSeconds(rarity: string): number
	local data = (FishConfig.Rarity :: any)[rarity]
	return (data and data.CureSeconds) or 20
end

local function doRelease(plr: Player, fish: BasePart, rarity: string)
	local ls = getLeaderstats(plr)
	if ls and ls.Tickets then
		ls.Tickets.Value += ticketsForRelease(rarity)
	end
	if fish and fish.Parent then
		fish:Destroy()
	end
	FishSignals.CatchFeedback:FireClient(plr, "Released", "Fish released! +tickets")
	dbg("Release ->", plr.Name, rarity)
end

local function doCure(plr: Player, fish: BasePart, rarity: string)
	if not fish or not fish.Parent then return end
	local total = cureSeconds(rarity)
	local uid = tostring(fish:GetDebugId()) .. "_" .. tostring(os.clock())

	fish.Transparency = 0.8

	for t = total, 0, -1 do
		FishSignals.CureProgress:FireClient(plr, {
			uid = uid,
			secondsLeft = t,
			total = total,
			rarity = rarity,
		})
		task.wait(1)
		if not fish.Parent then
			dbg("Cure aborted, fish destroyed")
			return
		end
	end

	local ls = getLeaderstats(plr)
	if ls and ls.Fish then
		ls.Fish.Value += 1
	end
	if fish and fish.Parent then
		fish:Destroy()
	end

	FishSignals.CatchFeedback:FireClient(plr, "Cured", "Fish cured! +1 Fish")
	dbg("Cure done ->", plr.Name, rarity)
end

FishSignals.CatchDecision.OnServerEvent:Connect(function(plr: Player, payload: any)
	if type(payload) ~= "table" then return end
	local fish = payload.Fish
	if not fish or not fish:IsA("BasePart") then return end
	local rarity = rarityOfPart(fish)
	if not rarity then
		local cur: Instance? = fish
		while cur and cur:IsA("BasePart") and (cur :: BasePart):GetAttribute("Rarity") == nil do
			cur = cur.Parent
		end
		if cur and cur:IsA("BasePart") then
			rarity = (cur :: BasePart):GetAttribute("Rarity")
			fish = cur :: BasePart
		end
	end
	if not rarity then return end

	if payload.Choice == "Release" then
		doRelease(plr, fish, rarity)
	elseif payload.Choice == "Cure" then
		task.spawn(function() doCure(plr, fish, rarity) end)
	end
end)

dbg("Ready")