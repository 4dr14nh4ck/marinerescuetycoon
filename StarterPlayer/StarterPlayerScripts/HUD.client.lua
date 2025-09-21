-- StarterPlayer/StarterPlayerScripts/HUD.client.lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 1) Referencia al GUI que contiene los textos del HUD
--    Si tu ScreenGui no es el parent del script, cámbialo por la ruta correcta.
local rootGui = script.Parent  -- normalmente el Script está dentro del ScreenGui del HUD

-- Helper para localizar TextLabels por varios nombres posibles, buscando en descendencia
local function findLabel(candidates)
	for _, name in ipairs(candidates) do
		local inst = rootGui:FindFirstChild(name, true)
		if inst and inst:IsA("TextLabel") then
			return inst
		end
	end
	return nil
end

-- 2) Intenta localizar las tres labels (pon aquí tus nombres si ya los conoces)
local fishLabel    = findLabel({ "FishValue", "FishText", "Fish", "TxtFish", "LblFish" })
local levelLabel   = findLabel({ "LevelValue", "LevelText", "Level", "TxtLevel", "LblLevel", "LvValue", "Lv" })
local ticketsLabel = findLabel({ "TicketsValue", "TicketsText", "Tickets", "TxtTickets", "LblTickets", "CoinsValue" })

-- 3) Espera a leaderstats y a sus hijos estándar
local leaderstats = LocalPlayer:WaitForChild("leaderstats")
local fish    = leaderstats:WaitForChild("Fish")
local tickets = leaderstats:WaitForChild("Tickets")
local level   = leaderstats:WaitForChild("Level")

-- 4) Funciones de pintado
local function fmt(n)
	-- formato corto: 1.2K, 3.4M si quieres; si no, simplemente tostring(n)
	if n >= 1e6 then
		return string.format("%.1fM", n/1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n/1e3)
	else
		return tostring(n)
	end
end

local function updateFish()
	if fishLabel then fishLabel.Text = fmt(fish.Value) end
end
local function updateTickets()
	if ticketsLabel then ticketsLabel.Text = fmt(tickets.Value) end
end
local function updateLevel()
	if levelLabel then levelLabel.Text = tostring(level.Value) end
end

-- 5) Pintado inicial + suscripciones
updateFish(); updateTickets(); updateLevel()

fish:GetPropertyChangedSignal("Value"):Connect(updateFish)
tickets:GetPropertyChangedSignal("Value"):Connect(updateTickets)
level:GetPropertyChangedSignal("Value"):Connect(updateLevel)