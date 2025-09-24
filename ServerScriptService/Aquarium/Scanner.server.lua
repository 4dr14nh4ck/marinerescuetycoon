-- ServerScriptService/Aquarium/Scanner.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Utils"))

task.defer(function()
	local root = Utils.GetAquariumsFolder()
	if not root then warn("[Scanner] No se encontró raíz de acuarios"); return end
	print("[Scanner] Root:", root:GetFullName())
	local slots = Utils.GetAllSlots(root)
	for _, plot in ipairs(slots) do
		local anchor = Utils.FindAnchor(plot)
		local labels = Utils.GetOwnerLabels(plot)
		local prompts = Utils.FindPrompts(plot)
		print(string.format("[Scanner] Plot=%s | Anchor=%s | Labels=%d | Prompts=%d",
			plot.Name,
			anchor and anchor.Name or "nil",
			#labels, #prompts))
	end
end)