-- ReplicatedStorage/Aquarium/Config.lua
-- Heurística para adaptarnos a plots horneados en el mapa.
local M = {}

-- Raíces candidatas (Workspace:FindFirstChild de cualquiera de estos)
M.ROOT_CANDIDATES = { "Aquariums", "Acuarios", "Plots", "TycoonPlots" }

-- Partes/Modelos dentro de cada plot que podrían servir de ancla visual
M.ANCHOR_CANDIDATES = { "Sign", "Signpost", "UpgradeSign", "Center", "Anchor", "Base", "Floor", "PlotCenter" }

-- Etiquetas de texto ya existentes en el modelo (no creamos otra si hay una)
M.LABEL_CANDIDATES  = { "Name", "Label", "Title", "OwnerLabel", "BillboardGui", "SurfaceGui" }

-- Candidatos a prompts existentes
M.PROMPT_CANDIDATES = { "Upgrade", "Mejorar", "UpgradePrompt", "Mejora", "LevelUp" }

-- Distancias/offsets visuales
M.BILLBOARD_OFFSET_Y = 6
M.COUNTER_OFFSET_Y   = 8

return M