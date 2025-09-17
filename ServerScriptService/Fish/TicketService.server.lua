-- ServerScriptService/Fish/TicketService.lua
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Profiles = require(RS:WaitForChild("Aquarium"):WaitForChild("Profiles"))

local INTERVAL = 10
local PER_FISH = 1

task.spawn(function()
	while true do
		task.wait(INTERVAL)
		for _,plr in ipairs(Players:GetPlayers()) do
			local p = Profiles.Get(plr.UserId)
			local occ = tonumber(p.fish) or 0
			if occ > 0 then
				p.tickets = (tonumber(p.tickets) or 0) + occ * PER_FISH
				Profiles.MarkDirty(plr.UserId)
				Profiles.Save(plr.UserId)

				local ls = plr:FindFirstChild("leaderstats")
				local tk = ls and ls:FindFirstChild("Tickets")
				if tk then tk.Value = p.tickets end
			end
		end
	end
end)