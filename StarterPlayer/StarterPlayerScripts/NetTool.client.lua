--!strict
-- Auto-engancha la Tool "Net" al cliente de red.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetClient = require(ReplicatedStorage:WaitForChild("Fish"):WaitForChild("NetClient"))
local localPlayer = Players.LocalPlayer

local function tryBind(tool: Tool?)
	if tool and tool:IsA("Tool") and tool.Name == "Net" then
		NetClient.BindTool(tool)
	end
end

local function scanBackpack()
	local backpack = localPlayer:WaitForChild("Backpack")
	for _, inst in ipairs(backpack:GetChildren()) do
		tryBind(inst :: Tool)
	end
	backpack.ChildAdded:Connect(function(child) tryBind(child :: Tool) end)
end

local function watchCharacter()
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	char.ChildAdded:Connect(function(child) tryBind(child :: Tool) end)
end

scanBackpack()
watchCharacter()