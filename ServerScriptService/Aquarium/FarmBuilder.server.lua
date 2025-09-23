-- ServerScriptService/Aquarium/FarmBuilder.server.lua
-- Inicializa rótulos "Libre" y elimina "Lv.X" en los nombres visibles.
local Workspace = game:GetService("Workspace")

local function root()
	return Workspace:FindFirstChild("Aquariums") or Workspace:FindFirstChild("Acuarios")
end

local function sanitizeText(s)
	if type(s) ~= "string" then return "" end
	return (s:gsub("%s*%-?%s*Lv%.%d+", ""))
end

local function ensureNameLabel(model)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("TextLabel") then
			inst.Text = "Libre"
			return
		end
	end
	-- Si no hay, lo crea VisualService cuando refresque
end

local function init()
	local r = root() if not r then return end
	for _, plot in ipairs(r:GetChildren()) do
		if plot:IsA("Model") or plot:IsA("Folder") then
			if plot.Name:find("Lv%.") then plot.Name = sanitizeText(plot.Name) end
			if not plot:GetAttribute("OwnerUserId") then
				ensureNameLabel(plot)
			end
		end
	end
end

init()
print("[FarmBuilder] Initialized nameplates (Libre)")