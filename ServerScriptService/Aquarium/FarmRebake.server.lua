-- ServerScriptService/Aquarium/FarmRebake.server.lua
-- Plataforma en extremo del muelle; parcelas grandes que SOBRESALEN de la plataforma
-- con una sola UI (Billboard). Sin alargar el muelle.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Layout = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("LayoutConfig"))

-- ========== utils ==========
local function makePart(parent, size, cf, name, anchored, canCollide, material, color)
	local p = Instance.new("Part")
	p.Name = name or "Part"
	p.Size = size
	p.CFrame = cf
	p.Anchored = anchored ~= false
	p.CanCollide = canCollide ~= false
	p.Material = material or Enum.Material.WoodPlanks
	if color then p.Color = color end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeOriented(parent, size, center, right, up, along, name, material, color)
	local cf = CFrame.fromMatrix(center, right.Unit, up.Unit, along.Unit)
	return makePart(parent, size, cf, name, true, true, material, color)
end

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = parent end
	return f
end

-- ========== muelle ==========
local function getPierInfo()
	local pier = Workspace:FindFirstChild("Pier")
	if not pier then return nil, "No existe Workspace.Pier" end
	local deck = pier:FindFirstChild("Deck")
	if not deck or not deck:IsA("BasePart") then return nil, "Pier sin 'Deck' válido" end

	local length, width, along, right
	if deck.Size.Z >= deck.Size.X then
		length = deck.Size.Z; width = deck.Size.X
		along  = deck.CFrame.LookVector
		right  = deck.CFrame.RightVector
	else
		length = deck.Size.X; width = deck.Size.Z
		along  = deck.CFrame.RightVector
		right  = deck.CFrame.LookVector
	end
	local up = deck.CFrame.UpVector

	local startCenter = deck.Position - along * (length * 0.5)
	local endCenter   = deck.Position + along * (length * 0.5)
	local deckTopY    = deck.Position.Y + deck.Size.Y * 0.5

	return {
		model   = pier,
		deck    = deck,
		origin  = startCenter,
		endEdge = endCenter,
		along   = along,
		right   = right,
		up      = up,
		length  = length,
		width   = width,
		deckTopY= deckTopY,
	}, nil
end

-- ========== plataforma en extremo ==========
local function ensureEdgePlatform(pier, anchor) -- "start" | "end"
	local ext = ensureFolder(pier.model, "Extensions")
	local name = (anchor == "start") and "AquariumPlatform_Start" or "AquariumPlatform_End"
	local plat = ext:FindFirstChild(name)
	if plat and plat:IsA("BasePart") then return plat end

	local sign = (anchor == "start") and -1 or 1
	local center = (anchor == "start" and pier.origin or pier.endEdge)
	center = center + pier.along * (sign * (Layout.PLATFORM_OFFSET_FROM_EDGE + Layout.PLATFORM_LENGTH * 0.5))

	plat = makeOriented(
		ext,
		Vector3.new(Layout.PLATFORM_WIDTH, Layout.PLATFORM_THICKNESS, Layout.PLATFORM_LENGTH),
		Vector3.new(center.X, pier.deckTopY, center.Z),
		pier.right, pier.up, pier.along,
		name, Enum.Material.WoodPlanks, pier.deck.Color
	)

	-- pilotes perimetrales
	local stepsAlong = math.max(2, math.floor(Layout.PLATFORM_LENGTH / Layout.PERIMETER_PILE_SPACING))
	local stepsSide  = math.max(2, math.floor(Layout.PLATFORM_WIDTH  / Layout.PERIMETER_PILE_SPACING))
	for i = 0, stepsAlong do
		local t = i/stepsAlong
		local base = center - pier.along * (Layout.PLATFORM_LENGTH*0.5) + pier.along * (t*Layout.PLATFORM_LENGTH)
		for _, s in ipairs({-Layout.PLATFORM_WIDTH*0.5 + 0.8, Layout.PLATFORM_WIDTH*0.5 - 0.8}) do
			makePart(ext, Vector3.new(1.8, 12, 1.8), CFrame.new(base + pier.right * s + Vector3.new(0,-6,0)),
				"Pile", true, true, Enum.Material.Wood)
		end
	end
	for i = 1, stepsSide-1 do
		local t = i/stepsSide
		local base = center - pier.right * (Layout.PLATFORM_WIDTH*0.5) + pier.right * (t*Layout.PLATFORM_WIDTH)
		for _, s in ipairs({-Layout.PLATFORM_LENGTH*0.5 + 0.8, Layout.PLATFORM_LENGTH*0.5 - 0.8}) do
			makePart(ext, Vector3.new(1.8, 12, 1.8), CFrame.new(base + pier.along * s + Vector3.new(0,-6,0)),
				"Pile", true, true, Enum.Material.Wood)
		end
	end

	return plat
