--over the  years i have found that it is much easier on performance to use frames and UI for ESP than drawing, at the cost of detectability.

--i belive every executor under the sun should have gethui() but if not.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Container Setup (The "gethui" logic)
local UIContainer;
if gethui then
    ui = gethui()
else
    ui = Player:WaitForChild("PlayerGui")
end

local ESPScreen = Instance.new("ScreenGui")
ESPScreen.Name = "\0" -- Null name to make it slightly harder to find via FindFirstChild
ESPScreen.IgnoreGuiInset = true
ESPScreen.DisplayOrder = 10
ESPScreen.Parent = ui

local config = {
    enabled = true,
    thickness = 1,
    teamcheck = true,
    color = {
        UseTeamColor = true,
        r = 255, g = 255, b = 255
    }
}

local function GetESPColor(plr)
    if config.color.UseTeamColor and plr.Team then
        return plr.TeamColor.Color
    end
    return Color3.fromRGB(config.color.r, config.color.g, config.color.b)
end

-- Line UI Factory
local function DrawLine()
    local f = Instance.new("Frame")
    f.Visible = false
    f.BorderSizePixel = 0
    f.BackgroundColor3 = Color3.new(1, 1, 1)
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Parent = ESPScreen
    return f
end

-- Math for UI Line Placement
local function UpdateLine(frame, from, to)
    local distance = (from - to).Magnitude
    local center = (from + to) / 2
    local rotation = math.atan2(to.Y - from.Y, to.X - from.X)

    frame.Size = UDim2.new(0, distance, 0, config.thickness)
    frame.Position = UDim2.new(0, center.X, 0, center.Y)
    frame.Rotation = math.deg(rotation)
    frame.Visible = true
end

