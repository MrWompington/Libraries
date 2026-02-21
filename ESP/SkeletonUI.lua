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

-- Precise line creation to mimic Drawing.new("Line")
local function createLine()
    local line = Instance.new("Frame")
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = Library.color
    line.Visible = false
    line.Parent = ESPScreen
    return line
end

-- Math to position a Frame between two 2D points
local function updateLine(line, p1, p2)
    local dist = (p1 - p2).Magnitude
    local center = (p1 + p2) / 2
    local angle = math.atan2(p2.Y - p1.Y, p2.X - p1.X)

    line.Size = UDim2.new(0, dist, 0, Library.thickness)
    line.Position = UDim2.new(0, center.X, 0, center.Y)
    line.Rotation = math.deg(angle)
    line.Visible = true
end

local function getJoints(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local isR15 = (hum and hum.RigType == Enum.HumanoidRigType.R15)
    
    if isR15 then
        return {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
        }
    else
        -- R6 Math requires offsets to look clean
        return {
            {"Head", "Torso", "R6_Head"},
            {"Torso", "Left Arm", "R6_LeftArm"},
            {"Torso", "Right Arm", "R6_RightArm"},
            {"Torso", "Left Leg", "R6_LeftLeg"},
            {"Torso", "Right Leg", "R6_RightLeg"},
            {"Torso", "Torso", "R6_Spine"}
        }
    end
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

        local joints = getJoints(obj)
        for i, joint in pairs(joints) do
            local p1, p2
            
            -- R6 Specific Offset Math from original Blissful4992 lib
            if joint[3] and joint[3]:find("R6") then
                local torso = obj:FindFirstChild("Torso")
                if not torso then continue end
                local tHeight = torso.Size.Y/2 - 0.2
                
                if joint[3] == "R6_Head" then
                    p1 = Camera:WorldToViewportPoint(obj.Head.Position)
                    p2 = Camera:WorldToViewportPoint((torso.CFrame * CFrame.new(0, tHeight, 0)).p)
                elseif joint[3] == "R6_Spine" then
                    p1 = Camera:WorldToViewportPoint((torso.CFrame * CFrame.new(0, tHeight, 0)).p)
                    p2 = Camera:WorldToViewportPoint((torso.CFrame * CFrame.new(0, -tHeight, 0)).p)
                else
                    local limb = obj:FindFirstChild(joint[2])
                    if limb then
                        local lHeight = limb.Size.Y/2 - 0.2
                        p1 = Camera:WorldToViewportPoint((torso.CFrame * CFrame.new(0, (joint[2]:find("Leg") and -tHeight or tHeight), 0)).p)
                        p2 = Camera:WorldToViewportPoint((limb.CFrame * CFrame.new(0, lHeight, 0)).p)
                        
                        -- Draw the extra limb segment
                        local extraKey = joint[2].."_extra"
                        local p3 = Camera:WorldToViewportPoint((limb.CFrame * CFrame.new(0, -lHeight, 0)).p)
                        lines[extraKey] = lines[extraKey] or createLine()
                        updateLine(lines[extraKey], Vector2.new(p2.X, p2.Y), Vector2.new(p3.X, p3.Y))
                    end
                end
            else
                -- Standard R15 Logic
                local partA, partB = obj:FindFirstChild(joint[1]), obj:FindFirstChild(joint[2])
                if partA and partB then
                    p1 = Camera:WorldToViewportPoint(partA.Position)
                    p2 = Camera:WorldToViewportPoint(partB.Position)
                end
            end

            if p1 and p2 then
                lines[i] = lines[i] or createLine()
                updateLine(lines[i], Vector2.new(p1.X, p1.Y), Vector2.new(p2.X, p2.Y))
                lines[i].BackgroundColor3 = (Library.teamcheck and isPlayer and isPlayer.TeamColor.Color) or Library.color
            elseif lines[i] then
                lines[i].Visible = false
            end
        end
    end)
end

function Library.Hook(target)
    local function process(char)
        if not char then return end
        task.defer(function()
            char:WaitForChild("HumanoidRootPart", 5)
            if not table.find(Library.Targets, char) then
                table.insert(Library.Targets, char)
                drawSkeleton(char)
            end
        end)
    end

    if typeof(target) == "Instance" then
        if target:IsA("Player") then
            target.CharacterAdded:Connect(process)
            process(target.Character)
        elseif target:IsA("Model") then
            process(target)
        end
    end
end

return Library
