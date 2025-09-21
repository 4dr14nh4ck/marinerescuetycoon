local Players = game:GetService("Players")
local player = Players.LocalPlayer
local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 10)
if not leaderstats then warn("[StatsHud] No se encontró 'leaderstats' en 10s."); return end
for _, name in ipairs({ "Fish","Tickets","Level" }) do
	if not leaderstats:FindFirstChild(name) then
		warn(("[StatsHud] Falta leaderstats.%s"):format(name))
	end
end