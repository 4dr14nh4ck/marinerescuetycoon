--!strict
-- Crea ReplicatedStorage.FishEvents y los RemoteEvents que usa CatchUI.
-- Si ya existen, no duplica nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("FishEvents")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "FishEvents"
	folder.Parent = ReplicatedStorage
end

local function ensureEvent(name: string): RemoteEvent
	local ev = folder:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then return ev end
	local new = Instance.new("RemoteEvent")
	new.Name = name
	new.Parent = folder
	return new
end

-- Nombres típicos (ajusta si tus scripts usan otros):
ensureEvent("StartCatch")   -- client -> server: iniciar captura (p. ej. al click con la Net)
ensureEvent("CatchResult")  -- server -> client: resultado {success, fishData}
ensureEvent("RequestNet")   -- client -> server: por si tu UI pide la herramienta