-- ServerScriptService/Fish/NetService
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CFG = require(RS:WaitForChild("Fish"):WaitForChild("FishConfig"))

-- Remotes
local events = RS:FindFirstChild("FishEvents") or Instance.new("Folder")
events.Name = "FishEvents"; events.Parent = RS
local NetThrow = events:FindFirstChild("NetThrow") or Instance.new("RemoteEvent"); NetThrow.Name="NetThrow"; NetThrow.Parent=events
local CatchPrompt = events:FindFirstChild("CatchPrompt") or Instance.new("RemoteEvent"); CatchPrompt.Name="CatchPrompt"; CatchPrompt.Parent=events

-- Tool + LocalScript plantilla
local function ensureTool(plr)
	local backpack = plr:FindFirstChild("Backpack") or plr:WaitForChild("Backpack")
	if backpack:FindFirstChild(CFG.toolName) then return end
	local tool = Instance.new("Tool")
	tool.Name = CFG.toolName
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.Parent = backpack
	local template = RS:WaitForChild("Fish"):WaitForChild("NetClient") -- LocalScript
	local ls = template:Clone(); ls.Parent = tool
	print("[NetService] Net entregada a", plr.Name)
end
Players.PlayerAdded:Connect(function(plr)
	if plr:GetAttribute("HasActiveCatch")==nil then plr:SetAttribute("HasActiveCatch", false) end
	plr.CharacterAdded:Connect(function() task.wait(0.2); ensureTool(plr) end)
end)
for _,plr in ipairs(Players:GetPlayers()) do
	plr.CharacterAdded:Connect(function() task.wait(0.2); ensureTool(plr) end)
	if plr.Character then task.wait(0.2); ensureTool(plr) end
end

-- Utilidades
local lastThrow = {}
local function dist(a,b) return (a-b).Magnitude end

local function nearestFishTo(point)
	local folder = workspace:FindFirstChild(CFG.folderName)
	if not folder then return nil end
	local best, bestD
	for _,f in ipairs(folder:GetChildren()) do
		if f:IsA("Part") and f.Name:match("^Fish_") then
			local d = dist(point, f.Position)
			if not bestD or d < bestD then best, bestD = f, d end
		end
	end
	if best and bestD and bestD <= CFG.captureRadius then return best end
	return nil
end

-- Splash 100% visible con UIStroke
local function splashAt(pos)
	local anchor = Instance.new("Part")
	anchor.Anchored = true; anchor.CanCollide=false; anchor.Transparency=1
	anchor.Size = Vector3.new(0.2,0.2,0.2)
	anchor.CFrame = CFrame.new(pos.X, CFG.waterLevelY + 0.4, pos.Z)
	anchor.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(36,36)
	bb.StudsOffset = Vector3.new(0,0.2,0)
	bb.Parent = anchor

	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1,1)
	ring.BackgroundTransparency = 1
	ring.Parent = bb
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = ring

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(180,220,255)
	stroke.Transparency = 0.25
	stroke.Parent = ring

	-- animación
	local t1 = TweenService:Create(bb, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(72,72)
	})
	local t2 = TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 })
	t1:Play(); t2:Play()
	task.delay(0.45, function() anchor:Destroy() end)
end

-- Captura
NetThrow.OnServerEvent:Connect(function(plr, hitPos)
	if typeof(hitPos) ~= "Vector3" then return end
	local now = os.clock()
	if lastThrow[plr] and (now - lastThrow[plr]) < (CFG.netCooldown or 0.6) then return end
	lastThrow[plr] = now
	if plr:GetAttribute("HasActiveCatch") == true then return end

	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if dist(hrp.Position, hitPos) > (CFG.maxThrowDistance or 120) then return end

	-- Feedback visible
	splashAt(hitPos)

	local fish = nearestFishTo(hitPos)
	if not fish then
		print("[NetService] Sin pez cerca del click (aumenta captureRadius si quieres).")
		return
	end

	local rarity = "Common"
	if fish.Name:find("Uncommon") then rarity = "Uncommon" end
	if fish.Name:find("Rare") then rarity = "Rare" end

	fish:Destroy()
	plr:SetAttribute("HasActiveCatch", true)
	CatchPrompt:FireClient(plr, rarity)
	print("[NetService] Capturado:", rarity, "por", plr.Name)
end)