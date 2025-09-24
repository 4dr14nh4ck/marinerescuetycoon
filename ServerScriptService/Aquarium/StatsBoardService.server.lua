-- ServerScriptService/Aquarium/StatsBoardService.server.lua
-- Sincroniza los SurfaceGui de cada slot con Fish/Tickets/Nombre del dueño (leaderstats).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Utils"))

local function updateBoardFor(player)
	local root = Utils.GetAquariumsFolder()
	if not root then return end
	local plot = Utils.GetPlotForUserId(player.UserId, root)
	if not plot then return end

	local panel = plot:FindFirstChild("StatsPanel")
	if not panel or not panel:IsA("BasePart") then return end
	local sg = panel:FindFirstChild("SurfaceGui")
	if not sg then return end

	local nameLbl   = sg:FindFirstChild("OwnerName")
	local fishLbl   = sg:FindFirstChild("FishLine")
	local ticketLbl = sg:FindFirstChild("TicketsLine")

	local ls = player:FindFirstChild("leaderstats")
	local fish = 0
	local tix  = 0
	if ls then
		if ls:FindFirstChild("Fish") then fish = ls.Fish.Value end
		if ls:FindFirstChild("Tickets") then tix = ls.Tickets.Value end
	end

	if nameLbl and nameLbl:IsA("TextLabel") then
		nameLbl.Text = (player.DisplayName ~= "" and player.DisplayName) or player.Name
	end
	if fishLbl and fishLbl:IsA("TextLabel") then
		fishLbl.Text = ("🐟 Fish: %d"):format(fish)
	end
	if ticketLbl and ticketLbl:IsA("TextLabel") then
		ticketLbl.Text = ("🎫 Tickets: %d"):format(tix)
	end
end

local function bindPlayer(p)
	-- cuando cambien los leaderstats, refresca panel
	local ls = p:FindFirstChild("leaderstats")
	if ls then
		for _, v in ipairs(ls:GetChildren()) do
			if v:IsA("IntValue") then
				v.Changed:Connect(function() updateBoardFor(p) end)
			end
		end
		ls.ChildAdded:Connect(function(v)
			if v:IsA("IntValue") then
				v.Changed:Connect(function() updateBoardFor(p) end)
			end
		end)
	end
	-- primer refresco
	updateBoardFor(p)
end

Players.PlayerAdded:Connect(bindPlayer)
for _, pl in ipairs(Players:GetPlayers()) do bindPlayer(pl) end

-- también refrescamos si Visual/Ownership reasignan plots:
_G.StatsBoard = _G.StatsBoard or {}
function _G.StatsBoard.Refresh(p) updateBoardFor(p) end

print("[StatsBoardService] Ready")