--!strict
-- Cliente helper (puedes requerirlo desde StarterPlayerScripts)
local Signals = require(game.ReplicatedStorage.Fish:WaitForChild("FishSignals"))

local NetClient = {}

function NetClient.RequestNet()
	Signals.RequestNet:FireServer()
end

return NetClient