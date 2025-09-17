local UpgradeService = require(script.Parent:WaitForChild("UpgradeService"))
UpgradeService.BindAll()

workspace.ChildAdded:Connect(function(ch)
	if ch.Name == "AquariumFarm" then
		task.wait(0.1)
		UpgradeService.BindAll()
	end
end)