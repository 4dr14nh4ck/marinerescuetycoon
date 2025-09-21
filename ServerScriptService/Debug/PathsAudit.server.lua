-- ServerScriptService/Debug/PathsAudit.server.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local function pathOf(inst) return inst and inst:GetFullName() or "nil" end

local function audit()
	local aq = ReplicatedStorage:FindFirstChild("Aquarium")
	local profiles = aq and aq:FindFirstChild("Profiles")
	print("[PathsAudit] Profiles module ->", pathOf(profiles), "(Level = Profiles:Get(player).SlotsOwned)")

	local ts = SSS:FindFirstChild("TicketService") or (SSS:FindFirstChild("Stats") and SSS.Stats:FindFirstChild("TicketService"))
	print("[PathsAudit] TicketService module ->", pathOf(ts), "(Tickets authority)")

	print("[PathsAudit] OrderedStore (Fish) ->", "DataStoreService:GetOrderedDataStore('INTARC_GlobalFish_v1')")
end

task.defer(audit)