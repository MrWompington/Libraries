local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera

local ui
if gethui then ui = gethui() else ui = Players.LocalPlayer:WaitForChild("PlayerGui") end
if ui:FindFirstChild("Box_ESP") then ui.Box_ESP:Destroy() end

local ESPScreen = Instance.new("ScreenGui")
ESPScreen.Name = "Box_ESP"
ESPScreen.IgnoreGuiInset = true
ESPScreen.Parent = ui

local Library = {
    Enabled    = false,
    BoxMode    = "Corners",
    CornerSize = 0.2,
    BoxColor   = Color3.fromRGB(0, 255, 0),
    HealthBar  = true,
    Flags      = true,
    TeamCheck  = false,
    Targets    = {},
}

local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function newBox()
    local box = {}

    box.Main = create("Frame", {
        BackgroundTransparency = 1,
        Visible = false,
        Parent  = ESPScreen,
    })

    box.Outline = create("UIStroke", {
        Color     = Library.BoxColor,
        Thickness = 1.5,
        Parent    = box.Main,
        Enabled   = false,
    })

    box.Corners = {}
    for i = 1, 8 do
        box.Corners[i] = create("Frame", {
            BackgroundColor3 = Library.BoxColor,
            BorderSizePixel  = 0,
            Visible          = false,
            Parent           = box.Main,
        })
    end

    box.HealthBarBG = create("Frame", {
        BackgroundColor3    = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel     = 0,
        Visible             = false,
        Parent              = ESPScreen,
    })

    box.HealthBarFill = create("Frame", {
        BorderSizePixel = 0,
        Visible         = false,
        Parent          = box.HealthBarBG,
    })

    box.InfoFlags = create("TextLabel", {
        BackgroundTransparency = 1,
        Font                   = Enum.Font.Code,
        TextColor3             = Color3.new(1, 1, 1),
        TextStrokeTransparency = 0,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextYAlignment         = Enum.TextYAlignment.Top,
        Visible                = false,
        Parent                 = ESPScreen,
    })

    return box
end

local function hideBox(box)
    box.Main.Visible        = false
    box.HealthBarBG.Visible  = false
    box.HealthBarFill.Visible = false
    box.InfoFlags.Visible   = false
end

local function destroyBox(box)
    box.Main:Destroy()
    box.HealthBarBG:Destroy()
    box.InfoFlags:Destroy()
end

local function screenPos(v3)
    local p = Camera:WorldToViewportPoint(v3)
    return Vector2.new(p.X, p.Y), p.Z > 0
end

local function updateBox(box, obj)
    local hum      = obj:FindFirstChildOfClass("Humanoid")
    local root     = obj:FindFirstChild("HumanoidRootPart")
    local isPlayer = Players:GetPlayerFromCharacter(obj)

    if not root or not hum or hum.Health <= 0
    or (Library.TeamCheck and isPlayer and isPlayer.Team == Players.LocalPlayer.Team) then
        hideBox(box)
        return
    end

    local _, onScreen = screenPos(root.Position)
    if not onScreen then
        hideBox(box)
        return
    end

    local cf = root.CFrame
    local p1, _ = screenPos((cf * CFrame.new(-2,  3, 0)).p)
    local p2, _ = screenPos((cf * CFrame.new( 2,  3, 0)).p)
    local p3, _ = screenPos((cf * CFrame.new(-2, -3, 0)).p)
    local p4, _ = screenPos((cf * CFrame.new( 2, -3, 0)).p)

    local minX = math.min(p1.X, p2.X, p3.X, p4.X)
    local minY = math.min(p1.Y, p2.Y, p3.Y, p4.Y)
    local maxX = math.max(p1.X, p2.X, p3.X, p4.X)
    local maxY = math.max(p1.Y, p2.Y, p3.Y, p4.Y)
    local w, h = maxX - minX, maxY - minY

    -- Main frame
    box.Main.Position = UDim2.new(0, minX, 0, minY)
    box.Main.Size     = UDim2.new(0, w, 0, h)
    box.Main.Visible  = true

    -- Box mode
    if Library.BoxMode == "Box" then
        box.Outline.Enabled = true
        box.Outline.Color   = Library.BoxColor
        for _, c in pairs(box.Corners) do c.Visible = false end
    else
        box.Outline.Enabled = false
        local cl, t = math.max(w * Library.CornerSize, 4), 1.5
        local layout = {
            {UDim2.new(0,cl,0,t),  UDim2.new(0,0,0,0)},
            {UDim2.new(0,t,0,cl),  UDim2.new(0,0,0,0)},
            {UDim2.new(0,cl,0,t),  UDim2.new(1,-cl,0,0)},
            {UDim2.new(0,t,0,cl),  UDim2.new(1,-t,0,0)},
            {UDim2.new(0,cl,0,t),  UDim2.new(0,0,1,-t)},
            {UDim2.new(0,t,0,cl),  UDim2.new(0,0,1,-cl)},
            {UDim2.new(0,cl,0,t),  UDim2.new(1,-cl,1,-t)},
            {UDim2.new(0,t,0,cl),  UDim2.new(1,-t,1,-cl)},
        }
        for i, c in pairs(box.Corners) do
            c.Size              = layout[i][1]
            c.Position          = layout[i][2]
            c.BackgroundColor3  = Library.BoxColor
            c.Visible           = true
        end
    end

    -- Health bar
    if Library.HealthBar then
        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        box.HealthBarBG.Position  = UDim2.new(0, minX - 6, 0, minY)
        box.HealthBarBG.Size      = UDim2.new(0, 3, 0, h)
        box.HealthBarBG.Visible   = true
        box.HealthBarFill.BackgroundColor3 = Color3.fromHSV(pct * 0.3, 1, 1)
        box.HealthBarFill.Size    = UDim2.new(1, 0, pct, 0)
        box.HealthBarFill.Position = UDim2.new(0, 0, 1 - pct, 0)
        box.HealthBarFill.Visible = true
    else
        box.HealthBarBG.Visible   = false
        box.HealthBarFill.Visible = false
    end

    -- Flags
    if Library.Flags then
        box.InfoFlags.TextSize = math.clamp(h * 0.15, 10, 14)
        box.InfoFlags.Position = UDim2.new(0, maxX + 4, 0, minY)
        box.InfoFlags.Text     = string.format(
            "%s\n%d HP",
            (isPlayer and isPlayer.Name or obj.Name),
            math.floor(hum.Health)
        )
        box.InfoFlags.Visible = true
    else
        box.InfoFlags.Visible = false
    end
end

-- Central RenderStepped — one loop, no per-target connections
RunService.RenderStepped:Connect(function()
    for obj, box in pairs(Library._boxes) do
        if not obj or not obj.Parent then
            destroyBox(box)
            Library._boxes[obj] = nil
            local idx = table.find(Library.Targets, obj)
            if idx then table.remove(Library.Targets, idx) end
        elseif not Library.Enabled then
            hideBox(box)
        else
            updateBox(box, obj)
        end
    end
end)

Library._boxes = {}

function Library.Hook(target)
    if typeof(target) ~= "Instance" then return end

    if target:IsA("Player") then
        local function hookChar(char)
            if not table.find(Library.Targets, char) then
                table.insert(Library.Targets, char)
                Library._boxes[char] = newBox()
            end
        end
        target.CharacterAppearanceLoaded:Connect(hookChar)
        if target.Character then hookChar(target.Character) end

    elseif target:IsA("Model") then
        if not table.find(Library.Targets, target) then
            table.insert(Library.Targets, target)
            Library._boxes[target] = newBox()
        end
    end
end

return Library
