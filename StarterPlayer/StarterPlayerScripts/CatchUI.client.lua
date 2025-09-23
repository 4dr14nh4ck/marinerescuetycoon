-- StarterPlayer/StarterPlayerScripts/CatchUI.client.lua
-- UI de captura con Curar/Release + countdown.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local FishFolder = ReplicatedStorage:FindFirstChild("Fish")
local Signals = require((FishFolder and FishFolder:FindFirstChild("FishSignals")) or ReplicatedStorage:WaitForChild("FishSignals"))

-- === UI básica (auto-creada si no existe) ===
local gui = player:WaitForChild("PlayerGui")
local screen = gui:FindFirstChild("CatchUI") or Instance.new("ScreenGui")
screen.Name = "CatchUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Enabled = false
screen.Parent = gui

local frame = screen:FindFirstChild("Frame") or Instance.new("Frame")
frame.Name = "Frame"
frame.AnchorPoint = Vector2.new(0.5, 0.75)
frame.Position = UDim2.fromScale(0.5, 0.75)
frame.Size = UDim2.fromOffset(320, 140)
frame.BackgroundTransparency = 0.2
frame.Parent = screen

local title = frame:FindFirstChild("Title") or Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 28)
title.Text = "¡Pez atrapado!"
title.TextScaled = true
title.BackgroundTransparency = 1
title.Parent = frame

local subtitle = frame:FindFirstChild("Subtitle") or Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Position = UDim2.fromOffset(0, 30)
subtitle.Size = UDim2.new(1, 0, 0, 24)
subtitle.Text = ""
subtitle.TextScaled = true
subtitle.BackgroundTransparency = 1
subtitle.Parent = frame

local countdown = frame:FindFirstChild("Countdown") or Instance.new("TextLabel")
countdown.Name = "Countdown"
countdown.Position = UDim2.fromOffset(0, 56)
countdown.Size = UDim2.new(1, 0, 0, 36)
countdown.Text = ""
countdown.TextScaled = true
countdown.BackgroundTransparency = 1
countdown.Parent = frame

local btnCure = frame:FindFirstChild("BtnCure") or Instance.new("TextButton")
btnCure.Name = "BtnCure"
btnCure.Position = UDim2.fromOffset(20, 100)
btnCure.Size = UDim2.fromOffset(130, 32)
btnCure.Text = "Curar"
btnCure.TextScaled = true
btnCure.Parent = frame

local btnRelease = frame:FindFirstChild("BtnRelease") or Instance.new("TextButton")
btnRelease.Name = "BtnRelease"
btnRelease.Position = UDim2.fromOffset(170, 100)
btnRelease.Size = UDim2.fromOffset(130, 32)
btnRelease.Text = "Liberar"
btnRelease.TextScaled = true
btnRelease.Parent = frame

-- ❗️Quita la anotación de tipo (era la causa del error)
local currentRarity

local function openUI(rarity)
	currentRarity = rarity or "Common"
	subtitle.Text = ("Rareza: %s"):format(currentRarity)
	countdown.Text = ""
	btnCure.Visible = true
	btnRelease.Visible = true
	screen.Enabled = true
end

-- Compat: tu NetService emite CatchPrompt; mantenemos ShowCatch también
Signals.CatchPrompt.OnClientEvent:Connect(function(payload)
	openUI(payload and payload.Rarity or "Common")
end)

Signals.ShowCatch.OnClientEvent:Connect(function(payload)
	openUI(payload and payload.rarity or "Common")
end)

Signals.CureTick.OnClientEvent:Connect(function(secLeft)
	btnCure.Visible = false
	btnRelease.Visible = false
	countdown.Text = ("Curando... %ds"):format(secLeft)
end)

Signals.CureComplete.OnClientEvent:Connect(function()
	screen.Enabled = false
	currentRarity = nil
end)

Signals.Error.OnClientEvent:Connect(function(msg)
	subtitle.Text = tostring(msg or "Error")
end)

btnCure.MouseButton1Click:Connect(function()
	if currentRarity then
		Signals.BeginCure:FireServer(currentRarity)
	end
end)

btnRelease.MouseButton1Click:Connect(function()
	if currentRarity then
		Signals.Release:FireServer(currentRarity)
		screen.Enabled = false
		currentRarity = nil
	end
end)