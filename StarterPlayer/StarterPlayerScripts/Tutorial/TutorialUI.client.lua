-- StarterPlayerScripts/Tutorial/TutorialUI.client.lua
-- Muestra el tutorial con márgenes (responsive). En móvil ocupa ~90% de ancho y ~70% de alto.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("TutorialEvents")
local TutorialAccept = folder:WaitForChild("TutorialAccept")

local function alreadyAccepted()
	return plr:GetAttribute("TutorialAccepted") == true
end

-- UI factory
local function buildUI()
	local sg = Instance.new("ScreenGui")
	sg.Name = "TutorialUI"
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 1000
	sg.ResetOnSpawn = false

	-- Fondo sutil
	local dim = Instance.new("Frame")
	dim.BackgroundColor3 = Color3.fromRGB(0,0,0)
	dim.BackgroundTransparency = 0.35
	dim.Size = UDim2.fromScale(1,1)
	dim.Parent = sg

	-- Card contenedor (responsive)
	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5,0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = isMobile and UDim2.fromScale(0.9, 0.7) or UDim2.fromScale(0.6, 0.55)
	card.BackgroundColor3 = Color3.fromRGB(22,22,22)
	card.BackgroundTransparency = 0.05
	card.Parent = dim
	local corner = Instance.new("UICorner", card); corner.CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", card); stroke.Thickness = 2; stroke.Color = Color3.fromRGB(255,255,255); stroke.Transparency = 0.85

	-- Padding interno
	local pad = Instance.new("UIPadding", card)
	pad.PaddingTop    = UDim.new(0, isMobile and 14 or 18)
	pad.PaddingBottom = UDim.new(0, isMobile and 14 or 18)
	pad.PaddingLeft   = UDim.new(0, isMobile and 14 or 20)
	pad.PaddingRight  = UDim.new(0, isMobile and 14 or 20)

	-- Contenido desplazable (para pantallas pequeñas)
	local body = Instance.new("ScrollingFrame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.CanvasSize = UDim2.new(0,0,0,0)
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ScrollBarThickness = 6
	body.Size = UDim2.new(1,0,1,-56) -- deja sitio para el botón
	body.Parent = card
	local list = Instance.new("UIListLayout", body)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 10)

	local function H(text)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.TextColor3 = Color3.fromRGB(255,255,255)
		t.TextTransparency = 0
		t.Font = Enum.Font.GothamBlack
		t.TextScaled = true
		t.Size = UDim2.new(1,0,0, isMobile and 40 or 44)
		t.Text = text
		return t
	end

	local function P(text)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.TextColor3 = Color3.fromRGB(230,230,230)
		t.TextWrapped = true
		t.Font = Enum.Font.Gotham
		t.TextScaled = true
		t.Size = UDim2.new(1,0,0, isMobile and 48 or 52)
		t.Text = text
		return t
	end

	body:AddItem(H("Welcome to Marine Rescue Tycoon!"))
	body:AddItem(P("1) Use your net to capture fish.\n2) Choose to cure or release.\n3) Earn tickets to upgrade your tank.\n4) Beat everyone and build the best aquarium!\n\nNote: this is a beta—more features coming soon."))

	-- Botón
	local btn = Instance.new("TextButton")
	btn.Name = "Accept"
	btn.AnchorPoint = Vector2.new(0.5,1)
	btn.Position = UDim2.new(0.5,0,1,-8)
	btn.Size = UDim2.new(1, - (isMobile and 12 or 16), 0, 42)
	btn.BackgroundColor3 = Color3.fromRGB(0, 153, 255)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Text = "I understand — play!"
	btn.Parent = card
	local btnCorner = Instance.new("UICorner", btn); btnCorner.CornerRadius = UDim.new(0, 10)

	btn.MouseButton1Click:Connect(function()
		TutorialAccept:FireServer()
		sg:Destroy()
	end)

	return sg
end

-- Mostrar solo si no está aceptado
local function maybeShow()
	if alreadyAccepted() then return end
	local ui = buildUI()
	ui.Parent = plr:WaitForChild("PlayerGui")
end

-- Reacciona si el atributo llega después
plr:GetAttributeChangedSignal("TutorialAccepted"):Connect(function()
	if alreadyAccepted() then
		local gui = plr.PlayerGui:FindFirstChild("TutorialUI")
		if gui then gui:Destroy() end
	end
end)

maybeShow()