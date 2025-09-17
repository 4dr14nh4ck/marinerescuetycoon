-- ServerScriptService/Fish/FishSpawner
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CFG = require(RS:WaitForChild("Fish"):WaitForChild("FishConfig"))

-- Carpeta mundial de peces
local fishFolder = workspace:FindFirstChild(CFG.folderName) or Instance.new("Folder")
fishFolder.Name = CFG.folderName
fishFolder.Parent = workspace

-- Leaderstats
local function ensurePlayerStats(plr)
	local ls = plr:FindFirstChild("leaderstats") or Instance.new("Folder")
	ls.Name = "leaderstats"; ls.Parent = plr
	local tickets = ls:FindFirstChild("Tickets") or Instance.new("IntValue"); tickets.Name="Tickets"; tickets.Parent=ls
	local peces   = ls:FindFirstChild("Peces")   or Instance.new("IntValue"); peces.Name="Peces";   peces.Parent=ls
	if tickets.Value==nil then tickets.Value=0 end
	if peces.Value==nil then peces.Value=0 end
	if plr:GetAttribute("HasActiveCatch")==nil then plr:SetAttribute("HasActiveCatch", false) end
end
Players.PlayerAdded:Connect(ensurePlayerStats)
for _,p in ipairs(Players:GetPlayers()) do ensurePlayerStats(p) end

-- Espera opcional al Deck
local function waitForDeck(timeout)
	local t, step = 0, 0.1
	while t < (timeout or 5) do
		local pier = workspace:FindFirstChild("Pier"); local deck = pier and pier:FindFirstChild("Deck")
		if deck then return deck end
		task.wait(step); t += step
	end
	return nil
end
local DECK = waitForDeck(CFG.waitForDeckSeconds)
if DECK then warn("[FishSpawner] Deck detectado.") else warn("[FishSpawner] SIN Deck: fallback.") end

local function getPierDeck() return workspace:FindFirstChild("Pier") and workspace.Pier:FindFirstChild("Deck") or DECK end

local function pointIsUnderDeck(deck, worldPos, padding)
	local cf, size = deck.CFrame, deck.Size
	local lp = cf:PointToObjectSpace(worldPos)
	local hx, hz = size.X/2 + (padding or 0), size.Z/2 + (padding or 0)
	return math.abs(lp.X) <= hx and math.abs(lp.Z) <= hz
end

local function chooseRarity()
	local total=0; for _,d in pairs(CFG.rarityWeights) do total+=d[1] end
	local r=math.random(1,total); local acc=0
	for name,d in pairs(CFG.rarityWeights) do acc+=d[1]; if r<=acc then return name, d[2] end end
	return "Common", Color3.fromRGB(140,190,255)
end

local function randomSpawnPosition()
	local deck = getPierDeck()
	if not deck then
		local ang = math.random()*math.pi*2
		local rad = math.random()*CFG.spawnRadius
		return Vector3.new(math.cos(ang)*rad, CFG.waterLevelY + CFG.fishHover, math.sin(ang)*rad)
	end
	local deckCF = deck.CFrame
	local forward = deckCF:VectorToWorldSpace(Vector3.new(0,0,1))
	local origin = deckCF.Position + forward * ((deck.Size.Z/2) + CFG.spawnOffsetForward)
	for _=1,18 do
		local ang = math.random()*math.pi*2
		local rad = math.random()*CFG.spawnRadius
		local pos = origin + Vector3.new(math.cos(ang)*rad, 0, math.sin(ang)*rad)
		pos = Vector3.new(pos.X, CFG.waterLevelY + CFG.fishHover, pos.Z)
		if not (CFG.avoidUnderPier and pointIsUnderDeck(deck, pos, CFG.deckPadding)) then return pos end
	end
	local fallback = origin + Vector3.new(CFG.spawnRadius, 0, 0)
	return Vector3.new(fallback.X, CFG.waterLevelY + CFG.fishHover, fallback.Z)
end

-- ====== “Burbujas” UI nativa (círculos con UIStroke) ======
local function addBubbleBillboard(parent, worldPos)
	local anchor = Instance.new("Part")
	anchor.Name = "BubbleAnchor"
	anchor.Size = Vector3.new(0.8,0.2,0.8)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CFrame = CFrame.new(worldPos.X, CFG.waterLevelY + 0.9, worldPos.Z)
	anchor.Parent = parent

	local bb = Instance.new("BillboardGui")
	bb.Name = "BubbleBillboard"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(22,22)
	bb.StudsOffset = Vector3.new(0, 0.35, 0)
	bb.Parent = anchor

	-- punto central
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromScale(1,1)
	dot.BackgroundColor3 = Color3.fromRGB(220,240,255)
	dot.BackgroundTransparency = 0.25
	dot.Parent = bb
	local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(1,0); c1.Parent = dot

	-- anillo con UIStroke (para animar transparencia)
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromOffset(22,22)
	ring.BackgroundTransparency = 1
	ring.Parent = bb
	local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(1,0); c2.Parent = ring

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(220,240,255)
	stroke.Transparency = 0.25
	stroke.Parent = ring

	-- pulso infinito
	task.spawn(function()
		while anchor.Parent do
			ring.Size = UDim2.fromOffset(22,22)
			stroke.Transparency = 0.25
			local t1 = TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(38,38)
			})
			local t2 = TweenService:Create(stroke, TweenInfo.new(0.6), { Transparency = 1 })
			t1:Play(); t2:Play()
			t1.Completed:Wait()
			task.wait(0.2)
		end
	end)

	return anchor
end

local function createFish()
	local rarityName, color = chooseRarity()
	local fish = Instance.new("Part")
	fish.Name = "Fish_"..rarityName
	fish.Shape = Enum.PartType.Ball
	fish.Size = Vector3.new(1.8,1.8,1.8)
	fish.Material = Enum.Material.SmoothPlastic
	fish.Color = color
	fish.Transparency = CFG.debugShowFish and 0 or 1
	fish.Anchored = true
	fish.CanCollide = false
	fish.CFrame = CFrame.new(randomSpawnPosition())
	fish.Parent = fishFolder
	addBubbleBillboard(fish, fish.Position)
	return fish
end

task.spawn(function()
	warn("[FishSpawner] Iniciando. maxFish=", CFG.maxFishInWorld, " interval=", CFG.spawnInterval)
	while true do
		task.wait(CFG.spawnInterval)
		local count = 0
		for _,ch in ipairs(fishFolder:GetChildren()) do
			if ch:IsA("Part") and ch.Name:match("^Fish_") then count += 1 end
		end
		if count < CFG.maxFishInWorld then
			local f = createFish()
			if f then print("[FishSpawner] Spawned:", f.Name, "@", f.Position) end
		end
	end
end)