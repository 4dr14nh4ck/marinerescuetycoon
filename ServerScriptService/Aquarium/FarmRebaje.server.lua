-- ServerScriptService/Aquarium/FarmRebake.server.lua
-- Rehornea Workspace.AquariumFarm con N AquariumSlot (N = MaxPlayers), listos para asignar.
-- Cada slot trae: CenterMarker, OwnerBillboard ("Free"), DisplayFish, UpgradeBoard con ProximityPrompt,
-- TankRegion (para agua), y StatsPanel (SurfaceGui) orientado hacia el muelle.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("LayoutConfig"))

local function makePart(parent, size, cframe, name, anchored, canCollide, material, color)
	local p = Instance.new("Part")
	p.Name = name or "Part"
	p.Size = size
	p.CFrame = cframe
	p.Anchored = anchored ~= false
	p.CanCollide = canCollide ~= false
	p.Material = material or Enum.Material.SmoothPlastic
	if color then p.Color = color end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function buildStatsPanel(slotModel: Model, origin: Vector3, facing: Vector3)
	-- Poste + SurfaceGui
	local up = Vector3.new(0,1,0)
	local look = CFrame.lookAt(origin, origin + facing, up)
	local panel = makePart(slotModel, Layout.PANEL_SIZE, look * CFrame.new(0, Layout.PANEL_SIZE.Y/2, 0), "StatsPanel", true, true, Enum.Material.WoodPlanks)

	local sg = Instance.new("SurfaceGui")
	sg.Name = "SurfaceGui"
	sg.Face = Enum.NormalId.Front
	sg.AlwaysOnTop = true
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 25
	sg.Parent = panel

	local function makeLbl(txt, y, name)
		local l = Instance.new("TextLabel")
		l.Name = name or "Label"
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 0.3)
		l.Position = UDim2.fromScale(0, y)
		l.TextScaled = true
		l.Font = Enum.Font.GothamBold
		l.TextColor3 = Color3.fromRGB(240,240,240)
		l.Text = txt
		l.Parent = sg
		return l
	end

	makeLbl("Free", 0.00, "OwnerName")      -- se sobreescribe al asignar
	makeLbl("🐟 Fish: 0", 0.35, "FishLine")
	makeLbl("🎫 Tickets: 0", 0.70, "TicketsLine")
end

local function buildSlot(root: Instance, index: number)
	local slot = Instance.new("Model")
	slot.Name = "AquariumSlot"
	slot.Parent = root
	slot:SetAttribute("OwnerUserId", nil)

	-- Posición a lo largo del muelle y a un lado (alterno izquierda/derecha)
	local side = (index % 2 == 0) and -1 or 1 -- alterna lados
	local along = math.ceil(index/2) * Layout.SLOT_STEP
	local basePos = Layout.PIER_ORIGIN + Layout.PIER_DIR*along + Vector3.new(Layout.BRANCH_OFFSET*side, Layout.SLOT_HEIGHT, 0)

	-- Centro/anchor
	local center = makePart(slot, Vector3.new(1,1,1), CFrame.new(basePos), "CenterMarker", true, false, Enum.Material.SmoothPlastic, Color3.fromRGB(255,255,255))
	center.Transparency = 1
	slot.PrimaryPart = center

	-- Owner billboard (Free)
	local bb = Instance.new("BillboardGui")
	bb.Name = "OwnerBillboard"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(220, 50)
	bb.StudsOffsetWorldSpace = Vector3.new(0, Layout.LABEL_OFFSETY, 0)
	bb.Adornee = center
	bb.Parent = center
	local nameLbl = Instance.new("TextLabel")
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.fromScale(1,1)
	nameLbl.TextScaled = true
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextColor3 = Color3.fromRGB(240,240,240)
	nameLbl.Name = "TextLabel"
	nameLbl.Text = "Free"
	nameLbl.Parent = bb

	-- DisplayFish folder (visuales)
	ensureFolder(slot, "DisplayFish")

	-- UpgradeBoard + ProximityPrompt
	local boardPos = basePos + Vector3.new( (side>0) and -3 or 3, 0, 0) -- pegado hacia el muelle
	local board = makePart(slot, Vector3.new(1,5,1), CFrame.new(boardPos), "UpgradeBoard", true, true, Enum.Material.WoodPlanks)
	local att = Instance.new("Attachment")
	att.Name = "PromptAttachment"
	att.Parent = board
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "ProximityPrompt"
	pp.HoldDuration = 0.25
	pp.MaxActivationDistance = 10
	pp.RequiresLineOfSight = false
	pp.ObjectText = "Acuario"
	pp.ActionText = "Mejorar"
	pp.Parent = att

	-- TankRegion (para rellenar agua)
	local waterCF = CFrame.new(basePos + Vector3.new(0, Layout.TANK_SIZE.Y/2, 0))
	local tank = makePart(slot, Layout.TANK_SIZE, waterCF, "TankRegion", true, false, Enum.Material.SmoothPlastic, Color3.fromRGB(0,170,255))
	tank.Transparency = 0.8
	tank.CanCollide = false

	-- StatsPanel (en dirección opuesta al side, mirando hacia el muelle)
	local towardsPier = Vector3.new(-Layout.BRANCH_OFFSET*side, 0, 0)
	local panelBase = basePos + Vector3.new((side>0) and -5 or 5, 0, -2)
	buildStatsPanel(slot, panelBase, towardsPier)

	return slot
end

local function rebuildFarm()
	-- Borra lo anterior y recrea
	local prev = Workspace:FindFirstChild("AquariumFarm")
	if prev then prev:Destroy() end
	local farm = Instance.new("Folder")
	farm.Name = "AquariumFarm"
	farm.Parent = Workspace

	for i = 1, Layout.SLOT_COUNT do
		buildSlot(farm, i)
	end
	print(string.format("[FarmRebake] Rebuilt AquariumFarm with %d slots", Layout.SLOT_COUNT))
end

rebuildFarm()