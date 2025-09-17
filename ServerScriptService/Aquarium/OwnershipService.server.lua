-- ServerScriptService/Aquarium/OwnershipService.lua
--!strict
-- FIX: require correcto de módulos (antes fallaba por pasar una string/tabla)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Profiles = require(ReplicatedStorage.Aquarium:WaitForChild("Profiles"))
local Config = require(ReplicatedStorage.Aquarium:WaitForChild("Config"))
local Utils = require(ReplicatedStorage.Aquarium:WaitForChild("Utils"))
local Signals = require(ReplicatedStorage.Aquarium:WaitForChild("Signals"))

local OwnershipService = {}

-- Busca un modelo de acuario libre en Workspace.Aquariums (OwnerUserId == 0 o nil)
local function findFreeAquarium(): Model?
	local folder = Utils.GetAquariumsFolder()
	for _, mdl in ipairs(folder:GetChildren()) do
		if mdl:IsA("Model") and (not mdl:GetAttribute(Config.OwnerAttribute) or mdl:GetAttribute(Config.OwnerAttribute) == 0) then
			return mdl
		end
	end
	return nil
end

local function markOwner(model: Model, userId: number)
	model:SetAttribute(Config.OwnerAttribute, userId)
	for _, slot in ipairs(model:GetChildren()) do
		if slot:IsA("Model") then
			slot:SetAttribute(Config.OwnerAttribute, userId)
		end
	end
end

function OwnershipService.AssignAquarium(plr: Player)
	local existing = Utils.GetPlayerAquariumModel(plr.UserId)
	if existing then
		markOwner(existing, plr.UserId)
		Signals.AssignedAquarium:FireClient(plr, existing)
		return existing
	end

	local free = findFreeAquarium()
	if free then
		markOwner(free, plr.UserId)
		Signals.AssignedAquarium:FireClient(plr, free)
		return free
	end

	-- Si no hay modelos precolocados, crea uno simple contenedor (no geometría)
	local folder = Utils.GetAquariumsFolder()
	local mdl = Instance.new("Model")
	mdl.Name = ("Aquarium_%d"):format(plr.UserId)
	mdl.Parent = folder
	markOwner(mdl, plr.UserId)
	Signals.AssignedAquarium:FireClient(plr, mdl)
	return mdl
end

function OwnershipService.ReleaseAquarium(plr: Player)
	local mdl = Utils.GetPlayerAquariumModel(plr.UserId)
	if not mdl then return end
	mdl:SetAttribute(Config.OwnerAttribute, 0)
	for _, slot in ipairs(mdl:GetChildren()) do
		if slot:IsA("Model") then
			slot:SetAttribute(Config.OwnerAttribute, 0)
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	Profiles.Get(plr.UserId) -- asegúranos de tener perfil
	OwnershipService.AssignAquarium(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
	OwnershipService.ReleaseAquarium(plr)
end)

return OwnershipService