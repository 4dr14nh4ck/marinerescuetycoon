--!strict
-- Servicio simple: canjea Fish por Tickets (si ya tienes otro, deja el tuyo y borra este)
local Players = game:GetService("Players")

local RATE = 10 -- 10 fish -> 1 ticket

local function tryConvert(plr: Player)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then return end
	local fish = ls:FindFirstChild("Fish")
	local tickets = ls:FindFirstChild("Tickets")
	if not fish or not tickets then return end
	while fish.Value >= RATE do
		fish.Value -= RATE
		tickets.Value += 1
	end
end

Players.PlayerAdded:Connect(function(plr)
	task.spawn(function()
		while plr.Parent do
			task.wait(8)
			tryConvert(plr)
		end
	end)
end)