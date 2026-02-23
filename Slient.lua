-- silentAim.lua
-- Pre-flick silent aim: snaps camera to target before
-- click input reaches the game, then restores.

local Players    = game:GetService("Players")
local UserInput  = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local Library = {
    enabled    = false,
    fov        = 180,
    hitbox     = 'Head',
    teamcheck  = true,
    snapBack   = true,
    snapFrames = 1,
    -- stored as raw string from KeyPicker e.g. "MB1", "MB2", "F"
    triggerKey = 'MB1',
}

-- ── Key match helper ──────────────────────────────────────────
-- KeyPicker returns strings like "MB1", "MB2", or a KeyCode name
local function inputMatches(input)
    local k = Library.triggerKey
    if k == 'MB1' then
        return input.UserInputType == Enum.UserInputType.MouseButton1
    elseif k == 'MB2' then
        return input.UserInputType == Enum.UserInputType.MouseButton2
    else
        -- assume it's a KeyCode name string e.g. "F", "E", "CapsLock"
        local ok, enum = pcall(function()
            return Enum.KeyCode[k]
        end)
        return ok and enum and input.KeyCode == enum
    end
end

-- ── Helpers ───────────────────────────────────────────────────
local function isAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isTeammate(player)
    if not Library.teamcheck then return false end
    return player.Team ~= nil and player.Team == LocalPlayer.Team
end

local function getHitboxPart(char)
    if Library.hitbox == 'Head' then
        return char:FindFirstChild('Head')
    elseif Library.hitbox == 'Torso' then
        return char:FindFirstChild('HumanoidRootPart')
            or char:FindFirstChild('Torso')
            or char:FindFirstChild('UpperTorso')
    elseif Library.hitbox == 'Nearest' then
        local center      = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local closest, closestDist = nil, math.huge
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local sp, vis = Camera:WorldToViewportPoint(part.Position)
                if vis then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = part
                    end
                end
            end
        end
        return closest
    end
end

local function getBestTarget()
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best, bestDist = nil, Library.fov

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if isTeammate(p)    then continue end

        local char = p.Character
        if not char or not isAlive(char) then continue end

        local part = getHitboxPart(char)
        if not part then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            best = part
        end
    end

    return best
end

-- ── Flick on input frame ─────────────────────────────────────
UserInput.InputBegan:Connect(function(input, processed)
    if processed           then return end
    if not Library.enabled then return end
    if not inputMatches(input) then return end

    local target = getBestTarget()
    if not target then return end

    local originalCF = Camera.CFrame
    Camera.CFrame    = CFrame.lookAt(originalCF.Position, target.Position)

    if Library.snapBack then
        Camera.CFrame = originalCF
    end
end)

function Library.Hook() end

return Library
