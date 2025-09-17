-- StarterPlayer/StarterPlayerScripts/Tutorial.client.lua
-- Fullscreen, must-accept tutorial overlay (English) with non-overlapping button.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local evFolder = ReplicatedStorage:WaitForChild("TutorialEvents")
local TutorialAccept = evFolder:WaitForChild("TutorialAccept")

-- Build UI
local sg = Instance.new("ScreenGui")
sg.Name = "IntroTutorial"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
sg.DisplayOrder = 10^6
sg.Parent = plr:WaitForChild("PlayerGui")

local dim = Instance.new("Frame")
dim.BackgroundColor3 = Color3.fromRGB(0,0,0)
dim.BackgroundTransparency = 0.25
dim.Size = UDim2.fromScale(1,1)
dim.Parent = sg

local card = Instance.new("Frame")
card.Name = "Card"
card.AnchorPoint = Vector2.new(0.5,0.5)
card.Position = UDim2.fromScale(0.5,0.5)
card.Size = UDim2.new(0, 720, 0, 480) -- taller so nothing overlaps
card.BackgroundColor3 = Color3.fromRGB(18,22,28)
card.BackgroundTransparency = 0.05
card.BorderSizePixel = 0
card.Parent = sg

local uic = Instance.new("UICorner", card)
uic.CornerRadius = UDim.new(0, 14)

local pad = Instance.new("UIPadding", card)
pad.PaddingTop    = UDim.new(0, 18)
pad.PaddingBottom = UDim.new(0, 18)
pad.PaddingLeft   = UDim.new(0, 22)
pad.PaddingRight  = UDim.new(0, 22)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,48)
title.BackgroundTransparency = 1
title.Text = "Marine Rescue & Aquarium Tycoon — Tutorial"
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Parent = card

-- Subtitle (beta note)
local beta = Instance.new("TextLabel")
beta.Size = UDim2.new(1,0,0,26)
beta.Position = UDim2.new(0,0,0,50)
beta.BackgroundTransparency = 1
beta.Text = "Beta • Some features are still under development."
beta.Font = Enum.Font.GothamSemibold
beta.TextScaled = true
beta.TextColor3 = Color3.fromRGB(200,220,255)
beta.TextTransparency = 0.1
beta.Parent = card

-- Steps container as a ScrollingFrame (prevents overlap with button)
local steps = Instance.new("ScrollingFrame")
steps.Name = "Steps"
steps.BackgroundTransparency = 1
steps.BorderSizePixel = 0
steps.ScrollBarThickness = 6
steps.AutomaticCanvasSize = Enum.AutomaticSize.Y
steps.CanvasSize = UDim2.new(0,0,0,0)
steps.ClipsDescendants = true
-- occupies the central area; bottom reserved for button (80px)
steps.Position = UDim2.new(0,0,0,90)
steps.Size = UDim2.new(1, 0, 1, -180) -- leaves ~90 top + ~90 bottom for button area
steps.Parent = card

local list = Instance.new("UIListLayout", steps)
list.Padding = UDim.new(0, 10)
list.HorizontalAlignment = Enum.HorizontalAlignment.Left
list.VerticalAlignment = Enum.VerticalAlignment.Top

local function addStep(num, titleTxt, descTxt)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1,0,0,64)
	row.Parent = steps

	local numBadge = Instance.new("TextLabel")
	numBadge.Size = UDim2.new(0, 44, 0, 44)
	numBadge.BackgroundColor3 = Color3.fromRGB(35,130,220)
	numBadge.TextColor3 = Color3.fromRGB(255,255,255)
	numBadge.TextScaled = true
	numBadge.Font = Enum.Font.GothamBlack
	numBadge.Text = tostring(num)
	numBadge.Parent = row
	local badgeCorner = Instance.new("UICorner", numBadge)
	badgeCorner.CornerRadius = UDim.new(1,0)

	local col = Instance.new("Frame")
	col.BackgroundTransparency = 1
	col.Size = UDim2.new(1, -56, 1, 0)
	col.Position = UDim2.new(0,56,0,0)
	col.Parent = row

	local stepTitle = Instance.new("TextLabel")
	stepTitle.Size = UDim2.new(1,0,0,28)
	stepTitle.BackgroundTransparency = 1
	stepTitle.Text = titleTxt
	stepTitle.Font = Enum.Font.GothamBold
	stepTitle.TextScaled = true
	stepTitle.TextColor3 = Color3.fromRGB(255,255,255)
	stepTitle.Parent = col

	local stepDesc = Instance.new("TextLabel")
	stepDesc.Size = UDim2.new(1,0,0,26)
	stepDesc.Position = UDim2.new(0,0,0,30)
	stepDesc.BackgroundTransparency = 1
	stepDesc.TextWrapped = true
	stepDesc.TextScaled = true
	stepDesc.Font = Enum.Font.Gotham
	stepDesc.TextColor3 = Color3.fromRGB(210,220,230)
	stepDesc.Text = descTxt
	stepDesc.Parent = col
end

addStep(1, "Use the net to catch fish",
	"Equip your Net and click where you want to throw it. Simple and straight.")
addStep(2, "Choose to cure or release",
	"Every catch prompts a decision. Cure to grow your aquarium, or release to play it fair.")
addStep(3, "Upgrade your aquarium",
	"Earn tickets and spend them to increase your tank capacity. Bigger tanks, more fish.")
addStep(4, "Beat everyone — build the best aquarium",
	"Climb the global leaderboard and make your aquarium the #1 destination.")

-- Accept button (sits below the scrolling area)
local btn = Instance.new("TextButton")
btn.AnchorPoint = Vector2.new(0.5,1)
btn.Position = UDim2.new(0.5,0,1,-16)
btn.Size = UDim2.new(0, 260, 0, 48)
btn.BackgroundColor3 = Color3.fromRGB(46,180,130)
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.TextScaled = true
btn.Font = Enum.Font.GothamBlack
btn.Text = "I understand — Play"
btn.Parent = card
local btnCorner = Instance.new("UICorner", btn); btnCorner.CornerRadius = UDim.new(0, 10)

-- Optional tip (kept hidden unless you add a menu entry to reopen tutorial)
local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5,1)
hint.Position = UDim2.new(0.5,0,1,-70)
hint.Size = UDim2.new(0, 420, 0, 22)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.fromRGB(200,200,205)
hint.TextScaled = true
hint.Font = Enum.Font.Gotham
hint.Text = "Tip: You can re-open this tutorial later from the Menu."
hint.Parent = card
hint.Visible = false

-- Appear animation
card.Size = UDim2.new(0, 720, 0, 440)
TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 720, 0, 480)}):Play()

-- Prevent ESC reset while modal (optional)
pcall(function() game:GetService("StarterGui"):SetCore("ResetButtonCallback", false) end)

local accepted = false
local function closeTutorial()
	if accepted then return end
	accepted = true
	TutorialAccept:FireServer()
	TweenService:Create(dim, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
	TweenService:Create(card, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
	task.delay(0.2, function()
		if sg then sg:Destroy() end
		pcall(function() game:GetService("StarterGui"):SetCore("ResetButtonCallback", true) end)
	end)
end
btn.MouseButton1Click:Connect(closeTutorial)

-- Safety: if server already marked as accepted (e.g., quick respawn)
plr:GetAttributeChangedSignal("TutorialAccepted"):Connect(function()
	if plr:GetAttribute("TutorialAccepted") == true then
		closeTutorial()
	end
end)