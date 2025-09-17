--!strict
-- Señales/Remotes compartidos
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("AquariumSignals") or Instance.new("Folder")
folder.Name = "AquariumSignals"
folder.Parent = ReplicatedStorage

local function ensureEvent(name: string): RemoteEvent
	local e = folder:FindFirstChild(name) :: RemoteEvent
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = folder
	end
	return e
end

local Signals = {
	AssignedAquarium = ensureEvent("AssignedAquarium"), -- server->client {modelRef or id}
	UpgradeRequested = ensureEvent("UpgradeRequested"), -- client->server {slotName, upgradeId}
}

return Signals