--!strict
-- RemoteEvents centralizados para red/peces + UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eventsFolder = ReplicatedStorage:FindFirstChild("FishEvents")
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
local CatchDecision  = getOrCreateEvent("CatchDecision")    -- Cure/Release

-- Servidor -> Cliente
local ThrowResult    = getOrCreateEvent("ThrowResult")      -- hit/miss, pos, cooldown
local CatchPrompt    = getOrCreateEvent("CatchPrompt")      -- abre UI de decisión
local CatchFeedback  = getOrCreateEvent("CatchFeedback")    -- strings (compat UI)
local CureProgress   = getOrCreateEvent("CureProgress")     -- progreso de curación (uid, tLeft, tTotal)

return {
	Folder        = eventsFolder,
	ThrowRequest  = ThrowRequest,
	ThrowResult   = ThrowResult,
	CatchPrompt   = CatchPrompt,
	CatchDecision = CatchDecision,
	CatchFeedback = CatchFeedback,
	CureProgress  = CureProgress,
}