--!strict
-- FIX: el require fallaba (línea 1 en tu log). Nos aseguramos de requerir módulos reales.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Aquarium:WaitForChild("Config"))
local Utils = require(ReplicatedStorage.Aquarium:WaitForChild("Utils"))

-- Garantiza carpeta en workspace
Utils.GetAquariumsFolder()

-- (Opcional) puedes precrear slots/bandas aquí si tus modelos no existen de antemano
print("[AquariumInit] OK. Folder:", Config.WorkspaceAquariumsFolder)