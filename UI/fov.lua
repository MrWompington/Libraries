local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local ui
if gethui then ui = gethui() else ui = LocalPlayer:WaitForChild("PlayerGui") end
if ui:FindFirstChild("FOV_Circle") then ui.FOV_Circle:Destroy() end

local Screen = Instance.new("ScreenGui")
Screen.Name            = "FOV_Circle"
Screen.IgnoreGuiInset  = true
Screen.ResetOnSpawn    = false
Screen.Parent          = ui

-- The circle is a transparent Frame with UICorner (radius 0.5 = pill/circle)
-- and UIStroke for the visible outline ring
local Circle = Instance.new("Frame")
Circle.Name                    = "Circle"
Circle.BackgroundTransparency  = 1
Circle.BorderSizePixel         = 0
Circle.AnchorPoint             = Vector2.new(0.5, 0.5)
Circle.Visible                 = false
Circle.Parent                  = Screen

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0) -- fully round
Corner.Parent       = Circle

local Stroke = Instance.new("UIStroke")
Stroke.Thickness    = 1.5
Stroke.Color        = Color3.fromRGB(255, 255, 255)
Stroke.Transparency = 0
Stroke.Parent       = Circle

local Library = {
    enabled     = false,
    fov         = 90,       -- should match AimbotUI.fov
    color       = Color3.fromRGB(255, 255, 255),
    thickness   = 1.5,
    transparency = 0,
}

RunService.RenderStepped:Connect(function()
    if not Library.enabled then
        Circle.Visible = false
        return
    end

    local center = Camera.ViewportSize / 2

    Circle.Visible          = true
    Circle.Size             = UDim2.new(0, Library.fov * 2, 0, Library.fov * 2)
    Circle.Position         = UDim2.new(0, center.X, 0, center.Y)
    Stroke.Color            = Library.color
    Stroke.Thickness        = Library.thickness
    Stroke.Transparency     = Library.transparency
end)

-- no-op Hook stub for API consistency
function Library.Hook() end

return Library
