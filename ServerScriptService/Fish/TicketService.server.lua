-- ServerScriptService/Fish/TicketService.server.lua
local SSS = game:GetService("ServerScriptService")

local function requireTS()
	local mod = SSS:FindFirstChild("TicketService")
	if not mod then
		local stats = SSS:FindFirstChild("Stats")
		if stats then mod = stats:FindFirstChild("TicketService") end
	end
	if not mod then warn("[Fish.TicketService] TicketService module NO encontrado."); return nil end
	local ok, svc = pcall(require, mod)
	if not ok then warn("[Fish.TicketService] require falló:", svc); return nil end
	return svc
end

local TS = requireTS()
if not TS then return end

_G.TicketService = _G.TicketService or { Get=TS.Get, Set=TS.Set, Add=TS.Add, Changed=TS.Changed }