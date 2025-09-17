--!strict
-- TutorialUI.client.lua
-- Mantiene la jerarquía: TutorialUI > Frame > Card > Body (ScrollingFrame)
-- Reemplaza cualquier uso de Body:AddItem(x) por item.Parent = Body

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--========================
-- CONFIG
--========================
local STEPS = {
	{ title = "Bienvenido", body = "Este es Marine Rescue Tycoon. Captura peces con tu red y gestiona tu acuario." },
	{ title = "Movimiento", body = "Muévete con WASD y salta con Space. Mantén Shift para correr." },
	{ title = "Tu Red", body = "Si no tienes la red, se te entrega automáticamente al entrar. Úsala para capturar peces." },
	{ title = "Acuario", body = "Tienes un acuario propio. Coloca/gestiona peces y mira cómo progresa." },
	{ title = "Progresión", body = "Gana Fish y Tickets. Usa los puntos de mejora (prompts) para ampliar y mejorar." },
}

local THEME = {
	cardW = 520,
	cardH = 300,
	bgTransparency = 0.35,
	accent = Color3.fromRGB(255,255,255),
}

--========================
-- UI BASE
--========================
local gui = Instance.new("ScreenGui")
gui.Name = "TutorialUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Enabled = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Frame"
frame.Size = UDim2.fromScale(1,1)
frame.BackgroundColor3 = Color3.new(0,0,0)
frame.BackgroundTransparency = 1
frame.Parent = gui

local dim = Instance.new("TextButton")
dim.Name = "Dim"
dim.AutoButtonColor = false
dim.Text = ""
dim.Size = UDim2.fromScale(1,1)
dim.BackgroundColor3 = Color3.new(0,0,0)
dim.BackgroundTransparency = 0.5
dim.Parent = frame

-- Tarjeta
local card = Instance.new("Frame")
card.Name = "Card"
card.Size = UDim2.fromOffset(THEME.cardW, THEME.cardH)
card.AnchorPoint = Vector2.new(0.5,0.5)
card.Position = UDim2.fromScale(0.5,0.5)
card.BackgroundColor3 = Color3.fromRGB(30,30,40)
card.BackgroundTransparency = THEME.bgTransparency
card.BorderSizePixel = 0
card.Parent = frame

local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,16); corner.Parent = card
local stroke = Instance.new("UIStroke"); stroke.Thickness = 1; stroke.Color = Color3.fromRGB(200,200,200); stroke.Transparency = 0.4; stroke.Parent = card

-- Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -24, 0, 36)
title.Position = UDim2.new(0, 12, 0, 10)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(245,245,245)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

-- Cuerpo (ScrollingFrame)
local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.Size = UDim2.new(1, -24, 1, -100)
body.Position = UDim2.new(0, 12, 0, 52)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 6
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.CanvasSize = UDim2.new(0,0,0,0)
body.Parent = card

-- Layout de lista para los items del cuerpo
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 8)
layout.Parent = body

-- Footer con botones
local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.BackgroundTransparency = 1
footer.Size = UDim2.new(1, -24, 0, 40)
footer.Position = UDim2.new(0, 12, 1, -48)
footer.Parent = card

local buttons = Instance.new("Frame")
buttons.Name = "Buttons"
buttons.BackgroundTransparency = 1
buttons.Size = UDim2.new(1,0,1,0)
buttons.Parent = footer

local blayout = Instance.new("UIListLayout")
blayout.FillDirection = Enum.FillDirection.Horizontal
blayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
blayout.Padding = UDim.new(0,8)
blayout.Parent = buttons

local function newBtn(text: string)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(140, 36)
	b.BackgroundColor3 = THEME.accent
	b.TextColor3 = Color3.fromRGB(30,30,30)
	b.AutoButtonColor = true
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.Text = text
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = b
	return b
end

local skipBtn = newBtn("Saltar")
skipBtn.Parent = buttons

local nextBtn = newBtn("Siguiente")
nextBtn.Parent = buttons

--========================
-- LÓGICA
--========================
local index = 1

local function makeBodyItem(text: string)
	local item = Instance.new("TextLabel")
	item.BackgroundTransparency = 0.2
	item.TextWrapped = true
	item.Size = UDim2.new(1, -6, 0, 28)
	item.Font = Enum.Font.Gotham
	item.TextScaled = true
	item.TextColor3 = Color3.fromRGB(235,235,235)
	item.Text = "• "..text
	local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,8); ic.Parent = item
	return item
end

local function clearBody()
	for _, ch in ipairs(body:GetChildren()) do
		if ch:IsA("GuiObject") and ch ~= layout then
			ch:Destroy()
		end
	end
end

local function buildUI()
	local step = STEPS[index]
	if not step then return end

	title.Text = step.title
	clearBody()

	-- IMPORTANTE: antes se hacía Body:AddItem(x) -> eso NO existe. Ahora:
	-- creamos los items y les ponemos Parent = body (con UIListLayout).
	local lines = string.split(step.body, ". ")
	for i, line in ipairs(lines) do
		if line == "" then continue end
		local item = makeBodyItem(line .. (i < #lines and "." or ""))
		item.Parent = body
	end

	-- Animación suave de aparición
	card.BackgroundTransparency = 0.5
	TweenService:Create(card, TweenInfo.new(0.18), {BackgroundTransparency = THEME.bgTransparency}):Play()

	nextBtn.Text = (index >= #STEPS) and "Entendido" or "Siguiente"
end

nextBtn.MouseButton1Click:Connect(function()
	if index < #STEPS then
		index += 1
		buildUI()
	else
		gui.Enabled = false
	end
end)

skipBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

dim.MouseButton1Click:Connect(function() end) -- bloquea clicks al fondo

-- Inicial
buildUI()