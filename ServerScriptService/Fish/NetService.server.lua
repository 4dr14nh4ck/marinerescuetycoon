-- ServerScriptService/Fish/NetService
--!strict
local Players = game:GetService("Players")

local function giveNet(plr: Player)
	local function put(toolParent: Instance)
		local tool = Instance.new("Tool")
		tool.Name = "Net"
		tool.RequiresHandle = false
		tool.Parent = toolParent
	end

	-- Backpack existente
	local backpack = plr:FindFirstChildOfClass("Backpack")
	if backpack and not backpack:FindFirstChild("Net") then
		put(backpack)
	end

	-- Si reaparece y no la tiene en el character, la volvemos a dar
	if plr.Character and not plr.Character:FindFirstChild("Net") then
		local bp = plr:FindFirstChildOfClass("Backpack")
		if bp and not bp:FindFirstChild("Net") then
			put(bp)
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	-- Entrega al entrar
	giveNet(plr)
	-- Y en cada respawn
	plr.CharacterAdded:Connect(function()
		task.defer(function() giveNet(plr) end)
	end)
end)