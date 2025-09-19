--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Aquarium:WaitForChild("Config"))
local Utils = require(ReplicatedStorage.Aquarium:WaitForChild("Utils"))

Utils.GetAquariumsFolder()
print("[AquariumInit] OK. Folder:", Config.WorkspaceAquariumsFolder)