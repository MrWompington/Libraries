local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput  = game:GetService("UserInputService")
local Camera     = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local Library = {
    -- core
    enabled     = false,
    teamcheck   = true,

    -- targeting
    fov         = 90,       -- radius in pixels
    hitbox      = 'Head',   -- 'Head' | 'Torso' | 'Nearest'
    smoothing   = 0.25,     -- 0.0 = instant, 1.0 = very slow (lerp factor inverted)

    -- trigger
    holdKey     = Enum.UserInputType.MouseButton2, -- aim only while held
    toggleMode  = false,    -- if true, key toggles instead of hold

    -- internals
    Targets     = {},
    _active     = false,    -- internal toggle state (used in toggle mode)
}

-- ── Helpers ────────────────────────────────────────────────────

local function isAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isTeammate(player)
    if not Library.teamcheck then return false end
    local lp = LocalPlayer
    return player ~= lp
        and player.Team ~= nil
        and player.Team == lp.Team
end

local function getHitboxPart(char)
    if Library.hitbox == 'Head' then
        return char:FindFirstChild('Head')
    elseif Library.hitbox == 'Torso' then
        return char:FindFirstChild('HumanoidRootPart')
            or char:FindFirstChild('Torso')
            or char:FindFirstChild('UpperTorso')
    elseif Library.hitbox == 'Nearest' then
        -- find whichever visible part is closest to screen center
        local center  = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local closest = nil
        local closestDist = math.huge
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

local function getScreenPos(part)
    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
    return Vector2.new(sp.X, sp.Y), onScreen
end

local function getBestTarget()
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best     = nil
    local bestDist = Library.fov  -- only consider targets within FOV radius

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if isTeammate(p)    then continue end

        local char = p.Character
        if not char or not isAlive(char) then continue end

        local part = getHitboxPart(char)
        if not part then continue end

        local sp, onScreen = getScreenPos(part)
        if not onScreen then continue end

        local dist = (sp - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            best     = part
        end
    end

    return best
end

local function isKeyDown()
    if typeof(Library.holdKey) == "EnumItem" then
        if Library.holdKey.EnumType == Enum.KeyCode then
            return UserInput:IsKeyDown(Library.holdKey)
        elseif Library.holdKey.EnumType == Enum.UserInputType then
            return UserInput:IsMouseButtonPressed(Library.holdKey)
        end
    end
    return false
end

-- ── Toggle mode input ─────────────────────────────────────────
UserInput.InputBegan:Connect(function(input, processed)
    if processed then return end
    if Library.toggleMode and input.KeyCode == Library.holdKey
    or Library.toggleMode and input.UserInputType == Library.holdKey then
        Library._active = not Library._active
    end
end)

-- ── Main loop ─────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not Library.enabled then return end

    local shouldAim = Library.toggleMode and Library._active
                   or (not Library.toggleMode and isKeyDown())

    if not shouldAim then return end

    local target = getBestTarget()
    if not target then return end

    local targetPos  = target.Position
    local currentCF  = Camera.CFrame
    local lookCF     = CFrame.lookAt(currentCF.Position, targetPos)

    -- smooth lerp toward target
    local smooth = 1 - math.clamp(Library.smoothing, 0, 0.99)
    Camera.CFrame = currentCF:Lerp(lookCF, smooth)
end)

-- ── Hook (matches ESP API style) ──────────────────────────────
-- Aimbot auto-targets from Players list, Hook is a no-op stub
-- kept for API consistency so scripts can call it the same way
function Library.Hook(target)
    -- no-op: aimbot reads Players:GetPlayers() directly
end

return Library
