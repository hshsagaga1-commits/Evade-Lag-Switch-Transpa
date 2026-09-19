-- Evade Lag Switch + Transparency
-- Original lag switch: justmoon56 / RawScripts
-- Mobile transparency + drag + position lock layer.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local ORIGINAL_URL = "https://rawscripts.net/raw/Universal-Script-Lag-Switch-193057"
local GUI_NAME = "LagSwitchTransparencyController"
local GHOST_VISIBILITY = 10
local DRAG_THRESHOLD = 6

local function uiParent()
    if type(gethui) == "function" then
        local ok, value = pcall(gethui)
        if ok and value then
            return value
        end
    end
    return CoreGui
end

local parent = uiParent()

pcall(function()
    local oldGui = parent:FindFirstChild(GUI_NAME)
    if oldGui then
        oldGui:Destroy()
    end
end)

-- Snapshot existing UI so we only touch UI created by the lag-switch loader.
local roots = {}
local rootSeen = {}

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

-- Controller UI.
local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 2147483000
gui.Parent = parent

local open = Instance.new("TextButton")
open.Name = "TransparencyButton"
open.Size = UDim2.fromOffset(70, 36)
open.Position = UDim2.new(0, 12, 0.55, 0)
open.BackgroundTransparency = 0.18
open.Text = "◐ 100"
open.TextScaled = true
open.Active = true
open.Parent = gui
Instance.new("UICorner", open).CornerRadius = UDim.new(0, 9)

local panel = Instance.new("Frame")
panel.Name = "TransparencyPanel"
panel.Size = UDim2.fromOffset(286, 146)
panel.Position = UDim2.new(0.5, -143, 0.5, -73)
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
hint.Position = UDim2.fromOffset(10, 112)
hint.Text = "Arraste ◐ • X = aplicar"
hint.TextScaled = true
hint.Parent = panel

local current = 100
local tracked = setmetatable({}, {__mode = "k"})
local original = setmetatable({}, {__mode = "k"})
local writing = setmetatable({}, {__mode = "k"})
local propertyConnections = {}

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
    return obj == gui or (obj and obj:IsDescendantOf(gui))
end

local function visual(obj)
    return obj and (obj:IsA("GuiObject") or obj:IsA("UIStroke"))
end

local function fade(base, visibility)
    local hidden = 1 - math.clamp(visibility, 0, 100) / 100
    return base + (1 - base) * hidden
end

local function writeProperty(obj, name, value)
    local flags = writing[obj]
    if not flags then
        flags = {}
        writing[obj] = flags
    end

    flags[name] = true
    pcall(function()
        obj[name] = value
    end)
    flags[name] = nil
end

local function applyObject(obj, visibility)
    local p = original[obj]
    if not p or not obj.Parent then
        return
    end

    for name, base in pairs(p) do
        writeProperty(obj, name, fade(base, visibility))
    end
end

local function remember(obj)
    if not visual(obj) or ours(obj) then
        return
    end

    tracked[obj] = true
    if original[obj] then
        applyObject(obj, current)
        return
    end

    local p = {}
    original[obj] = p

    for _, name in ipairs(props) do
        local ok, value = pcall(function()
            return obj[name]
        end)

        if ok and type(value) == "number" then
            p[name] = value

            local signalOk, signal = pcall(function()
                return obj:GetPropertyChangedSignal(name)
            end)

            if signalOk and signal then
                propertyConnections[#propertyConnections + 1] = signal:Connect(function()
                    local flags = writing[obj]
                    if flags and flags[name] then
                        return
                    end

                    local readOk, newBase = pcall(function()
                        return obj[name]
                    end)

                    if readOk and type(newBase) == "number" then
                        p[name] = newBase

                        if current < 100 then
                            writeProperty(obj, name, fade(newBase, current))
                        end
                    end
                end)
            end
        end
    end

    applyObject(obj, current)
end

local openBaseBg = open.BackgroundTransparency
local openBaseText = open.TextTransparency

