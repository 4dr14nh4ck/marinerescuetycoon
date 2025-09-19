--!strict
-- ReplicatedStorage/Fish/FishSignals.lua
-- Punto único de truth para RemoteEvents relacionados con peces/red.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Carpeta contenedora (nombre esperado por CatchUI)
local eventsFolder = ReplicatedStorage:FindFirstChild("FishEvents")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "FishEvents"
	eventsFolder.Parent = ReplicatedStorage
end

local function getOrCreateEvent(name: string): RemoteEvent
	local ev = eventsFolder:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = eventsFolder
	end
	return ev :: RemoteEvent
end

-- Cliente -> Servidor: pedir lanzamiento de red
local ThrowRequest = getOrCreateEvent("ThrowRequest")
-- Servidor -> Cliente: resultado inmediato del lanzamiento (hit/miss, cooldown restante)
local ThrowResult = getOrCreateEvent("ThrowResult")
-- Servidor -> Cliente: abrir UI de captura (nombre esperado por CatchUI)
local CatchPrompt = getOrCreateEvent("CatchPrompt")
-- Cliente -> Servidor: jugador decide qué hacer con el pez (curar o liberar)
local CatchDecision = getOrCreateEvent("CatchDecision")

return {
    Folder = eventsFolder,
    ThrowRequest = ThrowRequest,
    ThrowResult = ThrowResult,
    CatchPrompt = CatchPrompt,
    CatchDecision = CatchDecision,
}