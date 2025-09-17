-- ReplicatedStorage/Aquarium/Profiles.lua
--!strict
-- Perfil simple en memoria (puedes migrarlo a DataStore mas adelante)
local Players = game:GetService("Players")
local Config = require(game.ReplicatedStorage.Aquarium:WaitForChild("Config"))

type Profile = {
	UserId: number,
	SlotsOwned: number,
}

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

-- Limpia perfiles al salir para no filtrar memoria en Studio
Players.PlayerRemoving:Connect(function(plr)
	Profiles[plr.UserId] = nil
end)

return M