end

-- ========== ramal desde borde de plataforma al slot ==========
local function buildBranch(fromPos, toPos, pier, parent)
	local delta = toPos - fromPos; delta = Vector3.new(delta.X, 0, delta.Z)
	local len = delta.Magnitude; if len < 0.1 then return end
	local dir = delta.Unit

	local sizeX = (math.abs(dir:Dot(pier.right)) > 0.5) and len or Layout.BRANCH_WIDTH
	local sizeZ = (math.abs(dir:Dot(pier.along)) > 0.5) and len or Layout.BRANCH_WIDTH
	local center = fromPos + dir * (len * 0.5)

	makeOriented(parent, Vector3.new(sizeX, Layout.BRANCH_THICKNESS, sizeZ),
		Vector3.new(center.X, pier.deckTopY + Layout.BRANCH_THICKNESS*0.5, center.Z),
		pier.right, pier.up, pier.along, "Branch", Enum.Material.WoodPlanks)

	-- pilotes del ramal
	local steps = math.max(2, math.floor(len / Layout.BRANCH_PILE_SPACING) + 1)
	for i = 0, steps - 1 do
		local t = i/(steps-1)
		local p = fromPos + dir * (len * t)
		makePart(parent, Vector3.new(1.6, 10, 1.6), CFrame.new(p + Vector3.new(0,-5,0)),
			"Pile", true, true, Enum.Material.Wood)
	end
end

-- ========== Slot ==========
local function buildSlot(root, centerPos, faceTowards)
	local slot = Instance.new("Model"); slot.Name = "AquariumSlot"; slot.Parent = root
	slot:SetAttribute("OwnerUserId", nil)

	-- Anchor invisible
	local anchor = makePart(slot, Vector3.new(1,1,1), CFrame.new(centerPos), "CenterMarker", true, false, Enum.Material.SmoothPlastic)
	anchor.Transparency = 1; slot.PrimaryPart = anchor

	-- Base (para upgrades)
	local baseSize = Vector3.new(Layout.TANK_SIZE.X + Layout.SLOT_BASE_MARGIN.X*2, 1, Layout.TANK_SIZE.Z + Layout.SLOT_BASE_MARGIN.Z*2)
	makePart(slot, baseSize, CFrame.new(centerPos + Vector3.new(0,-0.5,0)), "BasePlatform", true, true, Enum.Material.WoodPlanks)

	-- ÚNICO cartel (Billboard) con todo el texto
	local bb = Instance.new("BillboardGui"); bb.Name = "OwnerBillboard"; bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(240, 84); bb.StudsOffsetWorldSpace = Vector3.new(0, Layout.LABEL_OFFSETY, 0)
	bb.Adornee = anchor; bb.Parent = anchor
	local lbl = Instance.new("TextLabel"); lbl.Name = "TextLabel"; lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1,1); lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold
	lbl.TextColor3 = Color3.fromRGB(240,240,240); lbl.Text = "Free\n🐟 Fish: 0\n🎫 Tickets: 0"
	lbl.Parent = bb

	-- Carpetas para futuras mejoras y visuales
	if not slot:FindFirstChild("Sockets") then Instance.new("Folder", slot).Name = "Sockets" end
	if not slot:FindFirstChild("DisplayFish") then Instance.new("Folder", slot).Name = "DisplayFish" end

	-- Upgrade Board + Prompt (mirando hacia la plataforma)
	local boardPos = centerPos + faceTowards.Unit * -4
	local board = makePart(slot, Vector3.new(1,6,1), CFrame.new(boardPos), "UpgradeBoard", true, true, Enum.Material.WoodPlanks)
	local att = Instance.new("Attachment"); att.Name = "PromptAttachment"; att.Parent = board
	local pp = Instance.new("ProximityPrompt"); pp.Name = "ProximityPrompt"
	pp.HoldDuration = 0.25; pp.MaxActivationDistance = 10; pp.RequiresLineOfSight = false
	pp.ObjectText = "Acuario"; pp.ActionText = "Mejorar"; pp.Parent = att

	-- Tanque de agua (grande)
	local tank = makePart(slot, Layout.TANK_SIZE, CFrame.new(centerPos + Vector3.new(0, Layout.TANK_SIZE.Y/2, 0)),
		"TankRegion", true, false, Enum.Material.SmoothPlastic, Color3.fromRGB(0,170,255))
	tank.Transparency = 0.8; tank.CanCollide = false

	return slot
