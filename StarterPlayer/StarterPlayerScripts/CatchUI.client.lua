-- Catch UI (client): English + capacity error only (no "curing" messages)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

local ev = ReplicatedStorage:WaitForChild("FishEvents")
local CatchPrompt   = ev:WaitForChild("CatchPrompt")
local CatchDecision = ev:WaitForChild("CatchDecision")
local CatchFeedback = ev:WaitForChild("CatchFeedback")

local sg = Instance.new("ScreenGui")
sg.Name = "CatchUI"
sg.ResetOnSpawn = false
sg.Parent = plr:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5,0.5)
frame.Position = UDim2.new(0.5,0,0.82,0)
frame.Size = UDim2.new(0, 420, 0, 120)
frame.BackgroundTransparency = 0.15
frame.BackgroundColor3 = Color3.fromRGB(15,15,18)
frame.Visible = false
frame.Parent = sg

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1,0,0.45,0)
label.TextScaled = true
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.fromRGB(255,255,255)
label.Parent = frame

local btnCure = Instance.new("TextButton")
btnCure.Size = UDim2.new(0.5, -6, 0.45, -6)
btnCure.Position = UDim2.new(0, 0, 0.55, 6)
btnCure.Text = "Cure"
btnCure.TextScaled = true
btnCure.Font = Enum.Font.GothamBold
btnCure.BackgroundColor3 = Color3.fromRGB(46, 180, 130)
btnCure.TextColor3 = Color3.fromRGB(255,255,255)
btnCure.Parent = frame

local btnRelease = Instance.new("TextButton")
btnRelease.Size = UDim2.new(0.5, -6, 0.45, -6)
btnRelease.Position = UDim2.new(0.5, 6, 0.55, 6)
btnRelease.Text = "Release"
btnRelease.TextScaled = true
btnRelease.Font = Enum.Font.GothamBold
btnRelease.BackgroundColor3 = Color3.fromRGB(220, 90, 90)
btnRelease.TextColor3 = Color3.fromRGB(255,255,255)
btnRelease.Parent = frame

-- Small toast for errors (bottom-middle)
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5,1)
toast.Position = UDim2.new(0.5,0,1,-12)
toast.Size = UDim2.new(0, 520, 0, 36)
toast.BackgroundTransparency = 0.2
toast.BackgroundColor3 = Color3.fromRGB(0,0,0)
toast.TextColor3 = Color3.fromRGB(255,255,255)
toast.TextScaled = true
toast.Font = Enum.Font.GothamSemibold
toast.Visible = false
toast.Parent = sg

local function showToast(msg, dur)
	toast.Text = msg
	toast.Visible = true
	task.delay(dur or 2.2, function()
		if toast then toast.Visible = false end
	end)
end

local countdownTime = 10
local conns = {}
local function clearConns() for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end table.clear(conns) end
local function hidePrompt() frame.Visible = false; clearConns() end

local function showCatch(rarity)
	local t = countdownTime
	label.Text = ("You caught a fish (%s) • Decide in %ds"):format(rarity, t)
	frame.Visible = true

	conns[#conns+1] = btnCure.MouseButton1Click:Connect(function()
		CatchDecision:FireServer("CURE", rarity, nil)
		hidePrompt()
	end)
	conns[#conns+1] = btnRelease.MouseButton1Click:Connect(function()
		CatchDecision:FireServer("RELEASE", rarity, nil)
		hidePrompt()
	end)

	task.spawn(function()
		while frame.Visible and t > 0 do
			task.wait(1); t -= 1
			if frame.Visible then
				label.Text = ("You caught a fish (%s) • Decide in %ds"):format(rarity, t)
			end
		end
		if frame.Visible then
			CatchDecision:FireServer("TIMEOUT", rarity, nil)
			hidePrompt()
		end
	end)
end

-- Only error feedback (tank full)
CatchFeedback.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	if payload.type == "ERROR" and payload.code == "TANK_FULL" then
		showToast(payload.message or "Tank is full — upgrade capacity.", 3)
	end
end)

CatchPrompt.OnClientEvent:Connect(showCatch)