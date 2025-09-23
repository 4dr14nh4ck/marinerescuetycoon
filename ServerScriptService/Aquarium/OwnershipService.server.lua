-- ServerScriptService/Aquarium/OwnershipService.server.lua
-- Auto-asigna un plot al entrar (marca OwnerUserId y etiqueta con el nombre), sin niveles.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function root()
	return Workspace:FindFirstChild("Aquariums") or Workspace:FindFirstChild("Acuarios")
end

local function findFreePlot()
	local r = root() if not r then return nil end
	for _, plot in ipairs(r:GetChildren()) do
		if (plot:IsA("Model") or plot:IsA("Folder")) and not plot:GetAttribute("OwnerUserId") then
			return plot
		end
	end
	return nil
end

local function labelOf(plot)
	for _, inst in ipairs(plot:GetDescendants()) do
		if inst:IsA("TextLabel") then return inst end
	end
	return nil
end

local function setOwner(plot, p: Player)
	plot:SetAttribute("OwnerUserId", p.UserId)
	-- etiqueta visual
	local tl = labelOf(plot)
	if not tl then
		local anchor = plot:FindFirstChildWhichIsA("BasePart") or plot.PrimaryPart
		if anchor then
			local bb = Instance.new("BillboardGui")
			bb.Name = "NameBillboard"
			bb.Size = UDim2.fromOffset(200, 60)
			bb.ExtentsOffsetWorldSpace = Vector3.new(0, 6, 0)
			bb.AlwaysOnTop = true
			bb.Parent = anchor
			tl = Instance.new("TextLabel")
			tl.Name = "Text"
			tl.Size = UDim2.fromScale(1,1)
			tl.BackgroundTransparency = 1
			tl.TextScaled = true
			tl.Parent = bb
		end
	end
	if tl then tl.Text = p.DisplayName ~= "" and p.DisplayName or p.Name end
end

local function onPlayerAdded(p: Player)
	local plot = findFreePlot()
	if plot then setOwner(plot, p) end
	-- Refrescar contadores si VisualService está cargado
	if _G.Visual and _G.Visual.RefreshForPlayer then _G.Visual.RefreshForPlayer(p) end
end

Players.PlayerAdded:Connect(onPlayerAdded)

print("[OwnershipService] Ready")