-- ReplicatedStorage/Fish/FishSignals.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = ReplicatedStorage:FindFirstChild("FishSignals") or Instance.new("Folder")
folder.Name = "FishSignals"
folder.Parent = ReplicatedStorage

local function remote(name)
	local r = folder:FindFirstChild(name)
	if not r then r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = folder end
	return r
end

local Signals = {}
-- Client -> Server
Signals.ThrowRequest  = remote("ThrowRequest")
Signals.BeginCure     = remote("BeginCure")
Signals.CancelCure    = remote("CancelCure")
Signals.Release       = remote("Release")
Signals.ReportHit     = remote("ReportHit")   -- opcional

-- Server -> Client
Signals.ThrowResult   = remote("ThrowResult")
Signals.CatchFeedback = remote("CatchFeedback")
Signals.CatchPrompt   = remote("CatchPrompt")

-- UI de curación (server -> client)
Signals.ShowCatch     = remote("ShowCatch")   -- compat
Signals.CureTick      = remote("CureTick")
Signals.CureComplete  = remote("CureComplete")
Signals.Error         = remote("FishError")

return Signals