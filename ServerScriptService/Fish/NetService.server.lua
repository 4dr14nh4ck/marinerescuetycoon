--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishEvents = ReplicatedStorage:WaitForChild("FishEvents") :: Folder
local RequestNet = FishEvents:FindFirstChild("RequestNet") :: RemoteEvent

local function ensureNet(plr: Player)
	local function put(bp: Instance)
		if not bp:FindFirstChild("Net") then
			local tool = Instance.new("Tool")
			tool.Name = "Net"
			tool.RequiresHandle = false
			tool.Parent = bp
		end
	end
	local bp = plr:FindFirstChildOfClass("Backpack") or plr:WaitForChild("Backpack", 3)
	if bp then put(bp) end
	if plr.Character and not plr.Character:FindFirstChild("Net") and plr:FindFirstChildOfClass("Backpack") then
		put(plr.Backpack)
	end
end

Players.PlayerAdded:Connect(function(plr)
	ensureNet(plr)
	plr.CharacterAdded:Connect(function()
		task.defer(function() ensureNet(plr) end)
	end)
end)

if RequestNet then
	RequestNet.OnServerEvent:Connect(function(plr)
		ensureNet(plr)
	end)
end