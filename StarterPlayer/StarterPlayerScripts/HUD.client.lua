-- HUD (client): ONLY per-fish recovery countdowns (bottom-right), robust binding.
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local function mkRow()
	local r = Instance.new("TextLabel")
	r.BackgroundTransparency = 0.25
	r.BackgroundColor3 = Color3.fromRGB(0,0,0)
	r.TextColor3 = Color3.fromRGB(255,255,255)
	r.Font = Enum.Font.GothamSemibold
	r.TextScaled = true
	r.Size = UDim2.new(1, 0, 0, 26)
	return r
end

local sg = Instance.new("ScreenGui")
sg.Name = "HUD"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = plr:WaitForChild("PlayerGui")

-- Bottom-right container (list of recoveries)
local recFrame = Instance.new("Frame")
recFrame.Name = "RecoveringList"
recFrame.AnchorPoint = Vector2.new(1,1)
recFrame.Position = UDim2.new(1,-16,1,-16)
recFrame.Size = UDim2.new(0, 320, 0, 10) -- height grows with rows
recFrame.BackgroundTransparency = 1
recFrame.Parent = sg

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.FillDirection = Enum.FillDirection.Vertical
UIList.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIList.Padding = UDim.new(0, 6)
UIList.Parent = recFrame

-- rows management
local rows = {}  -- marker -> label

local function rarityFromMarkerName(name)
	-- "Recovering_Rare" → "Rare"
	local idx = string.find(name or "", "_")
	if not idx then return "Common" end
	return string.sub(name, idx+1)
end

local function addMarkerRow(marker)
	if rows[marker] then return end
	local row = mkRow()
	row.Parent = recFrame
	rows[marker] = row
end

local function removeMarkerRow(marker)
	local row = rows[marker]
	if row then row:Destroy() end
	rows[marker] = nil
end

local function updateRows()
	local now = os.time()
	for marker, row in pairs(rows) do
		if not marker.Parent then
			removeMarkerRow(marker)
		else
			local rarity = marker:GetAttribute("Rarity") or rarityFromMarkerName(marker.Name) or "Common"
			local endsAt = marker:GetAttribute("EndsAt")
			local left = 0
			if typeof(endsAt) == "number" then
				left = math.max(0, endsAt - now)
			else
				-- fallback 30s from creation if EndsAt missing
				local created = tonumber(marker.Value) or now
				left = math.max(0, (created + 30) - now)
			end
			row.Text = string.format("%s recovering %ds left", rarity, left)
		end
	end
end

local function rebuildFromRecoveryFolder(rec)
	-- clear
	for mk,_ in pairs(rows) do removeMarkerRow(mk) end
	-- add rows
	for _,marker in ipairs(rec:GetChildren()) do
		if marker:IsA("ValueBase") or marker:IsA("ObjectValue") then
			addMarkerRow(marker)
		end
	end
	updateRows()
end

local function bindRecovery()
	-- Be robust: if Recovery doesn't exist yet, wait and also listen for ChildAdded
	local rec = plr:FindFirstChild("Recovery")
	if not rec then
		local connected = false
		plr.ChildAdded:Connect(function(ch)
			if ch.Name == "Recovery" and not connected then
				connected = true
				rebuildFromRecoveryFolder(ch)
				ch.ChildAdded:Connect(function(m)
					if m:IsA("ValueBase") or m:IsA("ObjectValue") then addMarkerRow(m) end
				end)
				ch.ChildRemoved:Connect(function(m) removeMarkerRow(m) end)
				-- periodic updates
				task.spawn(function()
					while ch.Parent do
						updateRows()
						task.wait(0.5)
					end
				end)
			end
		end)
		-- also try a timed wait so it works even without ChildAdded firing early
		rec = plr:WaitForChild("Recovery", 60)
	end

	if not rec then
		warn("[HUD] Recovery folder not found; countdowns won't show.")
		return
	end

	rebuildFromRecoveryFolder(rec)
	rec.ChildAdded:Connect(function(m)
		if m:IsA("ValueBase") or m:IsA("ObjectValue") then addMarkerRow(m) end
	end)
	rec.ChildRemoved:Connect(function(m) removeMarkerRow(m) end)

	-- periodic updates (0.5 s)
	task.spawn(function()
		while rec.Parent do
			updateRows()
			task.wait(0.5)
		end
	end)
end

bindRecovery()