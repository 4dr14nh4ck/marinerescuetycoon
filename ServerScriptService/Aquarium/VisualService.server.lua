-- ServerScriptService/Aquarium/VisualService.server.lua
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")

local PROFILE_STORE_NAME = "INTARC_Profiles_v2"
local Profiles = DataStoreService:GetDataStore(PROFILE_STORE_NAME)

local function dsKey(uid) return "u_"..tostring(uid) end
local function toInt(n) if typeof(n)~="number" then return 0 end return math.max(0, math.floor(n+0.5)) end

local function readCounts(uid)
	local ok, data = pcall(function() return Profiles:GetAsync(dsKey(uid)) end)
	data = ok and type(data)=="table" and data or {}
	return {
		Common   = toInt(data.fishCommon   or 0),
		Uncommon = toInt(data.fishUncommon or 0),
		Rare     = toInt(data.fishRare     or 0),
		Total    = toInt(data.fish or 0),
	}
end

local function sanitizeText(s)
	if type(s) ~= "string" then return "" end
	return (s:gsub("%s*%-?%s*Lv%.%d+", "")) -- quita " - Lv.X" y "Lv.X"
end

local function findPlotFor(userId)
	local root = Workspace:FindFirstChild("Aquariums") or Workspace:FindFirstChild("Acuarios")
	if not root then return nil end
	for _, m in ipairs(root:GetDescendants()) do
		if (m:IsA("Model") or m:IsA("Folder")) and (m:GetAttribute("OwnerUserId") == userId or m.Name:find(tostring(userId), 1, true)) then
			return m
		end
	end
	return nil
end

local function upsertBillboard(parent, name)
	local bb = parent:FindFirstChild(name)
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = name
		bb.Size = UDim2.fromOffset(180, 80)
		bb.ExtentsOffsetWorldSpace = Vector3.new(0, 6, 0)
		bb.AlwaysOnTop = true
		bb.Parent = parent
		local tl = Instance.new("TextLabel")
		tl.Name = "Text"
		tl.Size = UDim2.fromScale(1,1)
		tl.BackgroundTransparency = 1
		tl.TextScaled = true
		tl.Parent = bb
	end
	return bb
end

local function cleanLvText(plot)
	for _, inst in ipairs(plot:GetDescendants()) do
		if inst:IsA("TextLabel") or inst:IsA("TextBox") then
			if inst.Text and inst.Text:find("Lv%.") then
				inst.Text = sanitizeText(inst.Text)
			end
		end
	end
end

local function refreshForPlayer(p)
	local counts = readCounts(p.UserId)
	local plot = findPlotFor(p.UserId)
	if not plot then return end
	cleanLvText(plot)

	local anchor = plot:FindFirstChildWhichIsA("BasePart") or plot.PrimaryPart
	if not anchor then return end
	local bb = upsertBillboard(anchor, "FishCounter")
	local tl = bb:FindFirstChild("Text")
	if tl then
		tl.Text = ("🐟 %d  |  C:%d  U:%d  R:%d"):format(counts.Total, counts.Common, counts.Uncommon, counts.Rare)
	end
end

Players.PlayerAdded:Connect(refreshForPlayer)
for _, plr in ipairs(Players:GetPlayers()) do refreshForPlayer(plr) end

-- Exponer para que CatchService avise tras curar
_G.Visual = _G.Visual or {}
function _G.Visual.RefreshForPlayer(p) refreshForPlayer(p) end

print("[VisualService] Ready")