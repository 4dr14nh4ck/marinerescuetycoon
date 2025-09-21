-- ServerScriptService/Debug/FindFishWriters.server.lua
-- Escanea el código para localizar escrituras a leaderstats.Fish
local function scan()
	for _, inst in ipairs(game:GetDescendants()) do
		if inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
			local ok, src = pcall(function() return inst.Source end)
			if ok and type(src)=="string" then
				-- patrones comunes de escritura a Fish
				if src:find("leaderstats%.Fish%.Value%s*%+") or src:find("leaderstats%.Fish%.Value%s*=") then
					print("[FindFishWriters] Posible escritura a Fish en:", inst:GetFullName())
				end
			end
		end
	end
end
task.defer(scan)