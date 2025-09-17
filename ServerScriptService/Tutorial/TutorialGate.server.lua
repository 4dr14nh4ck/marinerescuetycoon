-- ServerScriptService/Tutorial/TutorialGate.lua
-- Freezes players until they accept the tutorial. Simple per-session gate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote folder + event
local folder = ReplicatedStorage:FindFirstChild("TutorialEvents") or Instance.new("Folder")
folder.Name = "TutorialEvents"
folder.Parent = ReplicatedStorage

local TutorialAccept = folder:FindFirstChild("TutorialAccept") or Instance.new("RemoteEvent")
TutorialAccept.Name = "TutorialAccept"
TutorialAccept.Parent = folder

-- Helper: freeze/unfreeze character
local function setFrozen(character, frozen)
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then
		if frozen then
			-- safer than anchoring: stop movement + platform stand
			hum.WalkSpeed = 0
			hum.JumpPower = 0
			hum.AutoRotate = false
			hum.PlatformStand = true
		else
			-- restore reasonable defaults (use your game defaults if different)
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			hum.AutoRotate = true
			hum.PlatformStand = false
		end
	end
	-- Optional: anchor root to avoid physics drift
	if hrp then
		hrp.Anchored = frozen
	end
	-- Disable/enable equipped tools (if any)
	for _,tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			tool.Enabled = not frozen
		end
	end
end

local function onCharacterAdded(player, character)
	-- mark as not accepted each spawn
	if player:GetAttribute("TutorialAccepted") ~= true then
		player:SetAttribute("TutorialAccepted", false)
	end
	-- freeze on spawn if not accepted yet
	task.defer(function()
		if player:GetAttribute("TutorialAccepted") ~= true then
			setFrozen(character, true)
		else
			setFrozen(character, false)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("TutorialAccepted", false)
	player.CharacterAdded:Connect(function(char) onCharacterAdded(player, char) end)
	-- if character already exists (respawn disabled scenarios)
	if player.Character then onCharacterAdded(player, player.Character) end
end)

-- Unfreeze when client accepts
TutorialAccept.OnServerEvent:Connect(function(player)
	if player:GetAttribute("TutorialAccepted") == true then return end
	player:SetAttribute("TutorialAccepted", true)
	if player.Character then
		setFrozen(player.Character, false)
	end
end)
