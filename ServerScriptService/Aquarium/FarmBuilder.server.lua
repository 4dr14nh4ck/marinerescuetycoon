-- ServerScriptService/Aquarium/FarmBuilder (STUDIO-ONLY)
--!strict
-- Construye/asegura slots mínimos al asignar acuario
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Profiles = require(ReplicatedStorage.Aquarium:WaitForChild("Profiles"))
local Config = require(ReplicatedStorage.Aquarium:WaitForChild("Config"))
local Utils = require(ReplicatedStorage.Aquarium:WaitForChild("Utils"))

local function ensureSlots(plr: Player)
	local profile = Profiles.Get(plr.UserId)
	local mdl = Utils.GetPlayerAquariumModel(plr.UserId)
	if not mdl then return end

	local existing = 0
	for _, ch in ipairs(mdl:GetChildren()) do
		if ch:IsA("Model") then existing += 1 end
	end

	for i = existing + 1, profile.SlotsOwned do
		local slot = Instance.new("Model")
		slot.Name = ("Slot%d"):format(i)
		slot:SetAttribute(Config.OwnerAttribute, plr.UserId)

		local yield = Instance.new("NumberValue")
		yield.Name = "Yield"
		yield.Value = 1
		yield.Parent = slot

		slot.Parent = mdl
	end
	print("[FarmBuilder] Built", profile.SlotsOwned, "AquariumSlot(s).")
end

Players.PlayerAdded:Connect(ensureSlots)