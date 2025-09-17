-- Habilita movimiento/salto por si algún UI lo desactiva accidentalmente
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function resetHumanoid(h: Humanoid)
	if not h then return end
	if h.UseJumpPower ~= nil then
		h.JumpPower = math.max(h.JumpPower, 40)
	else
		h.JumpHeight = math.max(h.JumpHeight, 7)
	end
	h.WalkSpeed = math.max(h.WalkSpeed, 16)
end

local function onChar(char)
	resetHumanoid(char:FindFirstChildOfClass("Humanoid"))
	char.ChildAdded:Connect(function(ch)
		if ch:IsA("Humanoid") then resetHumanoid(ch) end
	end)
end

player.CharacterAdded:Connect(onChar)
if player.Character then onChar(player.Character) end