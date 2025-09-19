--!strict
-- Mantén los labels sin prefijo "Lv." (el nivel va en el HUD)
local Workspace = game:GetService("Workspace")

local function stripLvPrefix(s: string): string
	return (s:gsub("^%s*[Ll][Vv]%s*%.?%s*%d+%s*", ""))
end

local function clean(obj: Instance)
	if obj:IsA("TextLabel") or obj:IsA("TextButton") then
		obj.Text = stripLvPrefix(obj.Text)
		obj:GetPropertyChangedSignal("Text"):Connect(function()
			obj.Text = stripLvPrefix(obj.Text)
		end)
	end
end

local function watch(container: Instance)
	for _, d in ipairs(container:GetDescendants()) do clean(d) end
	container.DescendantAdded:Connect(clean)
end

watch(Workspace)