local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local ui;
if gethui then ui = gethui() else ui = Players.LocalPlayer:WaitForChild("PlayerGui") end

if ui:FindFirstChild("Box_ESP") then ui.Box_ESP:Destroy() end

local ESPScreen = Instance.new("ScreenGui")
ESPScreen.Name = "Box_ESP"
ESPScreen.IgnoreGuiInset = true
ESPScreen.Parent = ui

local Library = {
    Enabled = true,
    BoxMode = "Corners",
    CornerSize = 0.2,
    BoxColor = Color3.fromRGB(0, 255, 0),
    HealthBar = true,
    Flags = true,
    TeamCheck = false,
    Targets = {}
}

local function create(class, props)
    local obj = Instance.new(class)
    for i, v in pairs(props) do obj[i] = v end
    return obj
end

local function drawBox(obj)
    local box = {}
    box.Main = create("Frame", {BackgroundTransparency = 1, Visible = false, Parent = ESPScreen})
    box.Outline = create("UIStroke", {Color = Library.BoxColor, Thickness = 1.5, Parent = box.Main, Enabled = false})
    box.Corners = {}
    for i = 1, 8 do
        box.Corners[i] = create("Frame", {BackgroundColor3 = Library.BoxColor, BorderSizePixel = 0, Visible = false, Parent = box.Main})
    end
    box.HealthBarBG = create("Frame", {BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, Parent = ESPScreen})
    box.HealthBar = create("Frame", {BorderSizePixel = 0, Visible = false, Parent = box.HealthBarBG})
    box.InfoFlags = create("TextLabel", {BackgroundTransparency = 1, Font = Enum.Font.Code, TextColor3 = Color3.new(1,1,1), TextStrokeTransparency = 0, TextXAlignment = "Left", TextYAlignment = "Top", Visible = false, Parent = ESPScreen})

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not obj or not obj.Parent or not Library.Enabled or not table.find(Library.Targets, obj) then
            box.Main:Destroy(); box.HealthBarBG:Destroy(); box.InfoFlags:Destroy()
            connection:Disconnect()
            return
        end

        local hum = obj:FindFirstChildOfClass("Humanoid")
        local root = obj:FindFirstChild("HumanoidRootPart")
        local isPlayer = Players:GetPlayerFromCharacter(obj)

        if not root or not hum or hum.Health <= 0 or (Library.TeamCheck and isPlayer and isPlayer.Team == Players.LocalPlayer.Team) then
            box.Main.Visible = false; box.HealthBarBG.Visible = false; box.InfoFlags.Visible = false
            return
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            box.Main.Visible = false; box.HealthBarBG.Visible = false; box.InfoFlags.Visible = false
            return
        end

        local cf = root.CFrame
        local size = Vector3.new(4, 6, 0)
        local function getScreenPos(v3)
            local p = Camera:WorldToViewportPoint(v3)
            return Vector2.new(p.X, p.Y)
        end

        local corners = {
            getScreenPos((cf * CFrame.new(-2, 3, 0)).p),
            getScreenPos((cf * CFrame.new(2, 3, 0)).p),
            getScreenPos((cf * CFrame.new(-2, -3, 0)).p),
            getScreenPos((cf * CFrame.new(2, -3, 0)).p)
        }

        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        for _, v in pairs(corners) do
            minX = math.min(minX, v.X); minY = math.min(minY, v.Y)
            maxX = math.max(maxX, v.X); maxY = math.max(maxY, v.Y)
        end

        local w, h = maxX - minX, maxY - minY
        box.Main.Position = UDim2.new(0, minX, 0, minY)
        box.Main.Size = UDim2.new(0, w, 0, h)
        box.Main.Visible = true

        if Library.BoxMode == "Box" then
            box.Outline.Enabled = true
            box.Outline.Color = Library.BoxColor
            for _, v in pairs(box.Corners) do v.Visible = false end
        else
            box.Outline.Enabled = false
            local cl, t = w * Library.CornerSize, 1.5
            box.Corners[1].Size, box.Corners[1].Position = UDim2.new(0,cl,0,t), UDim2.new(0,0,0,0)
            box.Corners[2].Size, box.Corners[2].Position = UDim2.new(0,t,0,cl), UDim2.new(0,0,0,0)
            box.Corners[3].Size, box.Corners[3].Position = UDim2.new(0,cl,0,t), UDim2.new(1,-cl,0,0)
            box.Corners[4].Size, box.Corners[4].Position = UDim2.new(0,t,0,cl), UDim2.new(1,-t,0,0)
            box.Corners[5].Size, box.Corners[5].Position = UDim2.new(0,cl,0,t), UDim2.new(0,0,1,-t)
            box.Corners[6].Size, box.Corners[6].Position = UDim2.new(0,t,0,cl), UDim2.new(0,0,1,-cl)
            box.Corners[7].Size, box.Corners[7].Position = UDim2.new(0,cl,0,t), UDim2.new(1,-cl,1,-t)
            box.Corners[8].Size, box.Corners[8].Position = UDim2.new(0,t,0,cl), UDim2.new(1,-t,1,-cl)
            for _, v in pairs(box.Corners) do v.Visible = true; v.BackgroundColor3 = Library.BoxColor end
        end

        if Library.HealthBar then
            local pct = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
            box.HealthBarBG.Visible = true
            box.HealthBarBG.Position = UDim2.new(0, minX-6, 0, minY)
            box.HealthBarBG.Size = UDim2.new(0, 3, 0, h)
            box.HealthBar.Visible = true
            box.HealthBar.BackgroundColor3 = Color3.fromHSV(pct*0.3, 1, 1)
            box.HealthBar.Size = UDim2.new(1, 0, pct, 0)
            box.HealthBar.Position = UDim2.new(0, 0, 1-pct, 0)
        end

        if Library.Flags then
            box.InfoFlags.Visible = true
            box.InfoFlags.TextSize = math.clamp(h*0.15, 10, 14)
            box.InfoFlags.Position = UDim2.new(0, maxX+4, 0, minY)
            box.InfoFlags.Text = string.format("%s\n%d HP", (isPlayer and isPlayer.Name or obj.Name), math.floor(hum.Health))
        end
    end)
end

function Library.Hook(target)
    if typeof(target) == "Instance" then
        if target:IsA("Player") then
            target.CharacterAppearanceLoaded:Connect(function(char)
                if not table.find(Library.Targets, char) then
                    table.insert(Library.Targets, char)
                    drawBox(char)
                end
            end)
            if target.Character then
                if not table.find(Library.Targets, target.Character) then
                    table.insert(Library.Targets, target.Character)
                    drawBox(target.Character)
                end
            end
        elseif target:IsA("Model") then
            if not table.find(Library.Targets, target) then
                table.insert(Library.Targets, target)
                drawBox(target)
            end
        end
    end
end

return Library
