--!strict
local Workspace = game:GetService("Workspace")
local Config = require(game.ReplicatedStorage.Aquarium:WaitForChild("Config"))

local Utils = {}

function Utils.GetAquariumsFolder(): Folder
	local f = Workspace:FindFirstChild(Config.WorkspaceAquariumsFolder)
	if not f then
		f = Instance.new("Folder")
		f.Name = Config.WorkspaceAquariumsFolder
		f.Parent = Workspace
	end
	return f
end

-- Devuelve el modelo de acuario propiedad del jugador si existe
function Utils.GetPlayerAquariumModel(userId: number): Model?
	local folder = Utils.GetAquariumsFolder()
	for _, mdl in ipairs(folder:GetChildren()) do
		if mdl:IsA("Model") and (mdl:GetAttribute(Config.OwnerAttribute) == userId) then
			return mdl
		end
	end
	return nil
end

return Utils