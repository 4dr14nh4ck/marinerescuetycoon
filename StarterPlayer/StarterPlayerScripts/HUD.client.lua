--!strict
-- Lee leaderstats (lv, Tickets, Fish) y refleja cambios. No crea ni resetea nada.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = pg

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 360, 0, 26)
label.Position = UDim2.new(0, 10, 0, 10)
label.BackgroundTransparency = 0.3
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Parent = gui

local function stat(ls: Instance, names: {string})
	for _, n in ipairs(names) do
		local v = ls:FindFirstChild(n)
		if v and v:IsA("ValueBase") then return v end
	end
end

local function refresh()
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local lv      = stat(ls, {"lv"})       -- exacto (minúsculas)
	local tickets = stat(ls, {"Tickets"})
	local fish    = stat(ls, {"Fish","Peces"}) -- compat
	label.Text = string.format("LV: %s    Tickets: %s    Fish: %s",
		lv and lv.Value or "0",
		tickets and tickets.Value or "0",
		fish and fish.Value or "0"
	)
end

local function hook(ls: Instance)
	for _, v in ipairs(ls:GetChildren()) do
		if v:IsA("ValueBase") then v:GetPropertyChangedSignal("Value"):Connect(refresh) end
	end
	ls.ChildAdded:Connect(function(v)
		if v:IsA("ValueBase") then v:GetPropertyChangedSignal("Value"):Connect(refresh); refresh() end
	end)
	ls.ChildRemoved:Connect(refresh)
	refresh()
end

player.ChildAdded:Connect(function(ch) if ch.Name=="leaderstats" then hook(ch) end end)
if player:FindFirstChild("leaderstats") then hook(player.leaderstats) end