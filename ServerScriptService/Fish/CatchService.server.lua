--!strict
-- Servicio mínimo de captura (puedes reemplazar por tu lógica actual si ya la tienes)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function onTouchedFish(plr: Player, fish: BasePart)
	local ls = plr:FindFirstChild("leaderstats")
	if not ls then return end
	local count = ls:FindFirstChild("Fish")
	if not count then return end
	count.Value += 1
	fish:Destroy()
end

-- Si tu “Net” genera eventos, conéctalos aquí. De lo contrario, esto es un stub.
-- Mantengo este archivo para que el árbol coincida.