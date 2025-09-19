--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("FishSignals") or Instance.new("Folder")
folder.Name = "FishSignals"
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
	RequestNet = ensureEvent("RequestNet"),     -- client->server
	CaughtFish = ensureEvent("CaughtFish"),     -- server->client {value}
}

return Signals