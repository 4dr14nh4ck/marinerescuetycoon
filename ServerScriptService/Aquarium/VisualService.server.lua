-- ServerScriptService/Aquarium/VisualService.server.lua
-- Se adapta a plots horneados: limpia "Lv.X", usa rótulo existente y dibuja peces.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Config"))
local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local Profiles = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local COLORS = {
	Common   = Color3.fromRGB( 90, 220, 120),
	Uncommon = Color3.fromRGB( 80, 160, 255),
	Rare     = Color3.fromRGB(255, 110, 110),
}

local function dsKey(uid) return "u_"..tostring(uid) end
local function toInt(n) if typeof(n)~="number" then return 0 end return math.max(0, math.floor(n+0.5)) end
local function readCounts(uid)
	local ok, data = pcall(function() return Profiles:GetAsync(dsKey(uid)) end)
	data = ok and type(data)=="table" and data or {}
	return {
		Common   = toInt(data.fishCommon   or 0),
		Uncommon = toInt(data.fishUncommon or 0),
		Rare     = toInt(data.fishRare     or 0),
		Total    = toInt(data.fish         or 0),
	}
end

local function sanitizeText(s) s = tostring(s or "") return (s:gsub("%s*%-?%s*Lv%.%d+", "")) end

local function root()
	for _, n in ipairs(Config.ROOT_CANDIDATES) do
		local r = Workspace:FindFirstChild(n)
		if r then return r end
	end
	return nil
end

local function findPlotFor(userId)
	local r = root() if not r then return nil end
	for _, m in ipairs(r:GetChildren()) do
		if (m:IsA("Model") or m:IsA("Folder")) then
			if m:GetAttribute("OwnerUserId") == userId or m.Name:find(tostring(userId), 1, true) then
				return m
			end
		end
	end
	return nil
end

local function findAnchor(plot)
	-- 1) PrimaryPart / BasePart
	local b = plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
	if b then return b end
	-- 2) Candidatos nominales
	for _, name in ipairs(Config.ANCHOR_CANDIDATES) do
		local obj = plot:FindFirstChild(name, true)
		if obj and obj:IsA("BasePart") then return obj end
	end
	-- 3) Fallback: cualquier BasePart descendiente
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

local function findExistingLabel(plot)
	-- Busca TextLabel/SurfaceGui/Billboard ya existentes
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("TextLabel") then return d end
		if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			local tl = d:FindFirstChildWhichIsA("TextLabel", true)
			if tl then return tl end
		end
		for _, name in ipairs(Config.LABEL_CANDIDATES) do
			local obj = plot:FindFirstChild(name, true)
			if obj and obj:IsA("TextLabel") then return obj end
		end
	end
	return nil
end

local function ensureBillboard(anchor: BasePart, name: string, offsetY: number)
	local bb = anchor:FindFirstChild(name)
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = name
		bb.Size = UDim2.fromOffset(200, 60)
		bb.ExtentsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
		bb.AlwaysOnTop = true
		bb.Parent = anchor
		local tl = Instance.new("TextLabel")
		tl.Name = "Text"
		tl.Size = UDim2.fromScale(1,1)
		tl.BackgroundTransparency = 1
		tl.TextScaled = true
		tl.Parent = bb
	end
	return bb:FindFirstChild("Text")
end

local function setName(plot, p)
	-- Usa label existente; si no hay, crea Billboard
	local tl = findExistingLabel(plot)
	if not tl then
		local anchor = findAnchor(plot)
		if not anchor then return end
		tl = ensureBillboard(anchor, "NameBillboard", Config.BILLBOARD_OFFSET_Y)
	end
	tl.Text = p and sanitizeText(p.DisplayName ~= "" and p.DisplayName or p.Name) or "Libre"
	-- hook para limpiar reescrituras futuras
	if not tl:GetAttribute("__SanitizeHook") then
		tl:SetAttribute("__SanitizeHook", true)
		tl:GetPropertyChangedSignal("Text"):Connect(function()
			tl.Text = sanitizeText(tl.Text)
		end)
	end
end

local function ensureCounter(plot)
	local anchor = findAnchor(plot)
	if not anchor then return nil end
	return ensureBillboard(anchor, "FishCounter", Config.COUNTER_OFFSET_Y)
end

local function rebuildFishVisuals(plot, counts)
	local anchor = findAnchor(plot) if not anchor then return end
	local folder = plot:FindFirstChild("FishVisuals")
	if not folder then folder = Instance.new("Folder"); folder.Name = "FishVisuals"; folder.Parent = plot
	else folder:ClearAllChildren() end

	local total = counts.Total
	if total <= 0 then return end
	local cols = math.ceil(math.sqrt(total))
	local rows = math.ceil(total / cols)
	local spacing = 1.2
	local startX = -((cols-1) * spacing) / 2
	local startZ = -((rows-1) * spacing) / 2

	local order = {}
	for i=1,(counts.Rare or 0) do table.insert(order,"Rare") end
	for i=1,(counts.Uncommon or 0) do table.insert(order,"Uncommon") end
	for i=1,(counts.Common or 0) do table.insert(order,"Common") end

	for i = 1, total do
		local r = order[i] or "Common"
		local cx = startX + ((i-1) % cols) * spacing
		local cz = startZ + math.floor((i-1) / cols) * spacing
		local pos = anchor.Position + Vector3.new(cx, 0.8 + (0.05 * (i%3)), cz)

		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(0.6, 0.6, 0.6)
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Color = COLORS[r] or COLORS.Common
		part.Name = "Fish_"..r
		part.CFrame = CFrame.new(pos)
		part.Parent = folder
	end
end

local function refreshForPlayer(p: Player)
	local plot = findPlotFor(p.UserId)
	if not plot then return end
	setName(plot, p)
	local counts = readCounts(p.UserId)
	local tl = ensureCounter(plot)
	if tl then
		tl.Text = ("🐟 %d  |  C:%d  U:%d  R:%d"):format(counts.Total, counts.Common, counts.Uncommon, counts.Rare)
	end
	rebuildFishVisuals(plot, counts)
end

_G.Visual = _G.Visual or {}
function _G.Visual.RefreshForPlayer(p) refreshForPlayer(p) end
function _G.Visual.MarkFree(plot) setName(plot, nil) end

Players.PlayerAdded:Connect(refreshForPlayer)
for _, plr in ipairs(Players:GetPlayers()) do refreshForPlayer(plr) end

print("[VisualService] Ready")