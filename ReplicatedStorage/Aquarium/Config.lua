-- ReplicatedStorage/Aquarium/Config (ModuleScript)
--!strict
local Config = {}

-- Carpeta en Workspace donde viven los acuarios construidos/instanciados
Config.WorkspaceAquariumsFolder = "Aquariums"

-- Cantidad máxima de slots por acuario (puedes subirlo sin romper nada)
Config.MaxSlotsPerAquarium = 12

-- Slots iniciales desbloqueados
Config.StartingSlots = 4

-- Nombre del atributo que guarda el UserId dueño de un acuario/slot
Config.OwnerAttribute = "OwnerUserId"

-- Tiempo (seg) entre ciclos de farmeo/producción en UpgradeService
Config.FarmTick = 2

return Config