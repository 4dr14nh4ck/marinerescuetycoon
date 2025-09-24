-- ServerScriptService/Aquarium/VisualService.server.lua
-- Nombre en OwnerBillboard (sin “Lv.X”), contador y peces en DisplayFish.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Utils"))

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

local function ensureCounter(plot)
	local anchor = Utils.FindAnchor(plot) if not anchor then return nil end
	return Utils.EnsureBillboard(anchor, "FishCounter", 8)
end

local function rebuildFishVisuals(plot, counts)
	local folder = Utils.GetDisplayFolder(plot) if not folder then return end
	folder:ClearAllChildren()

	local anchor = Utils.FindAnchor(plot) if not anchor then return end
	local total = counts.Total
	if total <= 0 then return end

	local cols = math.ceil(math.sqrt(total))
	local spacing = 1.2
	local startX = -((cols-1) * spacing) / 2

	-- Rare -> Uncommon -> Common (simple y vistoso)
	local order = {}
	for i=1,(counts.Rare or 0) do table.insert(order,"Rare") end
	for i=1,(counts.Uncommon or 0) do table.insert(order,"Uncommon") end
	for i=1,(counts.Common or 0) do table.insert(order,"Common") end

	for i = 1, total do
		local r = order[i] or "Common"
		local cx = startX + ((i-1) % cols) * spacing
		local cz = math.floor((i-1) / cols) * spacing
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

local function refreshForPlayer(p)
	local root = Utils.GetAquariumsFolder() if not root then return end
	local plot = Utils.GetPlotForUserId(p.UserId, root)

	-- Fallback fuerte: si no tiene plot, ASIGNA el primero y escribe nombre
	if not plot then
		local all = Utils.GetAllSlots(root)
		if #all == 0 then return end
		plot = all[1]
		plot:SetAttribute("OwnerUserId", p.UserId)
		local nameText = (p.DisplayName ~= "" and p.DisplayName) or p.Name
		local labels = Utils.GetOwnerLabels(plot)
		if #labels == 0 then
			local anchor = Utils.FindAnchor(plot)
			if anchor then labels = { Utils.EnsureBillboard(anchor, "NameBillboard", 6) } end
		end
		for _, tl in ipairs(labels) do tl.Text = nameText end
	end

	-- Mantén limpio el texto del rótulo (elimina “ · Lv.X”, “- Lv.X”, etc.)
	Utils.HookLabelSanitizer(plot)

	-- Contador + peces
	local counts = readCounts(p.UserId)
	local counter = ensureCounter(plot)
	if counter then
		counter.Text = ("🐟 %d  |  C:%d  U:%d  R:%d"):format(counts.Total, counts.Common, counts.Uncommon, counts.Rare)
	end
	rebuildFishVisuals(plot, counts)
end

_G.Visual = _G.Visual or {}
function _G.Visual.RefreshForPlayer(p) refreshForPlayer(p) end

Players.PlayerAdded:Connect(refreshForPlayer)
for _, plr in ipairs(Players:GetPlayers()) do refreshForPlayer(plr) end

print("[VisualService] Ready")