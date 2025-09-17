# 🐟 MarineRescueTycoon

**MarineRescueTycoon** es un proyecto de Roblox Studio gestionado con [Rojo](https://rojo.space/).  
Este repositorio contiene **todos los scripts organizados** para sincronizarse automáticamente con Roblox Studio y versionarse en GitHub.

---

## ⚙️ Requisitos

- [Roblox Studio](https://www.roblox.com/create)
- [Rojo CLI](https://rojo.space/docs/v7/getting-started/installation/)
- [Rojo Plugin](https://www.roblox.com/library/5656128676/Rojo) en Roblox Studio
- [GitHub Desktop](https://desktop.github.com/) (opcional, para manejar commits/push sin terminal)

---

## 📂 Estructura del proyecto

```text
MarineRescueTycoon/
├── ReplicatedStorage/         # Módulos compartidos
│   ├── Aquarium/
│   │   ├── Config.lua
│   │   ├── Profiles.lua
│   │   ├── Signals.lua
│   │   └── Utils.lua
│   └── Fish/
│       ├── FishConfig.lua
│       ├── FishSignals.lua
│       └── NetClient.lua
│
├── ServerScriptService/       # Scripts del servidor
│   ├── Aquarium/
│   │   ├── AquariumInit.server.lua
│   │   ├── FarmBuilder.server.lua
│   │   ├── OwnershipService.server.lua
│   │   ├── TicketService.server.lua
│   │   ├── VisualService.server.lua
│   │   └── UpgradeService.server.lua
│   ├── Fish/
│   │   ├── CatchService.server.lua
│   │   ├── FishSpawner.server.lua
│   │   ├── NetService.server.lua
│   │   └── TicketService.server.lua
│   ├── Leaderboards/
│   │   └── GlobalLeaderboard.server.lua
│   ├── Stats/
│   │   └── PlayerStatsService.server.lua
│   └── Tutorial/
│       ├── TutorialGate.server.lua
│       └── TutorialUI.server.lua
│
├── StarterPlayer/
│   └── StarterPlayerScripts/  # Scripts del cliente
│       ├── CatchUI.client.lua
│       ├── HUD.client.lua
│       └── Tutorial.client.lua
│
├── default.project.json       # Configuración de Rojo
├── .gitignore                 # Archivos ignorados por Git
└── iniciar_rojo.bat           # Script para lanzar `rojo serve`
