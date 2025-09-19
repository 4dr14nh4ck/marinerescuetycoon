--!strict
-- Net Tool client: world "MISSED!" only (no screen toast here).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local FishSignals = require(ReplicatedStorage:WaitForChild("Fish"):WaitForChild("FishSignals"))

local module = {}

local function spawnMissBillboard(worldPos: Vector3)
	local anchor = Instance.new("Part")
	anchor.Name = "MissAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(worldPos)
	anchor.Parent = Workspace

	local gui = Instance.new("BillboardGui")
	gui.Name = "MissBillboard"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(200, 60)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0)
	gui.Adornee = anchor
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = "MISSED!"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.Parent = gui

	task.delay(1.4, function() if anchor then anchor:Destroy() end end)
end

local function computeShotVector(): (Vector3, Vector3)
	local cam = Workspace.CurrentCamera
	local mouse = UserInputService:GetMouseLocation()
	local ray = cam:ViewportPointToRay(mouse.X, mouse.Y)
	return ray.Origin, ray.Direction * 1000
end

function module.BindTool(tool: Tool)
	if tool:GetAttribute("NetBound") then return end
	tool:SetAttribute("NetBound", true)

	local untilTime = 0.0
	tool.Activated:Connect(function()
		local now = time()
		if now < untilTime then return end
		local origin, dir = computeShotVector()
		FishSignals.ThrowRequest:FireServer({ origin = origin, direction = dir })
	end)

	FishSignals.ThrowResult.OnClientEvent:Connect(function(res)
		if not res or not res.ok then return end
		untilTime = time() + (res.cooldown or 0)
		if res.hit == false and typeof(res.pos) == "Vector3" then
			spawnMissBillboard(res.pos)
		end
	end)
end

return module