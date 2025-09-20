--!strict
-- Stats HUD (EN) – pulls an initial snapshot, then listens for pushes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stats = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Stats"))
local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "StatsHUD"
gui.ResetOnSpawn = false
gui.Parent = pg

local panel = Instance.new("Frame")
panel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
panel.BackgroundTransparency = 0.2
panel.Size = UDim2.fromOffset(280, 90)
panel.Position = UDim2.fromOffset(12, 12)
panel.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = panel

local function makeRow(y: number, labelText: string)
	local row = Instance.new("Frame"); row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(260, 26); row.Position = UDim2.fromOffset(10, y); row.Parent = panel
	local label = Instance.new("TextLabel"); label.BackgroundTransparency = 1; label.Text = labelText
	label.TextXAlignment = Enum.TextXAlignment.Left; label.Size = UDim2.fromOffset(130, 26)
	label.Font = Enum.Font.GothamBold; label.TextScaled = true; label.TextColor3 = Color3.fromRGB(200,210,225)
	label.Parent = row
	local value = Instance.new("TextLabel"); value.Name = "Value"; value.BackgroundTransparency = 1; value.Text = "--"
	value.TextXAlignment = Enum.TextXAlignment.Right; value.Position = UDim2.fromOffset(130, 0); value.Size = UDim2.fromOffset(130, 26)
	value.Font = Enum.Font.Gotham; value.TextScaled = true; value.TextColor3 = Color3.fromRGB(255,255,255)
	value.Parent = row
	return value
end

local fishVal    = makeRow(10, "Fish")
local ticketsVal = makeRow(36, "Tickets")
local levelVal   = makeRow(62, "Level")

local function applySnapshot(snap)
	if typeof(snap) ~= "table" then return end
	if snap.Fish ~= nil then fishVal.Text = tostring(snap.Fish) end
	if snap.Tickets ~= nil then ticketsVal.Text = tostring(snap.Tickets) end
	if snap.Level ~= nil then levelVal.Text = tostring(snap.Level) end
end

-- Initial snapshot
local ok, initial = pcall(function() return Stats.StatsRequest:InvokeServer() end)
if ok and initial then
	applySnapshot(initial)
else
	warn("[StatsHUD] initial stats request failed")
end

-- Live updates
Stats.StatsPush.OnClientEvent:Connect(applySnapshot)

print("[StatsHUD] Ready (listening for StatsPush).")