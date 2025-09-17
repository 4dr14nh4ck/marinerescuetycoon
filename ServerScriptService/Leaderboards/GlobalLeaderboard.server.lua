-- ServerScriptService/Leaderboards/GlobalLeaderboard.lua
-- Global leaderboard: ordena por peces totales (fish) y muestra 🐟 y Lv.(capacityLevel) del perfil.

------------------ CONFIG ------------------
local CONFIG = {
	-- IMPORTANT: deben coincidir con ReplicatedStorage/Aquarium/Profiles.lua
	profileStoreName    = "INTARC_Profiles_v2",   -- MAIN_STORE en Profiles.lua
	orderedStoreName    = "INTARC_GlobalFish_v1", -- ORDERED_STORE en Profiles.lua

	boardName           = "GlobalLeaderboardBoard",
	boardSize           = Vector3.new(16, 10, 0.5),
	boardSide           = "left",
	boardSideOffset     = 3.0,
	boardAlongOffset    = -100.0,
	boardUpOffset       = 6.0,

	maxEntries          = 10,
	refreshSeconds      = 30,
}

------------------ SERVICES ------------------
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local ProfilesStore      = DataStoreService:GetDataStore(CONFIG.profileStoreName)
local GlobalOrderedStore = DataStoreService:GetOrderedDataStore(CONFIG.orderedStoreName)

------------------ UTILS ------------------
local function findDeck()
	local pier = workspace:FindFirstChild("Pier")
	return pier and pier:FindFirstChild("Deck") or nil
end

local function createOrFindBoard()
	local deck = findDeck()
	if not deck then
		warn("[GlobalLeaderboard] Pier/Deck not found; will retry later.")
		return nil
	end

	local existing = workspace:FindFirstChild(CONFIG.boardName)
	if existing and existing:IsA("Part") then return existing end

	local deckCF  = deck.CFrame
	local fwd     = deckCF:VectorToWorldSpace(Vector3.new(0,0,1))
	local right   = deckCF:VectorToWorldSpace(Vector3.new(1,0,0))
	local up      = Vector3.new(0,1,0)
	local tipPos  = deck.Position + fwd * (deck.Size.Z/2)

	local sideSign = (string.lower(CONFIG.boardSide) == "right") and 1 or -1
	local pos = tipPos
		+ fwd   * (CONFIG.boardAlongOffset)
		+ right * (sideSign * (deck.Size.X/2 + CONFIG.boardSideOffset))
		+ up    * (CONFIG.boardUpOffset)

	local faceDir = -right * sideSign
	local boardCF = CFrame.lookAt(pos, pos + faceDir)

	local board = Instance.new("Part")
	board.Name = CONFIG.boardName
	board.Size = CONFIG.boardSize
	board.Anchored = true
	board.CanCollide = false
	board.Material = Enum.Material.WoodPlanks
	board.Color = Color3.fromRGB(150,110,70)
	board.CFrame = boardCF
	board.Parent = workspace

	local sg = Instance.new("SurfaceGui")
	sg.Name = "GlobalBoardGui"
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50
	sg.Face = Enum.NormalId.Front
	sg.Adornee = board
	sg.AlwaysOnTop = true
	sg.Parent = board

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1,0,0,40)
	title.BackgroundTransparency = 0.2
	title.BackgroundColor3 = Color3.fromRGB(0,0,0)
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Text = "GLOBAL LEADERBOARD"
	title.Parent = sg

	local list = Instance.new("Frame")
	list.Name = "List"
	list.Size = UDim2.new(1, -8, 1, -48)
	list.Position = UDim2.new(0, 4, 0, 44)
	list.BackgroundTransparency = 0.2
	list.BackgroundColor3 = Color3.fromRGB(0,0,0)
	list.Parent = sg

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	return board
end

local function setRow(frame, index, textLine)
	local row = frame:FindFirstChild("Row_"..index)
	if not row then
		row = Instance.new("TextLabel")
		row.Name = "Row_"..index
		row.Size = UDim2.new(1, -8, 0, 30)
		row.BackgroundTransparency = 0.35
		row.BackgroundColor3 = Color3.fromRGB(0,0,0)
		row.TextColor3 = Color3.fromRGB(255,255,255)
		row.TextScaled = true
		row.Font = Enum.Font.GothamSemibold
		row.LayoutOrder = index
		row.Parent = frame
	end
	row.Text = textLine or ""
end

local function clearExtraRows(frame, keep)
	for _,child in ipairs(frame:GetChildren()) do
		if child:IsA("TextLabel") then
			local idx = tonumber(child.Name:match("Row_(%d+)") or "-1")
			if idx and idx > keep then child:Destroy() end
		end
	end
end

------------------ DISPLAY ------------------
local NameCache = {}   -- [userId] = displayName
local ProfCache = {}   -- [userId] = {capacityLevel=..., ...}

local function getName(userId)
	if NameCache[userId] then return NameCache[userId] end
	local ok, result = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and result then
		NameCache[userId] = result
		return result
	end
	return "[Unknown]"
end

local function getCapacityLevel(userId)
	local cached = ProfCache[userId]
	if cached and cached.capacityLevel ~= nil then
		return cached.capacityLevel
	end
	local ok, prof = pcall(function()
		return ProfilesStore:GetAsync("u_"..tostring(userId))
	end)
	local lvl = 0
	if ok and type(prof) == "table" then
		lvl = tonumber(prof.capacityLevel or 0) or 0
		ProfCache[userId] = prof
	end
	return lvl
end

local function refreshBoard()
	local board = createOrFindBoard()
	if not board then return end
	local gui = board:FindFirstChild("GlobalBoardGui")
	local list = gui and gui:FindFirstChild("List")
	if not list then return end

	local ok, pages = pcall(function()
		-- false = orden descendente (mayor primero)
		return GlobalOrderedStore:GetSortedAsync(false, CONFIG.maxEntries)
	end)

	if not ok or not pages then
		setRow(list, 1, "Be the first to rescue fish!")
		clearExtraRows(list, 1)
		return
	end

	local items = pages:GetCurrentPage()
	if #items == 0 then
		setRow(list, 1, "Be the first to rescue fish!")
		clearExtraRows(list, 1)
		return
	end

	local idx = 0
	for _,entry in ipairs(items) do
		idx += 1
		local totalFish = tonumber(entry.value) or 0
		local userId = tonumber(entry.key)
		local name = "[Unknown]"
		local lv = 0

		if userId then
			name = getName(userId)
			lv   = getCapacityLevel(userId)
		end

		setRow(list, idx, string.format("%s — 🐟 %d • Lv.%d", name, totalFish, lv))
	end
	clearExtraRows(list, idx)
end

task.defer(refreshBoard)
task.spawn(function()
	while true do
		task.wait(CONFIG.refreshSeconds)
		refreshBoard()
	end
end)