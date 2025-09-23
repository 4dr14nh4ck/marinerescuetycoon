-- ServerScriptService/Aquarium/Scanner.server.lua
-- Imprime por consola qué encuentra en cada plot (para mapas horneados).
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Aquarium"):WaitForChild("Config"))

local function root()
	for _, n in ipairs(Config.ROOT_CANDIDATES) do
		local r = Workspace:FindFirstChild(n)
		if r then return r end
	end
	return nil
end

local function findOne(plot, kind)
	local function ok(x) return x and ((kind=="BasePart" and x:IsA("BasePart")) or (kind=="Label" and x:IsA("TextLabel")) or (kind=="Prompt" and x:IsA("ProximityPrompt"))) end

	-- direct candidates
	if kind=="BasePart" then
		local b = plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
		if ok(b) then return b end
		for _, name in ipairs(Config.ANCHOR_CANDIDATES) do
			local obj = plot:FindFirstChild(name, true)
			if ok(obj) then return obj end
		end
	elseif kind=="Label" then
		for _, d in ipairs(plot:GetDescendants()) do if ok(d) then return d end end
		for _, name in ipairs(Config.LABEL_CANDIDATES) do
			local obj = plot:FindFirstChild(name, true)
			if ok(obj) then return obj end
		end
	elseif kind=="Prompt" then
		for _, name in ipairs(Config.PROMPT_CANDIDATES) do
			local obj = plot:FindChild(name, true)
			if ok(obj) then return obj end
		end
		for _, d in ipairs(plot:GetDescendants()) do if ok(d) then return d end end
	end
	return nil
end

task.defer(function()
	local r = root()
	if not r then warn("[Scanner] No se encontró raíz de acuarios"); return end
	print("[Scanner] Root:", r:GetFullName())
	for _, plot in ipairs(r:GetChildren()) do
		if plot:IsA("Model") or plot:IsA("Folder") then
			local anchor = findOne(plot, "BasePart")
			local label  = findOne(plot, "Label")
			local prompt = findOne(plot, "Prompt")
			print(string.format("[Scanner] Plot=%s | Anchor=%s | Label=%s | Prompt=%s",
				plot.Name,
				anchor and anchor.Name or "nil",
				label  and label:GetFullName() or "nil",
				prompt and prompt:GetFullName() or "nil"))
		end
	end
end)