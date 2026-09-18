-- Evade Lag Switch + Transparency
-- Original lag switch: justmoon56 / RawScripts
-- Transparency controller added for mobile use.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local ORIGINAL_URL = "https://rawscripts.net/raw/Universal-Script-Lag-Switch-193057"
local GUI_NAME = "LagSwitchTransparencyController"
local MIN_BUTTON_VISIBILITY = 10

local function uiParent()
    if type(gethui) == "function" then
        local ok, value = pcall(gethui)
        if ok and value then return value end
    end
    return CoreGui
end

local parent = uiParent()

pcall(function()
    local old = parent:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end)

-- Capture what exists BEFORE the original lag-switch UI loads.
local roots, rootSeen = {}, {}
local function addRoot(root)
    if root and not rootSeen[root] then
        rootSeen[root] = true
        roots[#roots + 1] = root
    end
end

addRoot(parent)
addRoot(CoreGui)
if player then
    addRoot(player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5))
end

local baseline = setmetatable({}, {__mode = "k"})
for _, root in ipairs(roots) do
    pcall(function()
        for _, obj in ipairs(root:GetDescendants()) do
            baseline[obj] = true
        end
    end)
end

-- Our controller.
local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 2147483000
gui.Parent = parent

local open = Instance.new("TextButton")
open.Name = "TransparencyButton"
open.Size = UDim2.fromOffset(58, 34)
open.Position = UDim2.new(0, 12, 0.55, 0)
open.BackgroundTransparency = 0.18
open.Text = "◐ 100"
open.TextScaled = true
open.Active = true
open.Draggable = true
open.Parent = gui
Instance.new("UICorner", open).CornerRadius = UDim.new(0, 9)

local panel = Instance.new("Frame")
panel.Name = "TransparencyPanel"
panel.Size = UDim2.fromOffset(270, 136)
panel.Position = UDim2.new(0.5, -135, 0.5, -68)
panel.BackgroundTransparency = 0.12
panel.Visible = false
panel.Active = true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -55, 0, 32)
title.Position = UDim2.fromOffset(12, 5)
title.Text = "Transparência"
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 30)
close.Position = UDim2.new(1, -40, 0, 6)
close.BackgroundTransparency = 0.3
close.Text = "X"
close.TextScaled = true
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

local valueLabel = Instance.new("TextLabel")
valueLabel.BackgroundTransparency = 1
valueLabel.Size = UDim2.fromOffset(64, 26)
valueLabel.Position = UDim2.new(0.5, -32, 0, 42)
valueLabel.Text = "100%"
valueLabel.TextScaled = true
valueLabel.Parent = panel

local left = Instance.new("TextLabel")
left.BackgroundTransparency = 1
left.Size = UDim2.fromOffset(36, 20)
left.Position = UDim2.fromOffset(10, 83)
left.Text = "100"
left.TextScaled = true
left.Parent = panel

local right = Instance.new("TextLabel")
right.BackgroundTransparency = 1
right.Size = UDim2.fromOffset(25, 20)
right.Position = UDim2.new(1, -35, 0, 83)
right.Text = "0"
right.TextScaled = true
right.Parent = panel

local track = Instance.new("Frame")
track.Size = UDim2.new(1, -88, 0, 8)
track.Position = UDim2.fromOffset(46, 89)
track.BackgroundTransparency = 0.25
track.Active = true
track.Parent = panel
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(20, 20)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(0, 0, 0.5, 0)
knob.BackgroundTransparency = 0
knob.Active = true
knob.Parent = track
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -20, 0, 20)
hint.Position = UDim2.fromOffset(10, 108)
hint.Text = "X = aplicar e fechar"
hint.TextScaled = true
hint.Parent = panel

local tracked = setmetatable({}, {__mode = "k"})
local original = setmetatable({}, {__mode = "k"})

local props = {
    "BackgroundTransparency",
    "TextTransparency",
    "TextStrokeTransparency",
    "ImageTransparency",
    "ScrollBarImageTransparency",
    "GroupTransparency",
    "VideoTransparency",
    "Transparency"
}

