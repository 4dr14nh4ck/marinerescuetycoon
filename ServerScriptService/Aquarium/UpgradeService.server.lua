--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Aquarium:WaitForChild("Config"))
local Utils = require(ReplicatedStorage.Aquarium:WaitForChild("Utils"))

local function playerSlots(plr: Player): {Model}
	local mdl = Utils.GetPlayerAquariumModel(plr.UserId)
	if not mdl then return {} end
	local out = {}
	for _, ch in ipairs(mdl:GetChildren()) do
		if ch:IsA("Model") then table.insert(out, ch) end
	end
	return out
end

local function farmTick(plr: Player)
	for _, slot in ipairs(playerSlots(plr)) do
		local yieldValue = slot:FindFirstChild("Yield") :: NumberValue
		if yieldValue then
			local ls = plr:FindFirstChild("leaderstats")
			local fish = ls and ls:FindFirstChild("Fish")
			if fish then
				fish.Value += yieldValue.Value
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(Config.FarmTick)
		for _, plr in ipairs(Players:GetPlayers()) do
			farmTick(plr)
		end
	end
end)