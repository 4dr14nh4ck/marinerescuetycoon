--!strict
-- Tutorial en cliente con la misma jerarquía del panel original y sin AddItem.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local STEPS = {
	{ title = "Bienvenido", body = "Captura peces con tu red y gestiona tu acuario." },
	{ title = "Movimiento", body = "WASD para moverte y Space para saltar." },
	{ title = "Red",       body = "Si no te aparece, se te entrega automáticamente." },
	{ title = "Acuario",   body = "Gestiona peces, slots y mejoras para progresar." },
}

local gui = Instance.new("ScreenGui")
gui.Name = "TutorialUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = pg

local root = Instance.new("Frame")
root.Name = "Frame"
root.Size = UDim2.fromScale(1,1)
root.BackgroundColor3 = Color3.new(0,0,0)
root.BackgroundTransparency = 0.45
root.Parent = gui

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5,0.5)
card.Position = UDim2.fromScale(0.5,0.5)
card.Size = UDim2.fromOffset(520, 300)
card.BackgroundColor3 = Color3.fromRGB(30,30,40)
card.BackgroundTransparency = 0.35
card.BorderSizePixel = 0
card.Parent = root
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,16); c.Parent = card
	local s = Instance.new("UIStroke"); s.Thickness = 1; s.Transparency = 0.4; s.Parent = card
end

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

local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.Size = UDim2.new(1, -24, 1, -100)
body.Position = UDim2.new(0, 12, 0, 52)
body.BackgroundTransparency = 1
body.ScrollBarThickness = 6
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.CanvasSize = UDim2.new(0,0,0,0)
body.Parent = card

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 8)
layout.Parent = body

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.BackgroundTransparency = 1
footer.Size = UDim2.new(1, -24, 0, 40)
footer.Position = UDim2.new(0, 12, 1, -48)
footer.Parent = card

local buttons = Instance.new("Frame")
buttons.BackgroundTransparency = 1
buttons.Size = UDim2.new(1,0,1,0)
buttons.Parent = footer
local bl = Instance.new("UIListLayout")
bl.FillDirection = Enum.FillDirection.Horizontal
bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
bl.Padding = UDim.new(0,8)
bl.Parent = buttons

local function newBtn(text: string)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(140, 36)
	b.BackgroundColor3 = Color3.fromRGB(255,255,255)
	b.TextColor3 = Color3.fromRGB(30,30,30)
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.Text = text
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = b
	return b
end

local skipBtn = newBtn("Saltar");    skipBtn.Parent = buttons
local nextBtn = newBtn("Siguiente"); nextBtn.Parent = buttons

local idx = 1

local function makeItem(text: string)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 0.2
	t.TextWrapped = true
	t.Size = UDim2.new(1, -6, 0, 28)
	t.Font = Enum.Font.Gotham
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(235,235,235)
	t.Text = "• " .. text
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = t
	return t
end

local function clearBody()
	for _, ch in ipairs(body:GetChildren()) do
		if ch:IsA("GuiObject") and ch ~= layout then ch:Destroy() end
	end
end

local function buildUI()
	local step = STEPS[idx]; if not step then return end
	title.Text = step.title
	clearBody()
	for _, line in ipairs(string.split(step.body, ". ")) do
		if line ~= "" then
			local item = makeItem(line .. ".")
			item.Parent = body -- <<< NUNCA Body:AddItem
		end
	end
	card.BackgroundTransparency = 0.5
	TweenService:Create(card, TweenInfo.new(0.18), {BackgroundTransparency = 0.35}):Play()
	nextBtn.Text = (idx >= #STEPS) and "Entendido" or "Siguiente"
end

nextBtn.MouseButton1Click:Connect(function()
	if idx < #STEPS then idx += 1; buildUI() else gui.Enabled = false end
end)
skipBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

buildUI()