-- ServerScriptService/Aquarium/AquariumInit.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Utils"))

local root = Utils.GetAquariumsFolder()
if not root then
	warn("[AquariumInit] No se encontró raíz de acuarios")
	return
end

print("[AquariumInit] OK. Folder: " .. root.Name)