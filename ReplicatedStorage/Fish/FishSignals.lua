local RS = game:GetService("ReplicatedStorage")

local folder = RS:FindFirstChild("FishEvents") or Instance.new("Folder")
folder.Name = "FishEvents"
folder.Parent = RS

local function getOrMake(name, className)
	local inst = folder:FindFirstChild(name)
	if not inst then
		inst = Instance.new(className)
		inst.Name = name
		inst.Parent = folder
	end
	return inst
end

-- Cliente → Servidor: el cliente pide lanzar la red a un punto del mundo
local NetThrow = getOrMake("NetThrow", "RemoteEvent")

-- Servidor → Cliente: mostrar prompt de decisión (curar / liberar) con rareza
local CatchPrompt = getOrMake("CatchPrompt", "RemoteEvent")

-- Cliente → Servidor: decisión tomada por el jugador
local CatchDecision = getOrMake("CatchDecision", "RemoteEvent")

return {
	Folder = folder,
	NetThrow = NetThrow,
	CatchPrompt = CatchPrompt,
	CatchDecision = CatchDecision,
}