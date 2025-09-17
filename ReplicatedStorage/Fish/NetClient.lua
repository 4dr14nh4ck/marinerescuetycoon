-- ReplicatedStorage/Fish/NetClient  (LocalScript plantilla)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local tool = script.Parent

local events = RS:WaitForChild("FishEvents")
local NetThrow = events:WaitForChild("NetThrow")

local mouse
tool.Equipped:Connect(function()
	mouse = player:GetMouse()
end)

tool.Activated:Connect(function()
	if not mouse or not mouse.Hit then return end
	-- Enviamos el punto de click al servidor
	NetThrow:FireServer(mouse.Hit.p)
end)