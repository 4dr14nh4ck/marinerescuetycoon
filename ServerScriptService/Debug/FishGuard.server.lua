-- ServerScriptService/Debug/FishGuard.server.lua
local Players = game:GetService("Players")
local function watch(p)
	local ls = p:WaitForChild("leaderstats", 10)
	if not ls then return end
	local fish = ls:WaitForChild("Fish", 10)
	if not fish then return end
	local last = fish.Value
	fish:GetPropertyChangedSignal("Value"):Connect(function()
		local new = fish.Value
		print(("[FishGuard] %s: Fish %d -> %d"):format(p.Name, last, new))
		last = new
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end