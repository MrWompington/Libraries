local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local ui;
if gethui then ui = gethui() else ui = Players.LocalPlayer:WaitForChild("PlayerGui") end

if ui:FindFirstChild("Skeleton_ESP") then ui.Skeleton_ESP:Destroy() end

local ESPScreen = Instance.new("ScreenGui")
ESPScreen.Name = "Skeleton_ESP"
ESPScreen.IgnoreGuiInset = true
ESPScreen.DisplayOrder = 10
ESPScreen.Parent = ui

local Library = {
    enabled = true,
    teamcheck = false,
    color = Color3.fromRGB(255, 255, 255),
    thickness = 2,
    Targets = {},
    headdot = true, -- Now functional
    dotSize = 5
}

-- Helper to create lines
local function createLine()
    local line = Instance.new("Frame")
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5) 
    line.BackgroundColor3 = Library.color
    line.Visible = false
    line.Parent = ESPScreen
    return line
end

-- Helper to create the head dot
local function createDot()
    local dot = Instance.new("Frame")
    dot.BorderSizePixel = 0
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Library.color
    dot.Visible = false
    dot.Parent = ESPScreen
    -- Make it round
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot
    return dot
end

local function drawLineBetween(line, p1, p2)
    local dist = (p2 - p1).Magnitude
    local center = (p1 + p2) / 2
    local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)

    line.Size = UDim2.new(0, dist, 0, Library.thickness)
    line.Position = UDim2.new(0, center.X, 0, center.Y)
    line.Rotation = math.deg(angle)
    line.Visible = true
end

