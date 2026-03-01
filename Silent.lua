-- silentAim.lua (FIXED)
local Players    = game:GetService("Players")
local UserInput  = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local Library = {
    enabled    = true, -- Set to true by default for testing
    fov        = 180,
    hitbox     = 'Head',
    teamcheck  = true,
    snapBack   = true,
    triggerKey = 'MB1', -- Mouse Button 1
}

-- Check if target is valid
local function isAlive(player)
    return player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

-- Team check
local function isTeammate(player)
    if not Library.teamcheck then return false end
    return player.Team == LocalPlayer.Team
end

-- Find best target inside FOV
local function getBestTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget, bestDist = nil, Library.fov

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer or isTeammate(p) then continue end
        
        local char = p.Character
        if isAlive(p) then
            local part = char:FindFirstChild(Library.hitbox)
            if not part then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestTarget = part
                end
            end
        end
    end
    return bestTarget
end

-- The Fix: Snap and Delay
UserInput.InputBegan:Connect(function(input, processed)
    -- We allow 'processed' because many guns use MB1 which registers as processed
    if not Library.enabled then return end
    
    local isMatch = false
    if Library.triggerKey == 'MB1' and input.UserInputType == Enum.UserInputType.MouseButton1 then isMatch = true
    elseif Library.triggerKey == 'MB2' and input.UserInputType == Enum.UserInputType.MouseButton2 then isMatch = true
    elseif input.KeyCode.Name == Library.triggerKey then isMatch = true end

    if not isMatch then return end

    local target = getBestTarget()
    if target then
        local originalCF = Camera.CFrame
        
        -- 1. Point camera at target
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)

        -- 2. Wait a tiny fraction of a second so the game registers the hit
        -- This is the "Pre-flick" logic that was missing.
        task.defer(function()
            RunService.RenderStepped:Wait() 
            if Library.snapBack then
                Camera.CFrame = originalCF
            end
        end)
    end
end)

return Library
