-- ServerScriptService/Aquarium/OwnershipService.server.lua
-- Asigna SIEMPRE un AquariumSlot al entrar (forzado si hace falta) y escribe el nombre en las etiquetas de dueño.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Utils"))

local function claimPlotFor(player: Player)
	local root = Utils.GetAquariumsFolder()
	if not root then
		warn("[Ownership] Sin raíz AquariumFarm")
		return
	end

	-- 1) Si ya tiene uno, úsalo
	local plot = Utils.GetPlotForUserId(player.UserId, root)

	-- 2) Si no, prueba libre
	if not plot then
		plot = Utils.GetFreePlot(root)
	end

	-- 3) Si aún no, fuerza el PRIMER slot disponible
	if not plot then
		local all = Utils.GetAllSlots(root)
		if #all > 0 then
			plot = all[1]
		end
	end

	if not plot then
		warn("[Ownership] No se pudo asignar AquariumSlot (no hay)")
		return
	end

	-- Marca dueño (sobrescribe si tuviera otro ID)
	plot:SetAttribute("OwnerUserId", player.UserId)

	-- Escribe nombre en TODAS las etiquetas de dueño visibles (OwnerBillboard/NameLabel…)
	local nameText = (player.DisplayName ~= "" and player.DisplayName) or player.Name
	local labels = Utils.GetOwnerLabels(plot)
	if #labels == 0 then
		local anchor = Utils.FindAnchor(plot)
		if anchor then
			table.insert(labels, Utils.EnsureBillboard(anchor, "NameBillboard", 6))
		end
	end
	for _, tl in ipairs(labels) do
		tl.Text = nameText
	end
	-- Mantén limpio (borra “ · Lv.X”, “- Lv.X”, etc. si otros scripts reescriben)
	Utils.HookLabelSanitizer(plot)

	print(("[Ownership] %s -> %s"):format(player.Name, plot:GetFullName()))

	-- Refresca visual (contador y peces)
	if _G.Visual and _G.Visual.RefreshForPlayer then
		_G.Visual.RefreshForPlayer(player)
	end
end

Players.PlayerAdded:Connect(claimPlotFor)
for _, plr in ipairs(Players:GetPlayers()) do claimPlotFor(plr) end

print("[OwnershipService] Ready")