local function DrawESP(plr)
    local limbs = {}
    local connection

    local function Cleanup()
        if connection then connection:Disconnect() end
        for _, v in pairs(limbs) do v:Destroy() end
        limbs = {}
    end

    local function CreateLimbTable(isR15)
        for _, v in pairs(limbs) do v:Destroy() end
        if isR15 then
            limbs = {
                Head_UT = DrawLine(), UT_LT = DrawLine(),
                UT_LUA = DrawLine(), LUA_LLA = DrawLine(), LLA_LH = DrawLine(),
                UT_RUA = DrawLine(), RUA_RLA = DrawLine(), RLA_RH = DrawLine(),
                LT_LUL = DrawLine(), LUL_LLL = DrawLine(), LLL_LF = DrawLine(),
                LT_RUL = DrawLine(), RUL_RLL = DrawLine(), RLL_RF = DrawLine()
            }
        else
            limbs = {
                Head_Spine = DrawLine(), Spine = DrawLine(),
                L_Arm = DrawLine(), LA_UT = DrawLine(),
                R_Arm = DrawLine(), RA_UT = DrawLine(),
                L_Leg = DrawLine(), LL_LT = DrawLine(),
                R_Leg = DrawLine(), RL_LT = DrawLine()
            }
        end
    end

    connection = RunService.RenderStepped:Connect(function()
        local char = plr.Character
        if not char or not char:FindFirstChild("Humanoid") or not char:FindFirstChild("HumanoidRootPart") or not config.enabled or (config.teamcheck and plr.Team == Player.Team) then
            for _, v in pairs(limbs) do v.Visible = false end
            if not Players:FindFirstChild(plr.Name) then Cleanup() end
            return
        end

        local isR15 = (char.Humanoid.RigType == Enum.HumanoidRigType.R15)
        if #limbs == 0 then CreateLimbTable(isR15) end

        local _, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
        local color = GetESPColor(plr)

        if onScreen and char.Humanoid.Health > 0 then
            local function GP(part) -- Get Screen Position
                local pName = isR15 and part or (part == "UpperTorso" and "Torso" or part)
                local obj = char:FindFirstChild(pName)
                if obj then
                    local p = Camera:WorldToViewportPoint(obj.Position)
                    return Vector2.new(p.X, p.Y)
                end
                return nil
            end

            if isR15 then
                local H, UT, LT = GP("Head"), GP("UpperTorso"), GP("LowerTorso")
                local LUA, LLA, LH = GP("LeftUpperArm"), GP("LeftLowerArm"), GP("LeftHand")
                local RUA, RLA, RH = GP("RightUpperArm"), GP("RightLowerArm"), GP("RightHand")
                local LUL, LLL, LF = GP("LeftUpperLeg"), GP("LeftLowerLeg"), GP("LeftFoot")
                local RUL, RLL, RF = GP("RightUpperLeg"), GP("RightLowerLeg"), GP("RightFoot")

                if H and UT then UpdateLine(limbs.Head_UT, H, UT) end
                if UT and LT then UpdateLine(limbs.UT_LT, UT, LT) end
                if UT and LUA then UpdateLine(limbs.UT_LUA, UT, LUA) end
                if LUA and LLA then UpdateLine(limbs.LUA_LLA, LUA, LLA) end
                if LUA and LH then UpdateLine(limbs.LLA_LH, LLA, LH) end
                if UT and RUA then UpdateLine(limbs.UT_RUA, UT, RUA) end
                if RUA and RLA then UpdateLine(limbs.RUA_RLA, RUA, RLA) end
                if RLA and RH then UpdateLine(limbs.RLA_RH, RLA, RH) end
                if LT and LUL then UpdateLine(limbs.LT_LUL, LT, LUL) end
                if LUL and LLL then UpdateLine(limbs.LUL_LLL, LUL, LLL) end
                if LLL and LF then UpdateLine(limbs.LLL_LF, LLL, LF) end
                if LT and RUL then UpdateLine(limbs.LT_RUL, LT, RUL) end
                if RUL and RLL then UpdateLine(limbs.RUL_RLL, RUL, RLL) end
                if RLL and RF then UpdateLine(limbs.RLL_RF, RLL, RF) end
            else
                local T = char:FindFirstChild("Torso")
                if T then
                    local H = GP("Head")
                    local T_Pos = T.CFrame
                    local UT = Camera:WorldToViewportPoint((T_Pos * CFrame.new(0, 1, 0)).p)
                    local LT = Camera:WorldToViewportPoint((T_Pos * CFrame.new(0, -1, 0)).p)
                    local UT_V2, LT_V2 = Vector2.new(UT.X, UT.Y), Vector2.new(LT.X, LT.Y)

                    local function GetR6Limb(name, offset)
                        local limb = char:FindFirstChild(name)
                        if limb then
                            local up = Camera:WorldToViewportPoint((limb.CFrame * CFrame.new(0, offset, 0)).p)
                            local dn = Camera:WorldToViewportPoint((limb.CFrame * CFrame.new(0, -offset, 0)).p)
                            return Vector2.new(up.X, up.Y), Vector2.new(dn.X, dn.Y)
                        end
                    end

                    local LUA, LLA = GetR6Limb("Left Arm", 1)
                    local RUA, RLA = GetR6Limb("Right Arm", 1)
                    local LUL, LLL = GetR6Limb("Left Leg", 1)
                    local RUL, RLL = GetR6Limb("Right Leg", 1)

                    if H and UT_V2 then UpdateLine(limbs.Head_Spine, H, UT_V2) end
                    if UT_V2 and LT_V2 then UpdateLine(limbs.Spine, UT_V2, LT_V2) end
                    if LUA and LLA then UpdateLine(limbs.L_Arm, LUA, LLA) end
                    if LUA and UT_V2 then UpdateLine(limbs.LA_UT, LUA, UT_V2) end
                    if RUA and RLA then UpdateLine(limbs.R_Arm, RUA, RLA) end
                    if RUA and UT_V2 then UpdateLine(limbs.RA_UT, RUA, UT_V2) end
                    if LUL and LLL then UpdateLine(limbs.L_Leg, LUL, LLL) end
                    if LUL and LT_V2 then UpdateLine(limbs.LL_LT, LUL, LT_V2) end
                    if RUL and RLL then UpdateLine(limbs.R_Leg, RUL, RLL) end
                    if RUL and LT_V2 then UpdateLine(limbs.RL_LT, RUL, LT_V2) end
                end
            end

            for _, line in pairs(limbs) do line.BackgroundColor3 = color end
        else
            for _, v in pairs(limbs) do v.Visible = false end
        end
    end)
end

-- Initialization
for _, v in pairs(Players:GetPlayers()) do
    if v ~= Player then DrawESP(v) end
end

Players.PlayerAdded:Connect(function(v)
    if v ~= Player then DrawESP(v) end
end)

return config
