-- StarterPlayer/StarterPlayerScripts/StatsHud.client.lua
-- Garantiza que el HUD nativo tenga leaderstats presentes. No escribe datos.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Espera con límite (evita yields infinitos)
local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 10)
if not leaderstats then
	warn("[StatsHud] No se encontró 'leaderstats' en 10s. El HUD nativo quedará vacío.")
	return
end

-- Verifica presencia de las 3 stats estándar; no crea nada aquí.
for _, name in ipairs({ "Fish", "Tickets", "Level" }) do
	if not leaderstats:FindFirstChild(name) then
		warn(("[StatsHud] Falta leaderstats.%s; el HUD nativo lo mostrará vacío."):format(name))
	end
end