--!strict
-- Stats HUD (EN) bound to: leaderstats -> GlobalLeaderboard -> INTARC_Profiles_v2 (replicated profiles).
-- Prints the chosen source so you can verify quickly in Output.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PROFILE_STORE_NAME = "INTARC_Profiles_v2" -- from GlobalLeaderboard (MAIN_STORE)

local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "StatsHUD"
gui.ResetOnSpawn = false
gui.Parent = pg

local panel = Instance.new("Frame")
panel.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
panel.BackgroundTransparency = 0.2
panel.Size = UDim2.fromOffset(280, 90)
panel.Position = UDim2.fromOffset(12, 12)
panel.Parent = gui
local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = panel

local function makeRow(y: number, labelText: string)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromOffset(260, 26)
	row.Position = UDim2.fromOffset(10, y)
	row.Parent = panel

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.fromOffset(130, 26)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(200, 210, 225)
	label.Parent = row

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.BackgroundTransparency = 1
	value.Text = "--"
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Position = UDim2.fromOffset(130, 0)
	value.Size = UDim2.fromOffset(130, 26)
	value.Font = Enum.Font.Gotham
	value.TextScaled = true
	value.TextColor3 = Color3.fromRGB(255, 255, 255)
	value.Parent = row
	return value
end

local fishVal   = makeRow(10, "Fish")
local ticketsVal= makeRow(36, "Tickets")
local levelVal  = makeRow(62, "Level")

local function bindValue(v: ValueBase?, label: TextLabel): boolean
	if not v then label.Text = "--"; return false end
	local function update() label.Text = tostring((v :: any).Value) end
	update()
	(v :: any):GetPropertyChangedSignal("Value"):Connect(update)
	return true
end

-- 1) leaderstats (preferred if already mirrored there)
local function tryLeaderstats(): boolean
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then return false end
	local fish    = (ls:FindFirstChild("Fish") or ls:FindFirstChild("Fishes")) :: ValueBase?
	local tickets = (ls:FindFirstChild("Tickets") or ls:FindFirstChild("Coins")) :: ValueBase?
	local level   = (ls:FindFirstChild("Level") or ls:FindFirstChild("Lv")) :: ValueBase?
	local ok = false
	ok = bindValue(fish, fishVal) or ok
	ok = bindValue(tickets, ticketsVal) or ok
	ok = bindValue(level, levelVal) or ok
	if ok then print("[StatsHUD] source: leaderstats") end
	return ok
end

-- 2) ReplicatedStorage.GlobalLeaderboard/<UserId>
local function tryGlobalLeaderboard(): boolean
	local root = ReplicatedStorage:FindFirstChild("GlobalLeaderboard")
	if not root then return false end

	-- wait briefly for late creation
	local holder = root:FindFirstChild(tostring(plr.UserId))
	if not holder then
		local conn: RBXScriptConnection? = nil
		local found = false
		conn = root.ChildAdded:Connect(function(ch)
			if ch.Name == tostring(plr.UserId) then found = true end
		end)
		task.wait(1)
		if conn then conn:Disconnect() end
		if found then holder = root:FindFirstChild(tostring(plr.UserId)) end
	end
	if not holder then return false end

	local fish    = (holder:FindFirstChild("Fish") or holder:FindFirstChild("Fishes")) :: ValueBase?
	local tickets = (holder:FindFirstChild("Tickets") or holder:FindFirstChild("Coins")) :: ValueBase?
	local level   = (holder:FindFirstChild("Level") or holder:FindFirstChild("Lv")) :: ValueBase?
	local ok = false
	ok = bindValue(fish, fishVal) or ok
	ok = bindValue(tickets, ticketsVal) or ok
	ok = bindValue(level, levelVal) or ok
	if ok then print("[StatsHUD] source: ReplicatedStorage.GlobalLeaderboard/" .. holder.Name) end
	return ok
end

-- 3) INTARC_Profiles_v2 — common replication patterns used with ProfileService-based setups.
-- We scan ReplicatedStorage for folders named like the profile store or typical mirrors and then bind by UserId.
local function tryProfilesMirror(): boolean
	local candidates: {Instance} = {}

	-- direct folder named INTARC_Profiles_v2
	local direct = ReplicatedStorage:FindFirstChild(PROFILE_STORE_NAME)
	if direct then table.insert(candidates, direct) end

	-- common structured paths
	for _, path in ipairs({
		"Aquarium",               -- e.g., ReplicatedStorage/Aquarium/Profiles
		"Profiles",
		"ProfileStores",
	}) do
		local node = ReplicatedStorage:FindFirstChild(path)
		if node then table.insert(candidates, node) end
	end

	-- broader scan for any folder that contains a child named by our UserId
	for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
		if inst:IsA("Folder") and inst:FindFirstChild(tostring(plr.UserId)) then
			table.insert(candidates, inst)
		end
	end

	-- attempt binding inside each candidate
	for _, root in ipairs(candidates) do
		-- look for a subfolder named exactly the store, or use the root itself
		local storeRoot = root:FindFirstChild(PROFILE_STORE_NAME) or root
		local holder = storeRoot:FindFirstChild(tostring(plr.UserId))
			or storeRoot:FindFirstChild(plr.Name)

		if holder then
			local fish    = (holder:FindFirstChild("Fish") or holder:FindFirstChild("Fishes")) :: ValueBase?
			local tickets = (holder:FindFirstChild("Tickets") or holder:FindFirstChild("Coins")) :: ValueBase?
			local level   = (holder:FindFirstChild("Level") or holder:FindFirstChild("Lv")) :: ValueBase?

			local ok = false
			ok = bindValue(fish, fishVal) or ok
			ok = bindValue(tickets, ticketsVal) or ok
			ok = bindValue(level, levelVal) or ok

			if ok then
				print(string.format("[StatsHUD] source: ReplicatedStorage.%s/%s",
					root:GetFullName():gsub("^ReplicatedStorage%.", ""),
					holder.Name
				))
				return true
			end
		end
	end
	return false
end

-- Try in order, with small retries to allow late replication
task.spawn(function()
	for i=1,6 do if tryLeaderstats() then return end task.wait(0.4) end
	for i=1,6 do if tryGlobalLeaderboard() then return end task.wait(0.4) end
	for i=1,6 do if tryProfilesMirror() then return end task.wait(0.4) end
	warn("[StatsHUD] could not find stats in leaderstats / GlobalLeaderboard / INTARC_Profiles_v2 mirrors. Tell me the exact ReplicatedStorage path and I'll wire it explicitly.")
end)