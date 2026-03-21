-- [ Oblivium 3D Box Library ]
-- Draws a wireframe 3D box using Drawing lines.
--
-- USAGE:
--   local box = ChamsBox.new(x, y, z)                          -- fixed size, tracks nothing
--   local box = ChamsBox.new(x, y, z, somePart)                -- tracks a BasePart
--   local box = ChamsBox.new(x, y, z, Vector3.new(0, 5, 0))    -- tracks a fixed world position
--   local box = ChamsBox.new(x, y, z, function() return cf end) -- tracks a dynamic CFrame
--
--   box.Color     = Color3.fromRGB(255, 0, 0)
--   box.Thickness = 1
--   box.Enabled   = true
--   box:Destroy()

local ChamsBox = {}
ChamsBox.__index = ChamsBox

local RunService = game:GetService('RunService')
local Camera     = workspace.CurrentCamera

-- Half-extents define the box size around the origin/part
-- CORNERS: 8 points of a unit box scaled by (x, y, z)
local function buildCorners(x, y, z)
    return {
        Vector3.new(-x,  y, -z),
        Vector3.new( x,  y, -z),
        Vector3.new( x, -y, -z),
        Vector3.new(-x, -y, -z),
        Vector3.new(-x,  y,  z),
        Vector3.new( x,  y,  z),
        Vector3.new( x, -y,  z),
        Vector3.new(-x, -y,  z),
    }
end

local EDGES = {
    {1,2},{2,3},{3,4},{4,1}, -- front face
    {5,6},{6,7},{7,8},{8,5}, -- back face
    {1,5},{2,6},{3,7},{4,8}, -- connecting edges
}

local function newLine()
    local l        = Drawing.new('Line')
    l.Thickness    = 1
    l.Color        = Color3.fromRGB(255, 0, 0)
    l.Visible      = false
    l.ZIndex       = 5
    return l
end

local function worldToScreen(pos)
    local v3, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v3.X, v3.Y), onScreen, v3.Z
end

-- Resolve the tracking target each frame into a CFrame
local function resolveCFrame(target)
    if target == nil then
        return CFrame.new(0, 0, 0)
    elseif typeof(target) == 'Vector3' then
        return CFrame.new(target)
    elseif typeof(target) == 'CFrame' then
        return target
    elseif typeof(target) == 'Instance' and target:IsA('BasePart') then
        return target.CFrame
    elseif type(target) == 'function' then
        local ok, result = pcall(target)
        if ok and result then return result end
    end
    return CFrame.new(0, 0, 0)
end

--[[
    ChamsBox.new(x, y, z [, target])
    x, y, z  : half-extents of the box (studs from center)
    target   : optional — BasePart | Vector3 | CFrame | function()->CFrame
               if nil, box sits at world origin (0,0,0)
]]
function ChamsBox.new(x, y, z, target)
    local self = setmetatable({}, ChamsBox)

    self.Enabled   = true
    self.Color     = Color3.fromRGB(255, 0, 0)
    self.Thickness = 1
    self._corners  = buildCorners(x, y, z)
    self._target   = target
    self._lines    = {}
    self._dead     = false

    for i = 1, #EDGES do
        self._lines[i] = newLine()
    end

    self._conn = RunService.RenderStepped:Connect(function()
        self:_update()
    end)

    return self
end

function ChamsBox:_update()
    if self._dead then return end

    if not self.Enabled then
        for _, l in ipairs(self._lines) do l.Visible = false end
        return
    end

    local cf = resolveCFrame(self._target)

    -- Project all 8 corners into screen space
    local screenPts  = {}
    local allVisible = true

    for i, offset in ipairs(self._corners) do
        local worldPos         = cf:PointToWorldSpace(offset)
        local screen, onScreen, depth = worldToScreen(worldPos)
        screenPts[i] = screen
        if not onScreen or depth <= 0 then
            allVisible = false
        end
    end

    for i, edge in ipairs(EDGES) do
        local l = self._lines[i]
        if allVisible then
            l.From      = screenPts[edge[1]]
            l.To        = screenPts[edge[2]]
            l.Color     = self.Color
            l.Thickness = self.Thickness
            l.Visible   = true
        else
            l.Visible = false
        end
    end
end

function ChamsBox:SetTarget(target)
    self._target = target
end

function ChamsBox:SetSize(x, y, z)
    self._corners = buildCorners(x, y, z)
end

function ChamsBox:Destroy()
    self._dead = true
    if self._conn then self._conn:Disconnect() end
    for _, l in ipairs(self._lines) do l:Remove() end
end

return ChamsBox
