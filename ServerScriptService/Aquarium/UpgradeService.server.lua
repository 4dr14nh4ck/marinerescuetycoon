-- ServerScriptService/Aquarium/UpgradeService (ModuleScript)
--!strict
-- FIX principal: sustituir TODOS los ".FindChild" por ":FindFirstChild" y usar :WaitForChild cuando corresponda.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Aquarium:WaitForChild("Config"))
local Utils = require(ReplicatedStorage.Aquarium:WaitForChild("Utils"))
local Signals = require(ReplicatedStorage.Aquarium:WaitForChild("Signals"))

local UpgradeService = {}

-- Devuelve los slots (Model) pertenecientes al jugador
local function getAllSlots(plr: Player): {Model}
	local mdl = Utils.GetPlayerAquariumModel(plr.UserId)
	if not mdl then return {} end
	local out = {}
	for _, ch in ipairs(mdl:GetChildren()) do
		if ch:IsA("Model") then
			table.insert(out, ch)
		end
	end
	return out
end

-- Ciclo de farmeo/producción sobre los slots del jugador
function UpgradeService.FarmTick(plr: Player)
	for _, slot in ipairs(getAllSlots(plr)) do
		-- ejemplo: sumar coins por cada slot con un Value llamado "Yield"
		local yieldValue = slot:FindFirstChild("Yield") :: NumberValue
		if yieldValue then
			local ls = plr:FindFirstChild("leaderstats")
			local coins = ls and ls:FindFirstChild("Coins")
			if coins then
				coins.Value += yieldValue.Value
			end
		end
	end
end

-- Bindear ProximityPrompts de mejora (si los tienes en tus modelos)
function UpgradeService.BindAll(plr: Player)
	for _, slot in ipairs(getAllSlots(plr)) do
		local prompt = slot:FindFirstChild("UpgradePrompt", true) -- busca recursivo
		if prompt and prompt:IsA("ProximityPrompt") and not prompt:GetAttribute("Bound") then
			prompt.Triggered:Connect(function(triggeringPlr)
				if triggeringPlr ~= plr then return end
				Signals.UpgradeRequested:FireServer(slot.Name, "Level") -- ejemplo, puedes cambiarlo
			end)
			prompt:SetAttribute("Bound", true)
		end
	end
end

-- Bucle de farmeo global (simple)
task.spawn(function()
	while true do
		task.wait(Config.FarmTick)
		for _, plr in ipairs(Players:GetPlayers()) do
			UpgradeService.FarmTick(plr)
		end
	end
end)

return UpgradeService