local function setOpenVisibility(value)
    -- The transparency control stays fully visible at every non-zero level.
    -- At zero it becomes a 10%-visible "ghost" so it can always be recovered.
    if value == 0 then
        open.BackgroundTransparency = fade(openBaseBg, GHOST_VISIBILITY)
        open.TextTransparency = fade(openBaseText, GHOST_VISIBILITY)
    else
        open.BackgroundTransparency = openBaseBg
        open.TextTransparency = openBaseText
    end
end

local function apply(value)
    value = math.clamp(math.floor(value + 0.5), 0, 100)
    current = value

    for obj in pairs(tracked) do
        if obj and obj.Parent and not ours(obj) then
            applyObject(obj, value)
        end
    end

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

-- Slider drag.
local sliderDragging = false

track.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
        setFromX(input.Position.X)
    end
end)

knob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
        setFromX(input.Position.X)
    end
end)

UIS.InputChanged:Connect(function(input)
    if sliderDragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        setFromX(input.Position.X)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
    end
end)

-- Custom mobile drag for the transparency button.
local draggingOpen = false
local openMoved = false
local openStartPointer
local openStartPosition

local function pointer2(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

open.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingOpen = true
        openMoved = false
        openStartPointer = pointer2(input)
        openStartPosition = open.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not draggingOpen then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.Touch
        and input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end

    local delta = pointer2(input) - openStartPointer

    if delta.Magnitude >= DRAG_THRESHOLD then
        openMoved = true
    end

    if openMoved then
        open.Position = UDim2.new(
            openStartPosition.X.Scale,
            openStartPosition.X.Offset + delta.X,
            openStartPosition.Y.Scale,
            openStartPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if not draggingOpen then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.Touch
        and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end

    draggingOpen = false

    if not openMoved then
        if panel.Visible then
            panel.Visible = false
            setOpenVisibility(current)
        else
            -- Always readable while editing, even if lag UI is at 0.
            setOpenVisibility(100)
            panel.Visible = true
        end
    end
end)

close.MouseButton1Click:Connect(function()
    apply(current)
    panel.Visible = false
end)

updateSlider()
setOpenVisibility(current)

local function showError(msg)
    setOpenVisibility(100)
    open.Text = "◐ ERR"
    title.Text = "Erro no Lag Switch"
    hint.Text = tostring(msg):sub(1, 150)
    panel.Visible = true
end

-- Run the untouched original lag-switch script.
local okDownload, body = pcall(function()
    return game:HttpGet(ORIGINAL_URL)
end)

if not okDownload then
    showError(body)
    return
end

local chunk, compileError = loadstring(body)
if not chunk then
    showError(compileError)
    return
end

local trace = (debug and debug.traceback) or function(err)
    return tostring(err)
end

local okRun, runtimeError = xpcall(chunk, trace)

-- Give asynchronously-created UI a short bounded window to appear.
task.wait(1.25)

-- Find new ScreenGuis created by the lag-switch script and scope all later
-- transparency tracking to those UIs only.
local lagScopes = {}
local lagScopeSeen = {}

local function addLagScope(scope)
    if scope and not lagScopeSeen[scope] and not ours(scope) then
        lagScopeSeen[scope] = true
        lagScopes[#lagScopes + 1] = scope
    end
end

for _, root in ipairs(roots) do
    pcall(function()
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("ScreenGui") and not baseline[obj] and not ours(obj) then
                addLagScope(obj)
            end
        end
    end)
end

-- Fallback for executors that parent GuiObjects into an existing ScreenGui.
if #lagScopes == 0 then
    for _, root in ipairs(roots) do
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if not baseline[obj] and visual(obj) and not ours(obj) then
                    local ancestor = obj:FindFirstAncestorWhichIsA("ScreenGui")
                    if ancestor and not baseline[ancestor] then
                        addLagScope(ancestor)
                    end
                end
            end
        end)
    end
end

local scopeConnections = {}

local function trackScope(scope)
    for _, obj in ipairs(scope:GetDescendants()) do
        if visual(obj) then
            remember(obj)
        end
    end

    scopeConnections[#scopeConnections + 1] = scope.DescendantAdded:Connect(function(obj)
        if visual(obj) then
            remember(obj)
        end
    end)
end

for _, scope in ipairs(lagScopes) do
    trackScope(scope)
end

-- Locate the actual lag-switch window by its visible title.
local function getText(obj)
    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
        return nil
    end

    local ok, value = pcall(function()
        return obj.Text
    end)

    if ok and type(value) == "string" then
        return string.upper(value)
    end

    return nil
end

local function findLagWindow()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local viewportArea = math.max(viewport.X * viewport.Y, 1)

    for _, scope in ipairs(lagScopes) do
        for _, obj in ipairs(scope:GetDescendants()) do
            local text = getText(obj)

            if text and string.find(text, "FREEZE NOW", 1, true) then
                local cursor = obj
                local best

                while cursor and cursor ~= scope do
                    if cursor:IsA("GuiObject") then
                        local size = cursor.AbsoluteSize
                        local area = size.X * size.Y

                        if size.X >= 180 and size.Y >= 60 and area < viewportArea * 0.55 then
                            best = cursor
                        end
                    end

                    cursor = cursor.Parent
                end

                if best then
                    return best
                end

                local parentFrame = obj:FindFirstAncestorWhichIsA("Frame")
                if parentFrame then
                    return parentFrame
                end
            end
        end
    end

    return nil
end

local lagWindow = findLagWindow()

if lagWindow then
    lagWindow.Active = true

    local positionLocked = true
    local lockedPosition = lagWindow.Position
    local writingPosition = false

    local lockButton = Instance.new("TextButton")
    lockButton.Name = "LagSwitchLockButton"
    lockButton.Size = UDim2.fromOffset(32, 32)
    lockButton.Position = UDim2.new(1, -38, 1, -38)
    lockButton.BackgroundTransparency = 0.18
    lockButton.Text = "🔒"
    lockButton.TextScaled = true
    lockButton.ZIndex = math.max(lagWindow.ZIndex + 20, 20)
    lockButton.Parent = lagWindow

    local lockCorner = Instance.new("UICorner")
    lockCorner.CornerRadius = UDim.new(0, 8)
    lockCorner.Parent = lockButton

    local lockStroke = Instance.new("UIStroke")
    lockStroke.Thickness = 1
    lockStroke.Transparency = 0.15
    lockStroke.Parent = lockButton

    remember(lockButton)
    remember(lockStroke)

    -- Enforce the lock even if the original script has its own drag logic.
    lagWindow:GetPropertyChangedSignal("Position"):Connect(function()
        if writingPosition then
            return
        end

        if positionLocked then
            writingPosition = true
            lagWindow.Position = lockedPosition
            writingPosition = false
        else
            lockedPosition = lagWindow.Position
        end
    end)

    lockButton.MouseButton1Click:Connect(function()
        positionLocked = not positionLocked

        if positionLocked then
            lockedPosition = lagWindow.Position
            lockButton.Text = "🔒"
        else
            lockButton.Text = "🔓"
        end
    end)

    -- Add touch/mouse dragging to the original lag-switch window.
    local lagDragging = false
    local lagMoved = false
    local lagStartPointer
    local lagStartPosition

    lagWindow.InputBegan:Connect(function(input)
        if positionLocked then
            return
        end

        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            lagDragging = true
            lagMoved = false
            lagStartPointer = pointer2(input)
            lagStartPosition = lagWindow.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not lagDragging or positionLocked then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = pointer2(input) - lagStartPointer

        if delta.Magnitude >= DRAG_THRESHOLD then
            lagMoved = true
        end

        if lagMoved then
            writingPosition = true
            lagWindow.Position = UDim2.new(
                lagStartPosition.X.Scale,
                lagStartPosition.X.Offset + delta.X,
                lagStartPosition.Y.Scale,
                lagStartPosition.Y.Offset + delta.Y
            )
            lockedPosition = lagWindow.Position
            writingPosition = false
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            lagDragging = false
        end
    end)
end

if not okRun then
    showError(runtimeError)
end
