--!strict
-- ServerScriptService/Fish/NetBootstrap.server.lua
-- Asegura que la Tool "Net" exista, esté en StarterPack y se entregue a todos los jugadores.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local TAG = "[NetBootstrap]"

-- Carpeta donde guardaremos una copia maestra de la Tool
local toolsFolder = ReplicatedStorage:FindFirstChild("Tools") :: Folder
if not toolsFolder then
	toolsFolder = Instance.new("Folder")
	toolsFolder.Name = "Tools"
	toolsFolder.Parent = ReplicatedStorage
end

local function createNet(): Tool
	local net = Instance.new("Tool")
	net.Name = "Net"
	net.RequiresHandle = false
	net.CanBeDropped = false
	net.ToolTip = "Throw the rescue net"
	-- (Opcional) atributos por si quieres versionar
	net:SetAttribute("Version", 1)
	return net
end

-- Garantiza que exista un prefab de "Net" en ReplicatedStorage/Tools
local function ensurePrefab(): Tool
	local prefab = toolsFolder:FindFirstChild("Net") :: Tool
	if not prefab or not prefab:IsA("Tool") then
		prefab = createNet()
		prefab.Parent = toolsFolder
		print(TAG, "Created prefab at ReplicatedStorage/Tools/Net")
	else
		print(TAG, "Found prefab at ReplicatedStorage/Tools/Net")
	end
	return prefab
end

-- Garantiza que StarterPack tenga la Tool (para todos los spawns)
local function ensureStarterPack(netPrefab: Tool)
	local spNet = StarterPack:FindFirstChild("Net")
	if not spNet then
		netPrefab:Clone().Parent = StarterPack
		print(TAG, "Cloned Net into StarterPack")
	else
		print(TAG, "StarterPack already has Net")
	end
end

-- Entrega la Net al jugador (Backpack y StarterGear)
local function giveToPlayer(plr: Player, netPrefab: Tool)
	local backpack = plr:FindFirstChildOfClass("Backpack")
	if not backpack then
		-- se creará tras el spawn
		return
	end

	-- Evitar duplicados
	if backpack:FindFirstChild("Net") then
		return
	end

	local net = netPrefab:Clone()
	net.Parent = backpack
	print(TAG, "Gave Net to", plr.Name)

	-- StarterGear para respawns consistentes (por si StarterPack cambia en runtime)
	local starterGear = plr:FindFirstChild("StarterGear")
	if starterGear and not starterGear:FindFirstChild("Net") then
		local sgNet = netPrefab:Clone()
		sgNet.Parent = starterGear
	end
end

-- === Arranque ===
local prefab = ensurePrefab()
ensureStarterPack(prefab)

-- Dar a jugadores actuales (si estás haciendo play solo)
for _, plr in ipairs(Players:GetPlayers()) do
	giveToPlayer(plr, prefab)
end

-- Nuevos jugadores
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		-- Backpack existe tras CharacterAdded
		giveToPlayer(plr, prefab)
	end)
end)

print(TAG, "Ready")