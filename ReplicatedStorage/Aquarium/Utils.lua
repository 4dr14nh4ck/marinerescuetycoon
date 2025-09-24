-- ReplicatedStorage/Aquarium/Utils.lua
-- Utilidades para AquariumFarm/AquariumSlot horneados

local Workspace = game:GetService("Workspace")

local Utils = {}

-- Raíz y slots
local ROOT_CANDIDATES = { "AquariumFarm", "Aquariums", "Acuarios", "Plots", "TycoonPlots" }
local SLOT_NAME       = "AquariumSlot"

-- Anclas/labels/prompts
local ANCHOR_CANDIDATES = { "CenterMarker", "Sign", "UpgradeBoard", "Anchor", "Base", "Floor", "PlotCenter" }
local LABEL_CANDIDATES  = { "OwnerBillboard", "NameLabel", "Label", "Title", "OwnerLabel", "BillboardGui", "SurfaceGui" }
local PROMPT_CANDIDATES = { "Upgrade", "Mejorar", "UpgradePrompt", "Mejora", "LevelUp", "ProximityPrompt" }

-- ---------- Raíz/plots ----------
function Utils.GetAquariumsFolder()
	for _, name in ipairs(ROOT_CANDIDATES) do
		local r = Workspace:FindFirstChild(name)
		if r then return r end
	end
	return nil
end

function Utils.GetAllSlots(root)
	root = root or Utils.GetAquariumsFolder()
	if not root then return {} end
	local out = {}
	for _, c in ipairs(root:GetChildren()) do
		if c.Name == SLOT_NAME and (c:IsA("Model") or c:IsA("Folder")) then
			table.insert(out, c)
		end
	end
	return out
end

function Utils.GetPlotForUserId(userId, root)
	root = root or Utils.GetAquariumsFolder()
	if not root then return nil end
	for _, plot in ipairs(Utils.GetAllSlots(root)) do
		if plot:GetAttribute("OwnerUserId") == userId or plot.Name:find(tostring(userId), 1, true) then
			return plot
		end
	end
	return nil
end

function Utils.GetFreePlot(root)
	root = root or Utils.GetAquariumsFolder()
	if not root then return nil end
	for _, plot in ipairs(Utils.GetAllSlots(root)) do
		if plot:GetAttribute("OwnerUserId") == nil then
			return plot
		end
	end
	return nil
end

-- ---------- Ancla / labels / prompts ----------
function Utils.FindAnchor(plot)
	if not plot then return nil end
	local b = plot.PrimaryPart or plot:FindFirstChild("CenterMarker", true)
	if b and b:IsA("BasePart") then return b end
	b = plot:FindFirstChildWhichIsA("BasePart")
	if b then return b end
	for _, name in ipairs(ANCHOR_CANDIDATES) do
		local obj = plot:FindFirstChild(name, true)
		if obj and obj:IsA("BasePart") then return obj end
	end
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

-- Todas las etiquetas visibles donde debe ir el nombre del dueño
function Utils.GetOwnerLabels(plot)
	local out = {}

	local bb = plot:FindFirstChild("OwnerBillboard", true)
	if bb and bb:IsA("BillboardGui") then
		local tl = bb:FindFirstChildWhichIsA("TextLabel", true)
		if tl then table.insert(out, tl) end
	end

	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("TextLabel") then
			local path = d:GetFullName():lower()
			if path:find("owner") or path:find("name") then
				table.insert(out, d)
			end
		end
	end

	local seen, res = {}, {}
	for _, tl in ipairs(out) do
		if not seen[tl] then res[#res+1]=tl; seen[tl]=true end
	end
	return res
end

-- Carpeta para peces visuales (usa DisplayFish horneado si existe)
function Utils.GetDisplayFolder(plot)
	if not plot then return nil end
	local f = plot:FindFirstChild("DisplayFish")
	if f and f:IsA("Folder") then return f end
	f = Instance.new("Folder")
	f.Name = "DisplayFish"
	f.Parent = plot
	return f
end

-- Prompts (reutiliza los horneados bajo UpgradeBoard)
function Utils.FindPrompts(plot)
	local list = {}
	if not plot then return list end

	local up = plot:FindFirstChild("UpgradeBoard", true)
	if up then
		for _, d in ipairs(up:GetDescendants()) do
			if d:IsA("ProximityPrompt") then table.insert(list, d) end
		end
	end
	for _, name in ipairs(PROMPT_CANDIDATES) do
		for _, d in ipairs(plot:GetDescendants()) do
			if d:IsA("ProximityPrompt") and (d.Name == name or (d.Parent and d.Parent.Name == name)) then
				table.insert(list, d)
			end
		end
	end
	if #list == 0 then
		for _, d in ipairs(plot:GetDescendants()) do
			if d:IsA("ProximityPrompt") then table.insert(list, d) end
		end
	end

	local seen, res = {}, {}
	for _, pp in ipairs(list) do
		if not seen[pp] then res[#res+1]=pp; seen[pp]=true end
	end
	return res
end

-- -------- limpieza "Lv.X" (incluye separadores como "·", "-", etc.) --------
function Utils.SanitizeLevelText(s)
	s = tostring(s or "")
	-- elimina cualquier separador puntuación/espacios antes de "Lv.<num>"
	return (s:gsub("%s*[%p%s]*Lv%.%d+", ""))
end

function Utils.HookLabelSanitizer(container)
	local function apply(lbl)
		if not lbl or not lbl:IsA("TextLabel") then return end
		lbl.Text = Utils.SanitizeLevelText(lbl.Text or "")
		if not lbl:GetAttribute("__SanitizeHook") then
			lbl:SetAttribute("__SanitizeHook", true)
			lbl:GetPropertyChangedSignal("Text"):Connect(function()
				lbl.Text = Utils.SanitizeLevelText(lbl.Text or "")
			end)
		end
	end
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("TextLabel") then apply(d) end
	end
	container.DescendantAdded:Connect(function(obj)
		if obj:IsA("TextLabel") then apply(obj) end
	end)
end

-- Billboard auxiliar si no existe ninguna etiqueta
function Utils.EnsureBillboard(anchor, name, offsetY)
	local bb = anchor:FindFirstChild(name)
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = name
		bb.Size = UDim2.fromOffset(200, 60)
		bb.ExtentsOffsetWorldSpace = Vector3.new(0, offsetY or 6, 0)
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

return Utils