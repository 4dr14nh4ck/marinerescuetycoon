-- ServerScriptService/Debug/StatsAudit.server.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function safeRequire(mod)
	local ok, result = pcall(require, mod)
	if not ok then
		warn("[StatsAudit] No se pudo require() el módulo: ", mod:GetFullName(), result)
	end
	return ok and result or nil
end

-- 1) Descubrir nombres de stores declarados en Profiles.lua
local profilesModule
do
	local aq = ReplicatedStorage:FindFirstChild("Aquarium")
	if aq then
		profilesModule = aq:FindFirstChild("Profiles")
	end
	if profilesModule then
		local Profiles = safeRequire(profilesModule)
		if Profiles then
			print(("[StatsAudit] Profiles.lua OK  MAIN_STORE=%s  ORDERED_STORE=%s")
				:format(tostring(Profiles.MAIN_STORE), tostring(Profiles.ORDERED_STORE)))
		else
			warn("[StatsAudit] Profiles.lua existe pero no devolvió tabla válida.")
		end
	else
		warn("[StatsAudit] NO se encontró ReplicatedStorage/Aquarium/Profiles.lua")
	end
end

-- 2) Helper para localizar dónde viven los valores persistidos en runtime
local function findRuntimeStat(player, statName)
	-- Busca por descendencia cualquier IntValue/NumberValue con ese nombre fuera de leaderstats
	for _, inst in ipairs(player:GetDescendants()) do
		if (inst:IsA("IntValue") or inst:IsA("NumberValue")) 
			and inst.Name == statName 
			and (not inst:FindFirstAncestor("leaderstats")) then
			return inst
		end
	end
	-- También revisa Attributes (algunos sistemas los usan)
	if player:GetAttribute(statName) ~= nil then
		return { 
			ClassName = "Attribute", 
			Name = statName, 
			Value = player:GetAttribute(statName), 
			__isAttribute = true 
		}
	end
	return nil
end

local function pathOf(instance)
	if typeof(instance) == "Instance" then
		return instance:GetFullName()
	elseif typeof(instance) == "table" and instance.__isAttribute then
		return ("Player:%s(Attribute)"):format(instance.Name)
	end
	return "?"
end

-- 3) Log por jugador
local function auditPlayer(p)
	task.defer(function()
		print(("[StatsAudit] >>> PlayerAdded %s (%d)"):format(p.Name, p.UserId))

		local leaderstats = p:FindFirstChild("leaderstats")
		if leaderstats then
			print("[StatsAudit] leaderstats EXISTE:", leaderstats:GetFullName())
		else
			warn("[StatsAudit] leaderstats NO existe.")
		end

		for _, name in ipairs({ "Fish","Tickets","Level" }) do
			local ls = leaderstats and leaderstats:FindFirstChild(name)
			if ls then
				print(("[StatsAudit] leaderstats.%s = %s"):format(name, tostring(ls.Value)))
			else
				warn(("[StatsAudit] leaderstats.%s NO existe."):format(name))
			end

			local src = findRuntimeStat(p, name)
			if src then
				if typeof(src) == "Instance" then
					print(("[StatsAudit] Fuente runtime %s en %s = %s")
						:format(name, pathOf(src), tostring(src.Value)))
				else
					print(("[StatsAudit] Fuente runtime %s como Attribute = %s")
						:format(name, tostring(src.Value)))
				end
			else
				warn(("[StatsAudit] No se encontró fuente runtime para %s"):format(name))
			end
		end
	end)
end

Players.PlayerAdded:Connect(auditPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	auditPlayer(p)
end

Players.PlayerRemoving:Connect(function(p)
	print(("[StatsAudit] <<< PlayerRemoving %s | snapshot:"):format(p.Name))
	local leaderstats = p:FindFirstChild("leaderstats")
	if leaderstats then
		for _, name in ipairs({ "Fish","Tickets","Level" }) do
			local v = leaderstats:FindFirstChild(name)
			print((" - %s=%s"):format(name, v and v.Value or "nil"))
		end
	end
end)