-- ServerScriptService/Aquarium/FarmBuilder (STUDIO-ONLY)
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	warn("[FarmBuilder] Studio-only. Skipping in live servers.")
	return
end

local Players = game:GetService("Players")
local C = require(game.ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Config"))

-- --- Anti z-fight levels (tiny, visually invisible) ---
local MAIN_PATH_Y_OFFSET   = -0.01   -- main spur slightly down vs deck
local BRANCH_PATH_Y_OFFSET = -0.03   -- branches a tad lower than main spur
local PLOT_Y_OFFSET        =  0.02   -- plots slightly raised vs branches

-- --- Extra outward pad for plots ---
local PLOT_PAD_WIDTH = 8
local PLOT_PAD_NAME  = "PlotPad"

-- --- Sign geometry ---
local SIGN_POST_THICK  = 0.6
local SIGN_POST_HEIGHT = 4.5
local SIGN_BOARD_SIZE  = Vector3.new(6, 2.8, 0.2)
local SIGN_GAP_POST2BOARD = 0.15

-- =============================== helpers ===============================
local function findDeck()
	local pier = workspace:FindFirstChild("Pier")
	return pier and pier:FindFirstChild("Deck") or nil
end

local function part(parent, size, cf, mat, color, anchored, collide, name, transp)
	local p = Instance.new("Part")
	p.Name = name or "Part"
	p.Size = size
	p.CFrame = cf
	p.Material = mat
	p.Color = color
	p.Anchored = anchored
	p.CanCollide = collide
	p.Transparency = transp or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function pathSlab(parent, cf, size, name)
	return part(parent, size, cf, Enum.Material.WoodPlanks, Color3.fromRGB(163,118,73), true, true, name or "Path")
end

local function glassPanel(parent, size, cf, name)
	local g = Instance.new("Part")
	g.Name = name or "Glass"
	g.Size = size
	g.CFrame = cf
	g.Anchored = true
	g.CanCollide = true
	g.Material = Enum.Material.Glass
	g.Color = Color3.fromRGB(170,230,255)
	g.Transparency = 0.2
	g.Parent = parent
	return g
end

local function addPillarsUnderRect(parent, centerCF, sizeX, sizeZ, heightY, spacingAlong, inset)
	local halfX = sizeX/2 - inset
	local halfZ = sizeZ/2 - inset
	local alongIsZ = (sizeZ >= sizeX)
	local length = alongIsZ and sizeZ or sizeX
	local count = math.max(1, math.floor(length / spacingAlong))

	for i = 0, count do
		local t = (count == 0) and 0 or (i / count)
		local alongOffset = (alongIsZ and Vector3.new(0,0,(t*2-1)*halfZ) or Vector3.new((t*2-1)*halfX,0,0))

		for _,sign in ipairs({-1,1}) do
			local sideOffset = alongIsZ and Vector3.new(sign*halfX,0,0) or Vector3.new(0,0,sign*halfZ)
			local basePos = centerCF.Position + alongOffset + sideOffset

			local pile = Instance.new("Part")
			pile.Name = "Pile"
			pile.Size = Vector3.new(C.pillarSize.X, heightY, C.pillarSize.Z)
			pile.Anchored = true
			pile.CanCollide = true
			pile.Material = C.pillarMaterial
			pile.Color = C.pillarColor
			pile.CFrame = CFrame.new(basePos.X, centerCF.Position.Y - (C.pathThickness/2) - (heightY/2), basePos.Z)
			pile.Parent = parent
		end

		local beam = Instance.new("Part")
		beam.Name = "CrossBeam"
		beam.Anchored = true
		beam.CanCollide = true
		beam.Material = C.pillarMaterial
		beam.Color = C.pillarColor
		if alongIsZ then
			beam.Size = Vector3.new(sizeX - inset*2, 0.8, 1)
			beam.CFrame = CFrame.new(centerCF.Position.X, centerCF.Position.Y - (C.pathThickness/2) - heightY + 0.4, centerCF.Position.Z + alongOffset.Z)
		else
			beam.Size = Vector3.new(1, 0.8, sizeZ - inset*2)
			beam.CFrame = CFrame.new(centerCF.Position.X + alongOffset.X, centerCF.Position.Y - (C.pathThickness/2) - heightY + 0.4, centerCF.Position.Z)
		end
		beam.Parent = parent
	end
end

-- =============================== build ===============================
local function build()
	local deck = findDeck()
	assert(deck, "[FarmBuilder] Pier/Deck not found. Build the pier first.")

	if workspace:FindFirstChild("AquariumFarm") then
		workspace.AquariumFarm:Destroy()
	end
	local FARM = Instance.new("Folder"); FARM.Name = "AquariumFarm"; FARM.Parent = workspace

	local deckCF = deck.CFrame
	local forward = deckCF:VectorToWorldSpace(Vector3.new(0,0,1))
	local right   = deckCF:VectorToWorldSpace(Vector3.new(1,0,0))
	local topY    = deck.Position.Y + deck.Size.Y/2
	local deckTip = deck.Position + forward * (deck.Size.Z/2)

	-- ===== Main spur (no horizontal gap; just lower 0.01)
	local mainLen  = C.mainPierExtraLength
	local mainSize = Vector3.new(math.max(C.pathWidth, deck.Size.X), C.pathThickness, mainLen)
	local mainStart= deckTip
	local mainCtr  = mainStart + forward * (mainLen/2)
	local mainCF   = CFrame.new(mainCtr.X, topY - (C.pathThickness/2) + MAIN_PATH_Y_OFFSET, mainCtr.Z)

	pathSlab(FARM, mainCF, mainSize, "MainSpur")
	addPillarsUnderRect(FARM, mainCF, mainSize.X, mainSize.Z, C.pillarSize.Y, C.pillarSpacingAlong, C.pillarInsetFromEdge)

	local targetSlots = (C.maxSlotsOverride > 0) and C.maxSlotsOverride or ((C.useMaxPlayers and Players.MaxPlayers) or 12)

	local created, moduleIndex = 0, 0
	while created < targetSlots and (moduleIndex * C.branchEvery) < (mainLen - 6) do
		moduleIndex += 1
		local along = moduleIndex * C.branchEvery
		local branchOrigin = mainStart + forward * along

		for _,side in ipairs({-1, 1}) do
			if created >= targetSlots then break end

			-- ===== Branch (lower than main spur to avoid z-fight at T-joint)
			local bCenter   = branchOrigin + right * side * (C.branchGapFromCenter + C.pathWidth/2 + C.branchLength/2)
			local branchCF  = CFrame.new(bCenter.X, topY - (C.pathThickness/2) + BRANCH_PATH_Y_OFFSET, bCenter.Z)
			local branchSize= Vector3.new(C.branchLength, C.pathThickness, C.pathWidth)
			pathSlab(FARM, branchCF, branchSize, side == -1 and "Branch_Left" or "Branch_Right")
			addPillarsUnderRect(FARM, branchCF, branchSize.X, branchSize.Z, C.pillarSize.Y, C.pillarSpacingAlong, C.pillarInsetFromEdge)

			-- ===== Plot (raised; no z-fight with branch)
			local plotCenter = branchOrigin + right * side * (C.branchGapFromCenter + C.pathWidth/2 + C.branchLength + C.plotOffsetFromBranchEnd)
			local plotCF     = CFrame.new(plotCenter.X, topY + C.plotSize.Y/2 - 1 + PLOT_Y_OFFSET, plotCenter.Z)
			local plot = part(FARM, C.plotSize, plotCF, Enum.Material.Concrete, Color3.fromRGB(120,120,120), true, true, "Plot", 0)
			addPillarsUnderRect(FARM, plotCF, C.plotSize.X, C.plotSize.Z, C.pillarSize.Y, C.pillarSpacingAlong, C.pillarInsetFromEdge)

			-- ===== Outward pad (more space to use prompts)
			do
				local halfX = C.plotSize.X/2
				local padCenter = plotCF.Position + right * side * (halfX + PLOT_PAD_WIDTH/2)
				local padCF = CFrame.new(padCenter.X, plotCF.Position.Y, padCenter.Z)
				local pad = part(FARM, Vector3.new(PLOT_PAD_WIDTH, C.plotSize.Y, C.plotSize.Z), padCF,
					Enum.Material.Concrete, Color3.fromRGB(120,120,120), true, true, PLOT_PAD_NAME, 0)
				addPillarsUnderRect(FARM, padCF, pad.Size.X, pad.Size.Z, C.pillarSize.Y, C.pillarSpacingAlong, C.pillarInsetFromEdge)
			end

			-- ===== Tank
			local tankCF = CFrame.new(plotCenter.X, (topY - 1) + C.tankSize.Y/2, plotCenter.Z)
			local tank = Instance.new("Model"); tank.Name = "AquariumSlot"; tank.Parent = FARM
			-- NUEVO: índice estable para OwnershipService (1..N)
			tank:SetAttribute("SlotIndex", created + 1)

			local g = C.glassThickness
			local half = C.tankSize/2

			part(tank, Vector3.new(C.tankSize.X, g, C.tankSize.Z),
				tankCF * CFrame.new(0, -half.Y, 0),
				Enum.Material.SmoothPlastic, Color3.fromRGB(200,200,200), true, true, "TankFloor", 0)

			glassPanel(tank, Vector3.new(C.tankSize.X, C.tankSize.Y, g), tankCF * CFrame.new(0, 0, -half.Z + g/2), "GlassBack")
			glassPanel(tank, Vector3.new(C.tankSize.X, C.tankSize.Y, g), tankCF * CFrame.new(0, 0,  half.Z - g/2), "GlassFront")
			glassPanel(tank, Vector3.new(g, C.tankSize.Y, C.tankSize.Z), tankCF * CFrame.new(-half.X + g/2, 0, 0), "GlassLeft")
			glassPanel(tank, Vector3.new(g, C.tankSize.Y, C.tankSize.Z), tankCF * CFrame.new( half.X - g/2, 0, 0), "GlassRight")

			local center = part(tank, Vector3.new(1,1,1), tankCF, Enum.Material.SmoothPlastic, Color3.fromRGB(255,255,255), true, false, "CenterMarker", 1)
			local df = Instance.new("Folder"); df.Name = "DisplayFish"; df.Parent = tank

			local bb = Instance.new("BillboardGui"); bb.Name = "OwnerBillboard"; bb.Size = UDim2.new(0, 240, 0, 34)
			bb.StudsOffset = Vector3.new(0, C.tankSize.Y/2 + 2, 0); bb.AlwaysOnTop = true; bb.Parent = center
			local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.TextScaled = true
			lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = Color3.fromRGB(235,235,235); lbl.Text = "Free • Lv.0"; lbl.Parent = bb

			-- ===== Sign (thin post + board above, on outward pad)
			do
				local outward = side
				local postOutFromTank = (half.X + C.signPostOffset + PLOT_PAD_WIDTH/2)
				local postBaseCF = tankCF * CFrame.new(outward * postOutFromTank, -half.Y + SIGN_POST_HEIGHT/2, 0)

				part(tank, Vector3.new(SIGN_POST_THICK, SIGN_POST_HEIGHT, SIGN_POST_THICK), postBaseCF,
					Enum.Material.Wood, Color3.fromRGB(130,95,60), true, true, "UpgradePost", 0)

				local boardPos = postBaseCF.Position + Vector3.new(0, (SIGN_POST_HEIGHT/2) + (SIGN_BOARD_SIZE.Y/2) + SIGN_GAP_POST2BOARD, 0)
				local boardLook = CFrame.lookAt(boardPos, tankCF.Position)
				local board = part(tank, SIGN_BOARD_SIZE, boardLook, Enum.Material.WoodPlanks, Color3.fromRGB(150,110,70), true, true, "UpgradeBoard", 0.05)

				local function addFace(face)
					local sg = Instance.new("SurfaceGui")
					sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
					sg.PixelsPerStud = 50
					sg.Face = face
					sg.Adornee = board
					sg.AlwaysOnTop = true
					sg.Parent = board
					local txt = Instance.new("TextLabel")
					txt.Size = UDim2.new(1,0,1,0)
					txt.BackgroundTransparency = 1
					txt.TextScaled = true
					txt.Font = Enum.Font.GothamBlack
					txt.TextColor3 = Color3.fromRGB(255,255,255)
					txt.TextStrokeTransparency = 0.2
					txt.Text = "UPGRADE CAPACITY"
					txt.Parent = sg
					return txt
				end
				local txtF = addFace(Enum.NormalId.Front)
				local txtB = addFace(Enum.NormalId.Back)

				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Upgrade"
				prompt.ObjectText  = "Aquarium"
				prompt.HoldDuration = 0.1
				prompt.MaxActivationDistance = C.signPromptDistance
				prompt.Parent = board

				-- attributes
				tank:SetAttribute("OwnerUserId", 0)
				tank:SetAttribute("CapacityLevel", 0)
				tank:SetAttribute("Capacity", C.capacityStart)
				tank:SetAttribute("Occupancy", 0)

				local meta = Instance.new("Folder"); meta.Name = "Meta"; meta.Parent = tank
				local rLbl = Instance.new("ObjectValue"); rLbl.Name = "NameLabel"; rLbl.Value = lbl; rLbl.Parent = meta
				local rPrompt = Instance.new("ObjectValue"); rPrompt.Name = "UpgradePrompt"; rPrompt.Value = prompt; rPrompt.Parent = meta
				local rBF = Instance.new("ObjectValue"); rBF.Name = "BoardFrontText"; rBF.Value = txtF; rBF.Parent = meta
				local rBB = Instance.new("ObjectValue"); rBB.Name = "BoardBackText";  rBB.Value = txtB; rBB.Parent = meta
			end

			created += 1
			if created >= targetSlots then break end
		end
	end

	warn(("[FarmBuilder] Built %d AquariumSlot(s)."):format(created))
end

build()