end

-- ========== Rebuild ==========
local function rebuildFarm()
	local pier, err = getPierInfo()

	-- reset raíz
	local prev = Workspace:FindFirstChild("AquariumFarm")
	if prev then prev:Destroy() end
	local farm = Instance.new("Folder"); farm.Name = "AquariumFarm"; farm.Parent = Workspace

	if not pier then
		warn("[FarmRebake] " .. tostring(err) .. " — fallback simple.")
		for i = 1, Layout.SLOT_COUNT do
			local base = Vector3.new(20, Layout.SLOT_HEIGHT, 10 + (i-1)*Layout.SLOT_STEP)
			buildSlot(farm, base, Vector3.new(-1,0,0))
		end
		print(string.format("[FarmRebake] Rebuilt AquariumFarm (fallback) with %d slots", Layout.SLOT_COUNT))
		return
	end

	-- Plataforma en el extremo
	local anchor = (string.lower(Layout.PLATFORM_ANCHOR) == "start") and "start" or "end"
	local platform = ensureEdgePlatform(pier, anchor)

	-- Capacidad por longitud de plataforma
	local usableLen = math.max(0, Layout.PLATFORM_LENGTH - 2 * Layout.EDGE_MARGIN)
	local perSide   = math.max(1, math.floor(usableLen / Layout.SLOT_STEP))
	local capacity  = perSide * 2
	local target    = math.min(Layout.SLOT_COUNT, capacity)
	if target < Layout.SLOT_COUNT then
		warn(("[FarmRebake] Ajuste: %d slots solicitados, caben %d en la plataforma. Se usarán %d.")
			:format(Layout.SLOT_COUNT, capacity, target))
	end

	local along, right = pier.along, pier.right
	local start = platform.Position - along * (Layout.PLATFORM_LENGTH * 0.5 - Layout.EDGE_MARGIN)

	-- Offset para que el centro de la parcela quede FUERA de la plataforma
	local outsideOffset = (Layout.PLATFORM_WIDTH * 0.5) + Layout.OVERHANG_DISTANCE

	for i = 1, target do
		local lane = math.ceil(i/2)            -- índice a lo largo
		local side = (i % 2 == 1) and 1 or -1  -- +right/-right

		local alongPos = start + along * ((lane - 1) * Layout.SLOT_STEP)

		-- Centro de la parcela SOBRE EL AGUA, fuera de la plataforma
		local center = Vector3.new(alongPos.X, pier.deckTopY + Layout.SLOT_HEIGHT, alongPos.Z)
			+ right * (side * outsideOffset)

		-- Punto del borde de plataforma del que sale el ramal
		local edge = Vector3.new(alongPos.X, pier.deckTopY, alongPos.Z)
			+ right * (side * (Layout.PLATFORM_WIDTH * 0.5))

		buildBranch(edge, center, pier, farm)

		-- Frente del slot mirando hacia la plataforma
		local faceTowards = -right * side
		buildSlot(farm, center, faceTowards)
	end

	print(string.format("[FarmRebake] Rebuilt AquariumFarm (end-platform overhang) with %d slots (perSide=%d, step=%d, tank=%s)",
		target, perSide, Layout.SLOT_STEP, tostring(Layout.TANK_SIZE)))
end

rebuildFarm()