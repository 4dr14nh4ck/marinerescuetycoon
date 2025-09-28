-- ReplicatedStorage/Aquarium/LayoutConfig.lua
-- Plataforma en extremo del muelle; parcelas grandes que SOBRESALEN de la plataforma.

local Players = game:GetService("Players")

local M = {}

-- Nº de parcelas = min(MaxPlayers, HARD_CAP)
M.HARD_CAP_SLOTS = 24
M.SLOT_COUNT     = math.min(Players.MaxPlayers or 6, M.HARD_CAP_SLOTS)

-- Anclar plataforma en "start" o "end"
M.PLATFORM_ANCHOR            = "start"

-- Plataforma (continuación del muelle)
M.PLATFORM_OFFSET_FROM_EDGE  = 4
M.PLATFORM_LENGTH            = 260
M.PLATFORM_WIDTH             = 60
M.PLATFORM_THICKNESS         = 1.2
M.PERIMETER_PILE_SPACING     = 12

-- Parcelas sobre plataforma (a ambos lados, pero FUERA de la plataforma)
M.SLOT_STEP                  = 36     -- más separación a lo largo
M.EDGE_MARGIN                = 10
M.OVERHANG_DISTANCE          = 12     -- cuánto sobresale el centro de la parcela fuera del borde
M.BRANCH_WIDTH               = 6
M.BRANCH_THICKNESS           = 1.2
M.BRANCH_PILE_SPACING        = 12

-- Tamaño de parcela (más grande)
M.TANK_SIZE        = Vector3.new(16, 10, 16)
M.SLOT_HEIGHT      = 2
M.SLOT_BASE_MARGIN = Vector3.new(4, 0, 4)

-- UI (solo Billboard)
M.LABEL_OFFSETY    = 7

return M