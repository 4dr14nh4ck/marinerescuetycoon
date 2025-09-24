-- ReplicatedStorage/Aquarium/LayoutConfig.lua
-- Config global para el rehorneado de AquariumFarm

local Players = game:GetService("Players")

local M = {}

-- Número de parcelas = MaxPlayers (por defecto 8 si no hay dato en Studio)
M.SLOT_COUNT = math.max(Players.MaxPlayers or 0, 8)

-- Layout respecto al muelle (asumimos el muelle crece sobre Z+)
M.PIER_ORIGIN   = Vector3.new(0, 0, 0)   -- punto base del muelle (puedes moverlo)
M.PIER_DIR      = Vector3.new(0, 0, 1)   -- eje Z+
M.BRANCH_OFFSET = 24                      -- separación lateral desde el muelle (X+/-)
M.SLOT_STEP     = 18                      -- separación a lo largo del muelle entre parcelas (en Z)

-- Geometría mínima del AquariumSlot
M.TANK_SIZE     = Vector3.new(8, 6, 8)    -- volumen de agua (studs)
M.SLOT_HEIGHT   = 2                        -- altura del suelo del slot
M.LABEL_OFFSETY = 6
M.COUNTER_OFFSETY = 8

-- Panel de stats (poste + SurfaceGui) colocado del lado del muelle
M.PANEL_SIZE    = Vector3.new(2, 5, 0.6)

return M