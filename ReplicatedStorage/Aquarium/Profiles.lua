-- ReplicatedStorage/Aquarium/Profiles.lua
--!strict
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Aquarium:WaitForChild("Config"))

type Profile = { UserId: number, SlotsOwned: number }
local Profiles: {[number]: Profile} = {}

local M = {}

function M.Get(userId: number): Profile
	local p = Profiles[userId]
	if not p then
		p = {UserId = userId, SlotsOwned = Config.StartingSlots}
		Profiles[userId] = p
	end
	return p
end

function M.SetSlots(userId: number, slots: number)
	local p = M.Get(userId)
	p.SlotsOwned = math.clamp(slots, 0, Config.MaxSlotsPerAquarium)
end

Players.PlayerRemoving:Connect(function(plr)
	Profiles[plr.UserId] = nil
end)

return M