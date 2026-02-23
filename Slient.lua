-- silentAim.lua
-- Pre-flick silent aim: snaps camera to nearest target before
-- the click input reaches the game, then restores immediately.
-- Works on most click-to-shoot games. Game-specific versions
-- should override this with proper projectile manipulation.

local Players    = game:GetService("Players")
local UserInput  = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local Library = {
    enabled     = false,
    fov         = 180,      -- wider than legit aimbot by default
    hitbox      = 'Head',   -- 'Head' | 'Torso' | 'Nearest'
    teamcheck   = true,
    triggerKey  = Enum.UserInputType.MouseButton1,
    snapBack    = true,     -- restore camera after snap
    snapFrames  = 1,        -- how many frames to hold snap before restoring
}

-- ── Helpers (mirrors aimbotUI pattern) ───────────────────────

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
        local closest     = nil
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

local function getBestTarget()
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best     = nil
    local bestDist = Library.fov

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer  then continue end
        if isTeammate(p)     then continue end

        local char = p.Character
        if not char or not isAlive(char) then continue end

        local part = getHitboxPart(char)
        if not part then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            best     = part
        end
    end

    return best
end

-- ── Pre-flick input intercept ─────────────────────────────────
UserInput.InputBegan:Connect(function(input, processed)
    if processed                              then return end
    if not Library.enabled                    then return end
    if input.UserInputType ~= Library.triggerKey
    and input.KeyCode      ~= Library.triggerKey then return end

    local target = getBestTarget()
    if not target then return end

    local originalCF = Camera.CFrame
    local snapCF     = CFrame.lookAt(originalCF.Position, target.Position)

    -- snap
    Camera.CFrame = snapCF

    if Library.snapBack then
        -- restore after N frames so the click fires during the snap window
        local frames = 0
        local conn
        conn = RunService.RenderStepped:Connect(function()
            frames += 1
            if frames >= Library.snapFrames then
                Camera.CFrame = originalCF
                conn:Disconnect()
            end
        end)
    end
end)

-- no-op Hook stub for API consistency
function Library.Hook() end

return Library