local function drawSkeleton(obj)
    local lines = {}
    local headDot = createDot()
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not obj or not obj.Parent then
            for _, v in pairs(lines) do v:Destroy() end
            headDot:Destroy()
            connection:Disconnect()
            return
        end

        local hum = obj:FindFirstChildOfClass("Humanoid")
        local root = obj:FindFirstChild("HumanoidRootPart")
        local head = obj:FindFirstChild("Head")
        local isPlayer = Players:GetPlayerFromCharacter(obj)

        -- Check if we should draw
        if not Library.enabled or not root or not hum or hum.Health <= 0 or (Library.teamcheck and isPlayer and isPlayer.Team == Players.LocalPlayer.Team) then
            for _, v in pairs(lines) do v.Visible = false end
            headDot.Visible = false
            return
        end

        local _, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            for _, v in pairs(lines) do v.Visible = false end
            headDot.Visible = false
            return
        end

        local currentColor = (Library.teamcheck and isPlayer and isPlayer.TeamColor.Color) or Library.color

        -- Segment drawing internal function
        local function segment(name, v3_1, v3_2)
            local p1, vis1 = Camera:WorldToViewportPoint(v3_1)
            local p2, vis2 = Camera:WorldToViewportPoint(v3_2)
            
            lines[name] = lines[name] or createLine()
            if vis1 or vis2 then
                drawLineBetween(lines[name], Vector2.new(p1.X, p1.Y), Vector2.new(p2.X, p2.Y))
                lines[name].BackgroundColor3 = currentColor
            else
                lines[name].Visible = false
            end
        end

        -- Handle Head Dot
        if Library.headdot and head then
            local p, vis = Camera:WorldToViewportPoint(head.Position)
            if vis then
                headDot.Visible = true
                headDot.Position = UDim2.new(0, p.X, 0, p.Y)
                headDot.Size = UDim2.new(0, Library.dotSize, 0, Library.dotSize)
                headDot.BackgroundColor3 = currentColor
            else
                headDot.Visible = false
            end
        else
            headDot.Visible = false
        end

        -- Rig Logic
        if hum.RigType == Enum.HumanoidRigType.R15 then
            segment("HeadSpine", head.Position, obj.UpperTorso.Position)
            segment("Spine", obj.UpperTorso.Position, obj.LowerTorso.Position)
            -- Arms
            segment("L_Arm1", obj.UpperTorso.Position, obj.LeftUpperArm.Position)
            segment("L_Arm2", obj.LeftUpperArm.Position, obj.LeftLowerArm.Position)
            segment("L_Arm3", obj.LeftLowerArm.Position, obj.LeftHand.Position)
            segment("R_Arm1", obj.UpperTorso.Position, obj.RightUpperArm.Position)
            segment("R_Arm2", obj.RightUpperArm.Position, obj.RightLowerArm.Position)
            segment("R_Arm3", obj.RightLowerArm.Position, obj.RightHand.Position)
            -- Legs
            segment("L_Leg1", obj.LowerTorso.Position, obj.LeftUpperLeg.Position)
            segment("L_Leg2", obj.LeftUpperLeg.Position, obj.LeftLowerLeg.Position)
            segment("L_Leg3", obj.LeftLowerLeg.Position, obj.LeftFoot.Position)
            segment("R_Leg1", obj.LowerTorso.Position, obj.RightUpperLeg.Position)
            segment("R_Leg2", obj.RightUpperLeg.Position, obj.RightLowerLeg.Position)
            segment("R_Leg3", obj.RightLowerLeg.Position, obj.RightFoot.Position)
        else
            local t = obj.Torso
            local tHeight = t.Size.Y/2 - 0.2
            local upperTorsoPos = (t.CFrame * CFrame.new(0, tHeight, 0)).Position
            local lowerTorsoPos = (t.CFrame * CFrame.new(0, -tHeight, 0)).Position
            
            segment("HeadSpine", head.Position, upperTorsoPos)
            segment("Spine", upperTorsoPos, lowerTorsoPos)
            
            -- Arms
            local la, ra = obj["Left Arm"], obj["Right Arm"]
            segment("L_Arm_Joint", upperTorsoPos, (la.CFrame * CFrame.new(0, la.Size.Y/2, 0)).Position)
            segment("L_Arm_Limb", (la.CFrame * CFrame.new(0, la.Size.Y/2, 0)).Position, (la.CFrame * CFrame.new(0, -la.Size.Y/2, 0)).Position)
            segment("R_Arm_Joint", upperTorsoPos, (ra.CFrame * CFrame.new(0, ra.Size.Y/2, 0)).Position)
            segment("R_Arm_Limb", (ra.CFrame * CFrame.new(0, ra.Size.Y/2, 0)).Position, (ra.CFrame * CFrame.new(0, -ra.Size.Y/2, 0)).Position)
            
            -- Legs
            local ll, rl = obj["Left Leg"], obj["Right Leg"]
            segment("L_Leg_Joint", lowerTorsoPos, (ll.CFrame * CFrame.new(0, ll.Size.Y/2, 0)).Position)
            segment("L_Leg_Limb", (ll.CFrame * CFrame.new(0, ll.Size.Y/2, 0)).Position, (ll.CFrame * CFrame.new(0, -ll.Size.Y/2, 0)).Position)
            segment("R_Leg_Joint", lowerTorsoPos, (rl.CFrame * CFrame.new(0, rl.Size.Y/2, 0)).Position)
            segment("R_Leg_Limb", (rl.CFrame * CFrame.new(0, rl.Size.Y/2, 0)).Position, (rl.CFrame * CFrame.new(0, -rl.Size.Y/2, 0)).Position)
        end
    end)
end

function Library.Hook(target)
    local function process(char)
        if not char then return end
        task.spawn(function()
            char:WaitForChild("HumanoidRootPart", 10)
            char:WaitForChild("Head", 10)
            if not table.find(Library.Targets, char) then
                table.insert(Library.Targets, char)
                drawSkeleton(char)
            end
        end)
    end

    if typeof(target) == "Instance" then
        if target:IsA("Player") then
            target.CharacterAdded:Connect(process)
            if target.Character then process(target.Character) end
        elseif target:IsA("Model") then
            process(target)
        end
    end
end

-- Initialize for all players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        Library.Hook(player)
    end
end

Players.PlayerAdded:Connect(Library.Hook)

return Library
