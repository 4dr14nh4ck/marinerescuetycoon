--!strict
-- Decision UI (CURE / RELEASE) + curing countdown (EN).
-- Shows no "miss" toast (world billboard is handled by NetClient).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishSignals = require(ReplicatedStorage:WaitForChild("Fish"):WaitForChild("FishSignals"))
local player = Players.LocalPlayer

local screen = Instance.new("ScreenGui")
screen.Name = "CatchUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = player:WaitForChild("PlayerGui")

-- Modal
local modal = Instance.new("Frame")
modal.Name = "Decision"
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.fromScale(0.5, 0.75)
modal.Size = UDim2.fromOffset(420, 120)
modal.BackgroundColor3 = Color3.fromRGB(15,20,30)
modal.BackgroundTransparency = 0.2
modal.Visible = false
modal.Parent = screen
local mC = Instance.new("UICorner"); mC.CornerRadius = UDim.new(0, 12); mC.Parent = modal

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.fromOffset(420, 32)
title.Position = UDim2.fromOffset(0, 8)
title.Text = "You caught a fish!"
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Parent = modal

local container = Instance.new("Frame")
container.BackgroundTransparency = 1
container.Size = UDim2.fromOffset(420, 64)
container.Position = UDim2.fromOffset(0, 48)
container.Parent = modal

local cureBtn = Instance.new("TextButton")
cureBtn.Name = "Cure"
cureBtn.Size = UDim2.fromOffset(190, 52)
cureBtn.Position = UDim2.fromOffset(16, 6)
cureBtn.Text = "CURE"
cureBtn.TextScaled = true
cureBtn.Font = Enum.Font.GothamBold
cureBtn.BackgroundColor3 = Color3.fromRGB(90,200,120)
cureBtn.TextColor3 = Color3.fromRGB(0,0,0)
cureBtn.Parent = container
local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0, 10); c1.Parent = cureBtn

local releaseBtn = Instance.new("TextButton")
releaseBtn.Name = "Release"
releaseBtn.Size = UDim2.fromOffset(190, 52)
releaseBtn.Position = UDim2.fromOffset(214, 6)
releaseBtn.Text = "RELEASE"
releaseBtn.TextScaled = true
releaseBtn.Font = Enum.Font.GothamBold
releaseBtn.BackgroundColor3 = Color3.fromRGB(240,110,110)
releaseBtn.TextColor3 = Color3.fromRGB(0,0,0)
releaseBtn.Parent = container
local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0, 10); c2.Parent = releaseBtn

-- Toast for success states only (no miss here)
local toast = Instance.new("TextLabel")
toast.BackgroundTransparency = 1
toast.Size = UDim2.fromOffset(700, 38)
toast.Position = UDim2.fromScale(0.5, 0.08)
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Text = ""
toast.TextScaled = true
toast.Font = Enum.Font.GothamBold
toast.TextColor3 = Color3.fromRGB(255,255,255)
toast.Visible = false
toast.Parent = screen

local countdown = Instance.new("TextLabel")
countdown.BackgroundTransparency = 0.25
countdown.BackgroundColor3 = Color3.fromRGB(10,15,25)
countdown.Size = UDim2.fromOffset(260, 40)
countdown.Position = UDim2.fromScale(0.5, 0.9)
countdown.AnchorPoint = Vector2.new(0.5, 0.5)
countdown.Text = ""
countdown.TextScaled = true
countdown.Font = Enum.Font.GothamMedium
countdown.TextColor3 = Color3.fromRGB(235,240,255)
countdown.Visible = false
countdown.Parent = screen
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 10); cc.Parent = countdown

local currentFish: BasePart? = nil

local function showToast(msg: string, color: Color3, dur: number)
	toast.Text = msg
	toast.TextColor3 = color
	toast.Visible = true
	task.delay(dur, function() if toast then toast.Visible = false end end)
end

-- Feedback (strings). Ignore "Miss" here to avoid duplicate text.
FishSignals.CatchFeedback.OnClientEvent:Connect(function(kind: string, message: string)
	if kind == "Cured" then
		showToast(message or "Fish cured!", Color3.fromRGB(130,210,120), 1.4)
	elseif kind == "Released" then
		showToast(message or "Fish released!", Color3.fromRGB(240,200,120), 1.2)
	end
end)

-- Open decision
FishSignals.CatchPrompt.OnClientEvent:Connect(function(data)
	currentFish = data and data.Fish
	modal.Visible = true
end)

-- Send decision
cureBtn.MouseButton1Click:Connect(function()
	if not currentFish then return end
	FishSignals.CatchDecision:FireServer({ Fish = currentFish :: BasePart, Choice = "Cure" })
	modal.Visible = false
end)

releaseBtn.MouseButton1Click:Connect(function()
	if not currentFish then return end
	FishSignals.CatchDecision:FireServer({ Fish = currentFish :: BasePart, Choice = "Release" })
	modal.Visible = false
end)

-- Cure countdown
FishSignals.CureProgress.OnClientEvent:Connect(function(p)
	if not p or typeof(p.secondsLeft) ~= "number" or typeof(p.total) ~= "number" then return end
	if p.secondsLeft > 0 then
		countdown.Visible = true
		local elapsed = p.total - p.secondsLeft
		countdown.Text = string.format("Curing... %ds / %ds", elapsed, p.total)
	else
		countdown.Visible = false
	end
end)

print("[CatchUI] Ready")