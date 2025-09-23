-- ServerScriptService/Aquarium/NameplateClean.server.lua
-- Quita " - Lv.X" o "Lv.X" de cualquier TextLabel/Billboard en Aquariums/Acuarios.
local Workspace = game:GetService("Workspace")

local function sanitize(s: string): string
	return (s:gsub("%s*%-?%s*Lv%.%d+", "")) -- elimina " - Lv.2", "Lv.10", etc.
end

local function cleanLabels(container)
	for _, inst in ipairs(container:GetDescendants()) do
		if inst:IsA("TextLabel") or inst:IsA("TextBox") then
			if inst.Text and inst.Text:find("Lv%.") then
				inst.Text = sanitize(inst.Text)
			end
		end
	end
end

local function run()
	local aquariums = Workspace:FindFirstChild("Aquariums") or Workspace:FindFirstChild("Acuarios")
	if aquariums then cleanLabels(aquariums) end
end

-- una vez al inicio y cada vez que FarmBuilder reconstruya/renombre
task.defer(run)
Workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") or obj:IsA("TextLabel") then
		task.defer(run)
	end
end)