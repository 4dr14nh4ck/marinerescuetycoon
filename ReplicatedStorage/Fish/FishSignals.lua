--!strict
-- ReplicatedStorage/Fish/FishSignals.lua
-- RemoteEvents centralizados para red/peces + compat con CatchUI (CatchFeedback, CatchDecision)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eventsFolder = ReplicatedStorage:FindFirstChild("FishEvents") :: Instance
	if not eventsFolder then
		local f = Instance.new("Folder")
		f.Name = "FishEvents"
		f.Parent = ReplicatedStorage
		eventsFolder = f
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

-- Cliente -> Servidor
local ThrowRequest   = getOrCreateEvent("ThrowRequest")
local CatchDecision  = getOrCreateEvent("CatchDecision")   -- UI envía curar/liberar

-- Servidor -> Cliente
local ThrowResult    = getOrCreateEvent("ThrowResult")     -- info técnica (cooldown, hit/miss)
local CatchPrompt    = getOrCreateEvent("CatchPrompt")     -- abre UI de decisión
local CatchFeedback  = getOrCreateEvent("CatchFeedback")   -- mensaje “¡Felicidades!” / “fallaste”

return {
	Folder        = eventsFolder,
	ThrowRequest  = ThrowRequest,
	ThrowResult   = ThrowResult,
	CatchPrompt   = CatchPrompt,
	CatchDecision = CatchDecision,
	CatchFeedback = CatchFeedback,
}