local function ours(obj)
    return obj == gui or obj:IsDescendantOf(gui)
end

local function visual(obj)
    return obj and (obj:IsA("GuiObject") or obj:IsA("UIStroke"))
end

local function remember(obj)
    if not visual(obj) or ours(obj) then return end
    tracked[obj] = true
    if original[obj] then return end

    local p = {}
    for _, name in ipairs(props) do
        local ok, v = pcall(function() return obj[name] end)
        if ok and type(v) == "number" then
            p[name] = v
        end
    end
    original[obj] = p
end

local function fade(originalValue, visibility)
    local alpha = 1 - math.clamp(visibility, 0, 100) / 100
    return originalValue + (1 - originalValue) * alpha
end

local openBaseBg = open.BackgroundTransparency
local openBaseText = open.TextTransparency

local function setOpenVisibility(value)
    local v = math.max(MIN_BUTTON_VISIBILITY, math.clamp(value, 0, 100))
    open.BackgroundTransparency = fade(openBaseBg, v)
    open.TextTransparency = fade(openBaseText, v)
end

local current = 100

local function apply(value)
    value = math.clamp(math.floor(value + 0.5), 0, 100)

    for obj in pairs(tracked) do
        if obj and obj.Parent and not ours(obj) then
            local p = original[obj]
            if p then
                for name, base in pairs(p) do
                    pcall(function()
                        obj[name] = fade(base, value)
                    end)
                end
            end
        end
    end

    current = value
    open.Text = string.format("◐ %d", value)
    setOpenVisibility(value)
end

local function updateSlider()
    current = math.clamp(math.floor(current + 0.5), 0, 100)
    valueLabel.Text = string.format("%d%%", current)
    knob.Position = UDim2.new(1 - current / 100, 0, 0.5, 0)
end

local function setFromX(x)
    local width = math.max(track.AbsoluteSize.X, 1)
    local ratio = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
    current = math.floor((1 - ratio) * 100 + 0.5)
    updateSlider()
end

local dragging = false

track.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        setFromX(input.Position.X)
    end
end)

knob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        setFromX(input.Position.X)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        setFromX(input.Position.X)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

open.MouseButton1Click:Connect(function()
    if panel.Visible then
        panel.Visible = false
        setOpenVisibility(current)
    else
        -- Always make the editor readable when opened.
        setOpenVisibility(100)
        panel.Visible = true
    end
end)

close.MouseButton1Click:Connect(function()
    apply(current)
    panel.Visible = false
end)

updateSlider()

-- Watch only UI created while the original lag switch initializes.
local connections = {}
for _, root in ipairs(roots) do
    local ok, conn = pcall(function()
        return root.DescendantAdded:Connect(function(obj)
            if not baseline[obj] and visual(obj) and not ours(obj) then
                remember(obj)
            end
        end)
    end)
    if ok and conn then
        connections[#connections + 1] = conn
    end
end

local function stopCapture()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(connections)
end

local function showError(msg)
    setOpenVisibility(100)
    open.Text = "◐ ERR"
    title.Text = "Erro no Lag Switch"
    hint.Text = tostring(msg):sub(1, 120)
    panel.Visible = true
end

local okDownload, body = pcall(function()
    return game:HttpGet(ORIGINAL_URL)
end)

if not okDownload then
    stopCapture()
    showError(body)
    return
end

local chunk, compileError = loadstring(body)
if not chunk then
    stopCapture()
    showError(compileError)
    return
end

local trace = (debug and debug.traceback) or function(err)
    return tostring(err)
end

local okRun, runtimeError = xpcall(chunk, trace)

-- Short bounded window for lag-switch UI created asynchronously.
task.wait(1.25)

for _, root in ipairs(roots) do
    pcall(function()
        for _, obj in ipairs(root:GetDescendants()) do
            if not baseline[obj] and visual(obj) and not ours(obj) then
                remember(obj)
            end
        end
    end)
end

stopCapture()

if not okRun then
    showError(runtimeError)
end
