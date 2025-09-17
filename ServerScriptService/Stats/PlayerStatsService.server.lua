-- ServerScriptService/Stats/PlayerStatsService.lua
--!strict
local Players = game:GetService("Players")

local function ensureLeaderstats(plr: Player)
	local ls = plr:FindFirstChild("leaderstats") :: Folder
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = plr
	end

	-- Migración: si por alguna razón existe "Peces", lo renombramos a "Fish"
	local old = ls:FindFirstChild("Peces")
	if old and not ls:FindFirstChild("Fish") then
		old.Name = "Fish"
	end

	local coins = ls:FindFirstChild("Coins") :: IntValue
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = ls
	end

	local fish = ls:FindFirstChild("Fish") :: IntValue
	if not fish then
		fish = Instance.new("IntValue")
		fish.Name = "Fish"
		fish.Parent = ls
	end

	local tickets = ls:FindFirstChild("Tickets") :: IntValue
	if not tickets then
		tickets = Instance.new("IntValue")
		tickets.Name = "Tickets"
		tickets.Parent = ls
	end
end

Players.PlayerAdded:Connect(ensureLeaderstats)