local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local ui;
if gethui then ui = gethui() else ui = Players.LocalPlayer:WaitForChild("PlayerGui") end

if ui:FindFirstChild("Skeleton_ESP") then ui.Skeleton_ESP:Destroy() end

local ESPScreen = Instance.new("ScreenGui")
ESPScreen.Name = "Skeleton_ESP"
ESPScreen.IgnoreGuiInset = true
ESPScreen.Parent = ui

local Library = {
    enabled = true,
    teamcheck = false,
    color = Color3.fromRGB(255, 255, 255),
    thickness = 1,
    Targets = {}
}

local function createLine()
    local line = Instance.new("Frame")
    line.BorderSizePixel = 0
    -- Critical Fix: AnchorPoint at 0.5 ensures rotation happens at the midpoint
    line.AnchorPoint = Vector2.new(0.5, 0.5) 
    line.BackgroundColor3 = Library.color
    line.Visible = false
    line.Parent = ESPScreen
    return line
end

-- Precise math to mimic Drawing.Line behavior using UI Frames
local function drawLineBetween(line, p1, p2)
    local unit = (p2 - p1).Unit
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
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not obj or not obj.Parent or not table.find(Library.Targets, obj) then
            for _, v in pairs(lines) do v:Destroy() end
            connection:Disconnect()
            return
        end

        local hum = obj:FindFirstChildOfClass("Humanoid")
        local root = obj:FindFirstChild("HumanoidRootPart")
        local isPlayer = Players:GetPlayerFromCharacter(obj)

        if not Library.enabled or not root or not hum or hum.Health <= 0 or (Library.teamcheck and isPlayer and isPlayer.Team == Players.LocalPlayer.Team) then
            for _, v in pairs(lines) do v.Visible = false end
            return
        end

        local _, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            for _, v in pairs(lines) do v.Visible = false end
            return
        end

        local isR15 = hum.RigType == Enum.HumanoidRigType.R15
        
        -- Internal function to handle point-to-point drawing
        local function segment(name, v3_1, v3_2)
            local p1, vis1 = Camera:WorldToViewportPoint(v3_1)
            local p2, vis2 = Camera:WorldToViewportPoint(v3_2)
            
            lines[name] = lines[name] or createLine()
            if vis1 or vis2 then
                drawLineBetween(lines[name], Vector2.new(p1.X, p1.Y), Vector2.new(p2.X, p2.Y))
                lines[name].BackgroundColor3 = (Library.teamcheck and isPlayer and isPlayer.TeamColor.Color) or Library.color
            else
                lines[name].Visible = false
            end
        end

        if isR15 then
            -- R15 Rig Logic
            local parts = obj
            segment("HeadSpine", parts.Head.Position, parts.UpperTorso.Position)
            segment("Spine", parts.UpperTorso.Position, parts.LowerTorso.Position)
            -- Arms
            segment("L_Arm1", parts.UpperTorso.Position, parts.LeftUpperArm.Position)
            segment("L_Arm2", parts.LeftUpperArm.Position, parts.LeftLowerArm.Position)
            segment("L_Arm3", parts.LeftLowerArm.Position, parts.LeftHand.Position)
            segment("R_Arm1", parts.UpperTorso.Position, parts.RightUpperArm.Position)
            segment("R_Arm2", parts.RightUpperArm.Position, parts.RightLowerArm.Position)
            segment("R_Arm3", parts.RightLowerArm.Position, parts.RightHand.Position)
            -- Legs
            segment("L_Leg1", parts.LowerTorso.Position, parts.LeftUpperLeg.Position)
            segment("L_Leg2", parts.LeftUpperLeg.Position, parts.LeftLowerLeg.Position)
            segment("L_Leg3", parts.LeftLowerLeg.Position, parts.LeftFoot.Position)
            segment("R_Leg1", parts.LowerTorso.Position, parts.RightUpperLeg.Position)
            segment("R_Leg2", parts.RightUpperLeg.Position, parts.RightLowerLeg.Position)
            segment("R_Leg3", parts.RightLowerLeg.Position, parts.RightFoot.Position)
        else
            -- R6 Rig Logic (Matches Blissful4992 Offset Math)
            local t = obj.Torso
            local tHeight = t.Size.Y/2 - 0.2
            
            segment("HeadSpine", obj.Head.Position, (t.CFrame * CFrame.new(0, tHeight, 0)).p)
            segment("Spine", (t.CFrame * CFrame.new(0, tHeight, 0)).p, (t.CFrame * CFrame.new(0, -tHeight, 0)).p)
            
            -- Arms
            local la, ra = obj["Left Arm"], obj["Right Arm"]
            local laH, raH = la.Size.Y/2 - 0.2, ra.Size.Y/2 - 0.2
            segment("L_Arm_Joint", (t.CFrame * CFrame.new(0, tHeight, 0)).p, (la.CFrame * CFrame.new(0, laH, 0)).p)
            segment("L_Arm_Limb", (la.CFrame * CFrame.new(0, laH, 0)).p, (la.CFrame * CFrame.new(0, -laH, 0)).p)
            segment("R_Arm_Joint", (t.CFrame * CFrame.new(0, tHeight, 0)).p, (ra.CFrame * CFrame.new(0, raH, 0)).p)
            segment("R_Arm_Limb", (ra.CFrame * CFrame.new(0, raH, 0)).p, (ra.CFrame * CFrame.new(0, -raH, 0)).p)
            
            -- Legs
            local ll, rl = obj["Left Leg"], obj["Right Leg"]
            local llH, rlH = ll.Size.Y/2 - 0.2, rl.Size.Y/2 - 0.2
            segment("L_Leg_Joint", (t.CFrame * CFrame.new(0, -tHeight, 0)).p, (ll.CFrame * CFrame.new(0, llH, 0)).p)
            segment("L_Leg_Limb", (ll.CFrame * CFrame.new(0, llH, 0)).p, (ll.CFrame * CFrame.new(0, -llH, 0)).p)
            segment("R_Leg_Joint", (t.CFrame * CFrame.new(0, -tHeight, 0)).p, (rl.CFrame * CFrame.new(0, rlH, 0)).p)
            segment("R_Leg_Limb", (rl.CFrame * CFrame.new(0, rlH, 0)).p, (rl.CFrame * CFrame.new(0, -rlH, 0)).p)
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

return Library
