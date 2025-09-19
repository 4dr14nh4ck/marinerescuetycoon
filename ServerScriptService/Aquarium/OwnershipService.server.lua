--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Aquarium:WaitForChild("Config"))
local Profiles = require(ReplicatedStorage.Aquarium:WaitForChild("Profiles"))
local Utils = require(ReplicatedStorage.Aquarium:WaitForChild("Utils"))
local Signals = require(ReplicatedStorage.Aquarium:WaitForChild("Signals"))

local function markOwner(model: Model, userId: number)
	model:SetAttribute(Config.OwnerAttribute, userId)
	for _, slot in ipairs(model:GetChildren()) do
		if slot:IsA("Model") then
			slot:SetAttribute(Config.OwnerAttribute, userId)
		end
	end
end

local function findFreeAquarium(): Model?
	local f = Utils.GetAquariumsFolder()
	for _, mdl in ipairs(f:GetChildren()) do
		if mdl:IsA("Model") then
			local attr = mdl:GetAttribute(Config.OwnerAttribute)
			if not attr or attr == 0 then
				return mdl
			end
		end
	end
	return nil
end

local function assign(plr: Player)
	Profiles.Get(plr.UserId)
	local existing = Utils.GetPlayerAquariumModel(plr.UserId)
	if existing then
		markOwner(existing, plr.UserId)
		Signals.AssignedAquarium:FireClient(plr, existing)
		return
	end
	local free = findFreeAquarium()
	if not free then
		local folder = Utils.GetAquariumsFolder()
		free = Instance.new("Model")
		free.Name = ("Aquarium_%d"):format(plr.UserId)
		free.Parent = folder
	end
	markOwner(free, plr.UserId)
	Signals.AssignedAquarium:FireClient(plr, free)
end

local function release(plr: Player)
	local mdl = Utils.GetPlayerAquariumModel(plr.UserId)
	if not mdl then return end
	mdl:SetAttribute(Config.OwnerAttribute, 0)
	for _, slot in ipairs(mdl:GetChildren()) do
		if slot:IsA("Model") then
			slot:SetAttribute(Config.OwnerAttribute, 0)
		end
	end
end

Players.PlayerAdded:Connect(assign)
Players.PlayerRemoving:Connect(release)