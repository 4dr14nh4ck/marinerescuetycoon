local Signals = {}

local folder = Instance.new("Folder"); folder.Name = "AquariumSignals"; folder.Parent = game.ReplicatedStorage
local function mk(name)
	local ev = Instance.new("BindableEvent"); ev.Name = name; ev.Parent = folder; return ev
end

Signals.BuiltFarm = mk("BuiltFarm")          -- :Fire(farmFolder)
Signals.SlotOwned = mk("SlotOwned")          -- :Fire(slotModel, player)
Signals.SlotCleared = mk("SlotCleared")      -- :Fire(slotModel)
Signals.RequestRefreshVisual = mk("ReqVis")  -- :Fire(slotModel, player)

return Signals