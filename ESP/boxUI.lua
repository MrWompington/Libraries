local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Detect UI Container
local ui;
if gethui then ui = gethui() else ui = Players.LocalPlayer:WaitForChild("PlayerGui") end

local ESPScreen = Instance.new("ScreenGui")
ESPScreen.Name = "\0"
ESPScreen.IgnoreGuiInset = true
ESPScreen.Parent = ui

local Settings = {
    Enabled = true,
    BoxMode = "Corners", -- "Box" or "Corners"
    CornerSize = 0.2,
    BoxColor = Color3.fromRGB(0, 255, 0),
    HealthBar = true,
    Flags = true
}

local ESP_Objects = {}

-- Utility to create UI elements
local function create(class, props)
    local obj = Instance.new(class)
    for i, v in pairs(props) do obj[i] = v end
    return obj
end

local function createESP(player)
    if player == Players.LocalPlayer then return end

    local box = {}
    
    -- Main Container Frame
    box.Main = create("Frame", {
        BackgroundTransparency = 1,
        Visible = false,
        Parent = ESPScreen
    })

    -- Box Outline (Used for "Box" mode)
    box.Outline = create("UIStroke", {
        Color = Settings.BoxColor,
        Thickness = 1.5,
        Parent = box.Main,
        Enabled = false
    })

    -- Corner Frames
    box.Corners = {}
    for i = 1, 8 do
        box.Corners[i] = create("Frame", {
            BackgroundColor3 = Settings.BoxColor,
            BorderSizePixel = 0,
            Visible = false,
            Parent = box.Main
        })
    end

    -- Health Bar
    box.HealthBarBG = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Visible = false,
        Parent = ESPScreen
    })
    box.HealthBar = create("Frame", {
        BorderSizePixel = 0,
        Visible = false,
        Parent = box.HealthBarBG
    })

    -- Flags
    box.InfoFlags = create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextStrokeTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Visible = false,
        Parent = ESPScreen
    })

    box.Connection = RunService.RenderStepped:Connect(function()
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not root or not hum or hum.Health <= 0 or not Settings.Enabled then
            box.Main.Visible = false
            box.HealthBarBG.Visible = false
            box.InfoFlags.Visible = false
            return
        end

        local _, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            box.Main.Visible = false
            box.HealthBarBG.Visible = false
            box.InfoFlags.Visible = false
            return
        end

        -- Bounding Box Logic
        local cf = root.CFrame
        local size = Vector3.new(4, 6, 0) -- Character approximation
        local corners = {
            Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, 0)).p),
            Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, 0)).p),
            Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, 0)).p),
            Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, 0)).p)
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge

        for _, v in pairs(corners) do
            minX = math.min(minX, v.X)
            minY = math.min(minY, v.Y)
            maxX = math.max(maxX, v.X)
            maxY = math.max(maxY, v.Y)
        end

        local w, h = maxX - minX, maxY - minY
        
        -- Update Main Box
        box.Main.Position = UDim2.new(0, minX, 0, minY)
        box.Main.Size = UDim2.new(0, w, 0, h)
        box.Main.Visible = true

        if Settings.BoxMode == "Box" then
            box.Outline.Enabled = true
            box.Outline.Color = Settings.BoxColor
            for _, v in pairs(box.Corners) do v.Visible = false end
        else
            box.Outline.Enabled = false
            local cLen = w * Settings.CornerSize
            local t = 1.5 -- Thickness
            
            -- Simple logic to position 8 frames as corners
            box.Corners[1].Size = UDim2.new(0, cLen, 0, t) -- TopLeft H
            box.Corners[1].Position = UDim2.new(0, 0, 0, 0)
            box.Corners[2].Size = UDim2.new(0, t, 0, cLen) -- TopLeft V
            box.Corners[2].Position = UDim2.new(0, 0, 0, 0)
            -- ... (Rest of corners follow this pattern)
            for _, v in pairs(box.Corners) do v.Visible = true v.BackgroundColor3 = Settings.BoxColor end
        end

        -- Health Bar
        if Settings.HealthBar then
            local pct = hum.Health / hum.MaxHealth
            box.HealthBarBG.Visible = true
            box.HealthBarBG.Position = UDim2.new(0, minX - 6, 0, minY)
            box.HealthBarBG.Size = UDim2.new(0, 3, 0, h)
            
            box.HealthBar.Visible = true
            box.HealthBar.BackgroundColor3 = Color3.fromHSV(pct * 0.3, 1, 1)
            box.HealthBar.Size = UDim2.new(1, 0, pct, 0)
            box.HealthBar.Position = UDim2.new(0, 0, 1 - pct, 0)
        end

        -- Flags
        if Settings.Flags then
            local dist = (Camera.CFrame.p - root.Position).Magnitude
            box.InfoFlags.Visible = true
            box.InfoFlags.TextSize = math.clamp(h * 0.15, 10, 14)
            box.InfoFlags.Position = UDim2.new(0, maxX + 4, 0, minY)
            box.InfoFlags.Text = string.format("%s\n%d HP\n%dm", player.Name, math.floor(hum.Health), math.floor(dist))
        end
    end)

    ESP_Objects[player] = box
end


local function removeESP(player)
    local box = ESP_Objects[player]
    if not box then
        return
    end

    if box.Connection then
        box.Connection:Disconnect()
    end

    for _, line in ipairs(box.Lines) do
        line:Remove()
    end

    box.HealthBarBG:Remove()
    box.HealthBar:Remove()
    box.InfoFlags:Remove()

    ESP_Objects[player] = nil
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end
