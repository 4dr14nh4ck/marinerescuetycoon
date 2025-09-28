-- ServerScriptService/Aquarium/StatsBoardService.server.lua
-- Sincroniza cartel (Billboard) por slot con Nombre + 🐟 + 🎫.
-- Mantiene soporte legacy si existe un StatsPanel/SurfaceGui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Utils"))

local function setBillboard(plot, player, fish, tickets)
	local center = plot:FindFirstChild("CenterMarker")
	if not center then return end
	local bb = center:FindFirstChild("OwnerBillboard")
	if not bb or not bb:IsA("BillboardGui") then return end
	local lbl = bb:FindFirstChild("TextLabel")
	if not lbl or not lbl:IsA("TextLabel") then return end

	local displayName = (player and ((player.DisplayName ~= "" and player.DisplayName) or player.Name)) or "Free"
	if player then
		lbl.Text = string.format("%s\n🐟 Fish: %d\n🎫 Tickets: %d", displayName, fish or 0, tickets or 0)
	else
		lbl.Text = "Free\n🐟 Fish: 0\n🎫 Tickets: 0"
	end
end

local function setLegacySurface(plot, player, fish, tickets)
	local panel = plot:FindFirstChild("StatsPanel")
	if not panel or not panel:IsA("BasePart") then return end
	local sg = panel:FindFirstChild("SurfaceGui"); if not sg then return end
	local nameLbl   = sg:FindFirstChild("OwnerName")
	local fishLbl   = sg:FindFirstChild("FishLine")
	local ticketLbl = sg:FindFirstChild("TicketsLine")
	if nameLbl and nameLbl:IsA("TextLabel") then
		nameLbl.Text = (player and ((player.DisplayName ~= "" and player.DisplayName) or player.Name)) or "Free"
	end
	if fishLbl and fishLbl:IsA("TextLabel") then fishLbl.Text = ("🐟 Fish: %d"):format(fish or 0) end
	if ticketLbl and ticketLbl:IsA("TextLabel") then ticketLbl.Text = ("🎫 Tickets: %d"):format(tickets or 0) end
end

local function updateFor(player)
	local root = Utils.GetAquariumsFolder()
	if not root then return end
	local plot = Utils.GetPlotForUserId(player.UserId, root)
	if not plot then return end

	local ls = player:FindFirstChild("leaderstats")
	local fish = 0; local tix = 0
	if ls then
		if ls:FindFirstChild("Fish") then fish = ls.Fish.Value end
		if ls:FindFirstChild("Tickets") then tix = ls.Tickets.Value end
	end
	setBillboard(plot, player, fish, tix)
	setLegacySurface(plot, player, fish, tix)
end

local function bindPlayer(p)
	local function hook(v) if v:IsA("IntValue") then v.Changed:Connect(function() updateFor(p) end) end end
	local ls = p:FindFirstChild("leaderstats")
	if ls then for _, v in ipairs(ls:GetChildren()) do hook(v) end; ls.ChildAdded:Connect(hook) end
	updateFor(p)
end

Players.PlayerAdded:Connect(bindPlayer)
for _, pl in ipairs(Players:GetPlayers()) do bindPlayer(pl) end

_G.StatsBoard = _G.StatsBoard or {}
function _G.StatsBoard.Refresh(p) updateFor(p) end

print("[StatsBoardService] Ready (Billboard mode)")