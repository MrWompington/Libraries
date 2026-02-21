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
    local frame = Instance.new("Frame")
    frame.BorderSizePixel = 0
    frame.BackgroundColor3 = Library.color
    frame.Visible = false
    frame.Parent = ESPScreen
    return frame
end

local function getJoints(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.RigType == Enum.HumanoidRigType.R15 then
        return {
            {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
            {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
        }
    else
        return {
            {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
            {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
        }
    end
end

local function drawSkeleton(obj)
    if not obj or not obj:IsA("Model") then return end
    local lines = {}
    local connection

    connection = RunService.RenderStepped:Connect(function()
        if not obj or not obj.Parent or not Library.enabled or not table.find(Library.Targets, obj) then
            for _, line in pairs(lines) do line:Destroy() end
            connection:Disconnect()
            return
        end

        local isPlayer = Players:GetPlayerFromCharacter(obj)
        if Library.teamcheck and isPlayer and isPlayer.Team == Players.LocalPlayer.Team then
            for _, line in pairs(lines) do line.Visible = false end
            return
        end

        local joints = getJoints(obj)
        for i, joint in pairs(joints) do
            local partA, partB = obj:FindFirstChild(joint[1]), obj:FindFirstChild(joint[2])
            if partA and partB then
                local posA, onScreenA = Camera:WorldToViewportPoint(partA.Position)
                local posB, onScreenB = Camera:WorldToViewportPoint(partB.Position)

                if onScreenA and onScreenB then
                    local line = lines[i] or createLine()
                    lines[i] = line
                    
                    local dist = (Vector2.new(posA.X, posA.Y) - Vector2.new(posB.X, posB.Y))
                    line.Visible = true
                    line.Size = UDim2.new(0, dist.Magnitude, 0, Library.thickness)
                    line.Position = UDim2.new(0, posA.X + (posB.X - posA.X) / 2, 0, posA.Y + (posB.Y - posA.Y) / 2)
                    line.Rotation = math.deg(math.atan2(dist.Y, dist.X))
                    line.BackgroundColor3 = Library.color
                elseif lines[i] then
                    lines[i].Visible = false
                end
            end
        end
    end)
end

function Library.Hook(target)
    if typeof(target) == "Instance" then
        if target:IsA("Player") then
            target.CharacterAppearanceLoaded:Connect(function(char)
                if not table.find(Library.Targets, char) then
                    table.insert(Library.Targets, char)
                    drawSkeleton(char)
                end
            end)
            if target.Character then
                if not table.find(Library.Targets, target.Character) then
                    table.insert(Library.Targets, target.Character)
                    drawSkeleton(target.Character)
                end
            end
        elseif target:IsA("Model") then
            if not table.find(Library.Targets, target) then
                table.insert(Library.Targets, target)
                drawSkeleton(target)
            end
        end
    end
end

return Library
