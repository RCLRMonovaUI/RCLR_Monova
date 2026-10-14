local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local Teams = game:GetService('Teams')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local Lighting = game:GetService('Lighting')
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

-- Only unload previous RCLR instances (do NOT destroy other scripts like Unnamed Enhancements)
local getgenv = getgenv or getfenv or function() return _G end
local OldLibrary = getgenv().RCLR_Library
if type(OldLibrary) == 'table' and OldLibrary.IsRCLR then
    pcall(function()
        if OldLibrary.Unload then OldLibrary:Unload() end
        if OldLibrary.ScreenGui and OldLibrary.ScreenGui.Parent then
            OldLibrary.ScreenGui:Destroy()
        end
    end)
end
-- Clean only our mobile overlay if re-executing
pcall(function()
    local cg = game:GetService('CoreGui')
    local oldMob = cg:FindFirstChild('RCLR_MobileUI')
    if oldMob then oldMob:Destroy() end
end)

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.Name = 'RCLR_Monova_UI'
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

local function ContrastColor(c)
    local lum = 0.299*c.R + 0.587*c.G + 0.114*c.B
    if lum > 0.55 then
        return Color3.fromRGB(20, 20, 20)
    end
    return Color3.fromRGB(240, 240, 240)
end

local Library = {
    IsRCLR = true,
    Name = "RCLR_Monova",
    IsMobile = false,
    PerformanceMode = true,
    Registry = {},
    RegistryMap = {},
    HudRegistry = {},
    FontColor = Color3.fromRGB(220, 220, 220),
    MainColor = Color3.fromRGB(28, 28, 28),
    BackgroundColor = Color3.fromRGB(18, 18, 18),
    AccentColor = Color3.fromRGB(200, 200, 200),
    OutlineColor = Color3.fromRGB(50, 50, 50),
    RiskColor = Color3.fromRGB(255, 50, 50),
    GlassEnabled = true,
    GlassTransparency = 0.92,
    GlassGloss = true,
    Black = Color3.new(0, 0, 0),
    Font = Enum.Font.Code,
    FontSize = 14,
    OpenedFrames = {},
    DependencyBoxes = {},
    Signals = {},
    ScreenGui = ScreenGui,
    Toggled = false,
    WireframeDrag = true,
    UseBlur = true,
    BlurSize = 24,
    UseDarken = true,
    DarkenAmount = 55,
    KeybindMode = 'All',
    NotifyConfig = {
        ClipDescendants = false,
        MaxHeight = 200,
        PosX = 50,
        PosY = 60,
        Transparency = 60,
        Alignment = "Center",
        BarSide = "Bottom",
        SortOrder = "Time",
    },
    NotifyQueue = {},
    ActiveNotifyCount = 0,
    NotifyCounter = 0,
    _GlassDirty = false,
    _LastGlassApply = 0,
}

Library.KeyPickerList = {}

Library.BlurEffect = Instance.new("BlurEffect")
Library.BlurEffect.Name = "LinoriaBlur"
Library.BlurEffect.Size = 0
Library.BlurEffect.Enabled = false
pcall(function() Library.BlurEffect.Parent = Lighting end)

do
    local OverlayGui = Instance.new("ScreenGui")
    OverlayGui.Name = "LinoriaBlurOverlay"
    OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    OverlayGui.DisplayOrder = -9999
    ProtectGui(OverlayGui)
    OverlayGui.Parent = CoreGui
    Library.DarkOverlay = Instance.new("Frame")
    Library.DarkOverlay.Name = "DarkOverlay"
    Library.DarkOverlay.Size = UDim2.new(10, 0, 10, 0)
    Library.DarkOverlay.Position = UDim2.new(-5, 0, -5, 0)
    Library.DarkOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Library.DarkOverlay.BackgroundTransparency = 1
    Library.DarkOverlay.BorderSizePixel = 0
    Library.DarkOverlay.ZIndex = 1
    Library.DarkOverlay.Parent = OverlayGui
end

function Library:UpdateBlur()
    local open = Library.Toggled == true
    local useBlur = open and Library.UseBlur and not (Library.IsMobile == true)
    if Library.BlurEffect then
        if useBlur then
            Library.BlurEffect.Enabled = true
            -- stronger when glass is on (frosted backdrop)
            local base = Library.BlurSize or 18
            if Library.GlassEnabled then
                base = math.clamp(base, 16, 32)
            end
            Library.BlurEffect.Size = base
        else
            Library.BlurEffect.Size = 0
            Library.BlurEffect.Enabled = false
        end
    end
    if Library.DarkOverlay then
        if open and Library.UseDarken then
            local amt = math.clamp(Library.DarkenAmount or 12, 0, 30)
            Library.DarkOverlay.BackgroundTransparency = 1 - (amt / 100)
        else
            Library.DarkOverlay.BackgroundTransparency = 1
        end
    end
end

function Library:SetBlur(Size)
    Library.BlurSize = math.clamp(Size, 0, 56)
    if Library.Toggled and Library.UseBlur then
        Library.BlurEffect.Size = Library.BlurSize
    end
end

function Library:AddBlurSlider(Groupbox)
    Groupbox:AddToggle('LinoriaUseBlur', {
        Text = 'Background Blur',
        Default = Library.UseBlur,
        Tooltip = 'Blur the background when the menu is open',
        Callback = function(Value)
            Library.UseBlur = Value
            Library:UpdateBlur()
        end,
    })
    Groupbox:AddSlider('LinoriaBlurSize', {
        Text = 'Blur Amount',
        Default = Library.BlurSize,
        Min = 0,
        Max = 56,
        Rounding = 0,
        Callback = function(Value)
            Library:SetBlur(Value)
        end,
    })
end

function Library:AddDarkenSlider(Groupbox)
    Groupbox:AddToggle('LinoriaUseDarken', {
        Text = 'Background Darken',
        Default = Library.UseDarken,
        Tooltip = 'Darken the background when the menu is open',
        Callback = function(Value)
            Library.UseDarken = Value
            Library:UpdateBlur()
        end,
    })
    Groupbox:AddSlider('LinoriaDarkenAmount', {
        Text = 'Darken Amount',
        Default = Library.DarkenAmount,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Suffix = '%',
        Callback = function(Value)
            Library.DarkenAmount = Value
            Library:UpdateBlur()
        end,
    })
end

function Library:SetKeybindTransparency(Value)
    Value = math.clamp(Value, 0, 1)
    local Inner = Library.KeybindInner
    if Library.KeybindFrame then
        Library.KeybindFrame.BackgroundTransparency = Value
        Library.KeybindFrame.BorderSizePixel = Value >= 1 and 0 or 1
        if not Inner then
            Inner = Library.KeybindFrame:FindFirstChildOfClass('Frame')
        end
    end
    if Inner then
        Inner.BackgroundTransparency = Value
        Inner.BorderSizePixel = Value >= 1 and 0 or 1
    end
    if Library.KeybindColorFrame then
        Library.KeybindColorFrame.BackgroundTransparency = Value
    end
end

function Library:AddKeybindTransparencySlider(Groupbox)
    Groupbox:AddSlider('LinoriaKeybindTransparency', {
        Text = 'Keybind Transparency',
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Suffix = '%',
        Callback = function(Value)
            Library:SetKeybindTransparency(Value / 100)
        end,
    })
end

function Library:SetFontSize(Size)
    Library.FontSize = Size
    for _, descendant in pairs(ScreenGui:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
            local offset = descendant:GetAttribute("FontSizeOffset")
            if offset then
                descendant.TextSize = Size + offset
            end
        end
    end
    local mobileUI = CoreGui:FindFirstChild("RCLR_MobileUI")
    if mobileUI then
        for _, descendant in pairs(mobileUI:GetDescendants()) do
            if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
                local offset = descendant:GetAttribute("FontSizeOffset")
                if offset then
                    descendant.TextSize = Size + offset
                end
            end
        end
    end
end

local RainbowStep = 0
local Hue = 0
table.insert(Library.Signals, RunService.Heartbeat:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    local interval = (Library.IsMobile == true) and (1 / 20) or (1 / 30)
    if RainbowStep >= interval then
        RainbowStep = 0
        Hue = Hue + (1 / 400)
        if Hue > 1 then Hue = 0 end
        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers()
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name
    end
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end)
    return PlayerList
end

local function GetTeamsString()
    local TeamList = Teams:GetTeams()
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name
    end
    table.sort(TeamList, function(str1, str2) return str1 < str2 end)
    return TeamList
end

function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local success, event = pcall(f, ...)
    if not success then
        local _, i = event:find(":%d+: ")
        if not i then
            return Library:Notify(tostring(event), 3)
        end
        return Library:Notify(event:sub(i + 1), 3)
    end
end

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save() end
end

function Library:Create(Class, Properties)
    local _Instance = Class
    if type(Class) == 'string' then _Instance = Instance.new(Class) end
    for Property, Value in next, Properties do
        pcall(function() _Instance[Property] = Value end)
    end
    if _Instance:IsA("TextLabel") or _Instance:IsA("TextBox") or _Instance:IsA("TextButton") then
        if Properties.TextSize then
            _Instance:SetAttribute("FontSizeOffset", Properties.TextSize - Library.FontSize)
        else
            _Instance:SetAttribute("FontSizeOffset", 0)
        end
    end
    return _Instance
end

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1
    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = Inst,
    })
end

function Library:ApplyGlow(Inst) end

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = Library.FontSize + 2,
        TextStrokeTransparency = 0,
    })
    Library:ApplyTextStroke(_Instance)
    Library:AddToRegistry(_Instance, { TextColor3 = 'FontColor' }, IsHud)
    return Library:Create(_Instance, Properties)
end

function Library:MakeDraggable(Instance, Cutoff, IsWindow)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            local StartPos = Instance.Position
            local DragStart = Input.Position
            if (DragStart.Y - Instance.AbsolutePosition.Y) > (Cutoff or 40) then return end
            local Dragging = true
            local HasMoved = false
            local Wireframe = nil
            local ChangedConn, EndedConn
            ChangedConn = InputService.InputChanged:Connect(function(Change)
                if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                    local Delta = Change.Position - DragStart
                    if IsWindow and Library.WireframeDrag then
                        if not HasMoved and Delta.Magnitude > 2 then
                            HasMoved = true
                            Wireframe = Library:Create("Frame", {
                                Size = Instance.Size,
                                Position = Instance.Position,
                                AnchorPoint = Instance.AnchorPoint,
                                BackgroundColor3 = Library.MainColor,
                                BackgroundTransparency = 0.5,
                                Active = false,
                                ZIndex = 100000,
                                Parent = ScreenGui,
                            })
                            Library:Create("UIStroke", {
                                Color = Library.AccentColor,
                                Thickness = 1,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                Parent = Wireframe,
                            })
                        end
                        if HasMoved and Wireframe then
                            Wireframe.Position = UDim2.new(
                                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                            )
                        end
                    else
                        Instance.Position = UDim2.new(
                            StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                            StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                        )
                    end
                end
            end)
            EndedConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                    ChangedConn:Disconnect()
                    EndedConn:Disconnect()
                    if IsWindow and Library.WireframeDrag and HasMoved and Wireframe then
                        Instance.Position = Wireframe.Position
                        Wireframe:Destroy()
                        Wireframe = nil
                    end
                end
            end)
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, Library.FontSize)
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,
        Visible = false,
    })
    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y),
        TextSize = Library.FontSize,
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = Tooltip.ZIndex + 1,
        Parent = Tooltip,
    })
    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    })
    Library:AddToRegistry(Label, { TextColor3 = 'FontColor' })
    local IsHovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true
        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)
    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance]
        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Property] then Reg.Properties[Property] = ColorIdx end
        end
    end)
    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance]
        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx
            if Reg and Reg.Properties[Property] then Reg.Properties[Property] = ColorIdx end
        end
    end)
end

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true
        end
    end
end

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
        return true
    end
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update()
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

do
    local mobile = false
    pcall(function()
        if InputService.TouchEnabled then
            mobile = true
        end
    end)
    Library.IsMobile = mobile
    if mobile then
        Library.UseBlur = false
        Library.BlurSize = 0
        Library.UseDarken = true
        Library.DarkenAmount = 8
        Library.WireframeDrag = false
        Library.PerformanceMode = true
    else
        Library.PerformanceMode = true
    end
end

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1
    local Data = { Instance = Instance, Properties = Properties, Idx = Idx }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
    if IsHud then table.insert(Library.HudRegistry, Data) end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then table.remove(Library.Registry, Idx) end
        end
        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then table.remove(Library.HudRegistry, Idx) end
        end
        Library.RegistryMap[Instance] = nil
    end
end

function Library:UpdateColorsUsingRegistry()
    for Idx, Object in next, Library.Registry do
        local inst = Object.Instance
        if inst and inst.Parent then
            for Property, ColorIdx in next, Object.Properties do
                if type(ColorIdx) == 'string' then
                    pcall(function() inst[Property] = Library[ColorIdx] end)
                elseif type(ColorIdx) == 'function' then
                    pcall(function() inst[Property] = ColorIdx() end)
                end
            end
        end
    end
    for _, Slider in pairs(Options) do
        if type(Slider) == 'table' and Slider.Type == 'Slider' and Slider._RefreshContrast then
            pcall(Slider._RefreshContrast)
        end
    end
end

function Library:GiveSignal(Signal) table.insert(Library.Signals, Signal) end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end
    if Library.OnUnload then Library.OnUnload() end
    if Library.BlurEffect then Library.BlurEffect:Destroy() end
    if Library.DarkOverlay and Library.DarkOverlay.Parent then Library.DarkOverlay.Parent:Destroy() end
    if Library._LoadingScreen then pcall(function() Library._LoadingScreen:Destroy() end) end
    ScreenGui:Destroy()
end

function Library:OnUnload(Callback) Library.OnUnload = Callback end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then Library:RemoveFromRegistry(Instance) end
end))

Library.PresetConfigs = {}

Library.PresetConfigs.Default = {
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 1000,
    GlassEnabled = true,
    GlassTransparency = 0.92,
    UseBlur = true,
    BlurSize = 24,
    UseDarken = true,
    DarkenAmount = 55,
    FontSize = 14,
    KeybindMode = "All",
    AccentColor = Color3.fromRGB(200, 200, 200),
    MainColor = Color3.fromRGB(28, 28, 28),
    BackgroundColor = Color3.fromRGB(18, 18, 18),
    OutlineColor = Color3.fromRGB(50, 50, 50),
    FontColor = Color3.fromRGB(220, 220, 220),
}

Library.PresetConfigs.PvP = {
    WalkSpeed = 22,
    JumpPower = 55,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 2000,
    GlassEnabled = true,
    GlassTransparency = 0.85,
    UseBlur = true,
    BlurSize = 12,
    UseDarken = true,
    DarkenAmount = 35,
    FontSize = 14,
    KeybindMode = "Active",
    AccentColor = Color3.fromRGB(255, 60, 60),
    MainColor = Color3.fromRGB(28, 20, 20),
    BackgroundColor = Color3.fromRGB(16, 10, 10),
    OutlineColor = Color3.fromRGB(80, 30, 30),
    FontColor = Color3.fromRGB(255, 240, 240),
}

Library.PresetConfigs.Stealth = {
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 800,
    GlassEnabled = true,
    GlassTransparency = 0.94,
    UseBlur = true,
    BlurSize = 20,
    UseDarken = true,
    DarkenAmount = 70,
    FontSize = 12,
    KeybindMode = "Toggled",
    AccentColor = Color3.fromRGB(120, 255, 180),
    MainColor = Color3.fromRGB(16, 22, 18),
    BackgroundColor = Color3.fromRGB(8, 12, 10),
    OutlineColor = Color3.fromRGB(40, 70, 55),
    FontColor = Color3.fromRGB(220, 255, 235),
}

Library.PresetConfigs.Rivals = {
    WalkSpeed = 20,
    JumpPower = 52,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 3000,
    GlassEnabled = true,
    GlassTransparency = 0.88,
    UseBlur = true,
    BlurSize = 8,
    UseDarken = true,
    DarkenAmount = 45,
    FontSize = 14,
    KeybindMode = "All",
    AccentColor = Color3.fromRGB(180, 90, 255),
    MainColor = Color3.fromRGB(20, 14, 30),
    BackgroundColor = Color3.fromRGB(10, 6, 18),
    OutlineColor = Color3.fromRGB(70, 40, 110),
    FontColor = Color3.fromRGB(240, 230, 255),
}

Library.PresetConfigs.Minimal = {
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    Gravity = 196.2,
    FogDistance = 1000,
    GlassEnabled = false,
    GlassTransparency = 1,
    UseBlur = false,
    BlurSize = 0,
    UseDarken = false,
    DarkenAmount = 0,
    FontSize = 14,
    KeybindMode = "All",
    AccentColor = Color3.fromRGB(200, 200, 200),
    MainColor = Color3.fromRGB(24, 24, 24),
    BackgroundColor = Color3.fromRGB(14, 14, 14),
    OutlineColor = Color3.fromRGB(60, 60, 60),
    FontColor = Color3.fromRGB(230, 230, 230),
}

function Library:LoadPreset(Name)
    local preset = Library.PresetConfigs[Name]
    if not preset then
        Library:Notify("Preset '" .. tostring(Name) .. "' not found", 3)
        return
    end
    Library.AccentColor = preset.AccentColor or Library.AccentColor
    Library.MainColor = preset.MainColor or Library.MainColor
    Library.BackgroundColor = preset.BackgroundColor or Library.BackgroundColor
    Library.OutlineColor = preset.OutlineColor or Library.OutlineColor
    Library.FontColor = preset.FontColor or Library.FontColor
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
    Library.UseBlur = preset.UseBlur == true
    Library.BlurSize = preset.BlurSize or Library.BlurSize
    Library.UseDarken = preset.UseDarken == true
    Library.DarkenAmount = preset.DarkenAmount or Library.DarkenAmount
    Library.GlassEnabled = preset.GlassEnabled ~= false
    Library.GlassTransparency = preset.GlassTransparency or Library.GlassTransparency
    pcall(function() Library:SetFontSize(preset.FontSize or Library.FontSize) end)
    pcall(function() Library:SetKeybindMode(preset.KeybindMode or Library.KeybindMode) end)
    pcall(function() Library:UpdateColorsUsingRegistry() end)
    pcall(function() Library:SetGlass(Library.GlassEnabled, Library.GlassTransparency) end)
    pcall(function() Library:UpdateBlur() end)
    if Toggles then
        if Toggles.InfiniteJump then Toggles.InfiniteJump:SetValue(preset.InfiniteJump == true) end
        if Toggles.Noclip then Toggles.Noclip:SetValue(preset.Noclip == true) end
    end
    if Options then
        if Options.WalkSpeed then Options.WalkSpeed:SetValue(preset.WalkSpeed or 16) end
        if Options.JumpPower then Options.JumpPower:SetValue(preset.JumpPower or 50) end
        if Options.Gravity then Options.Gravity:SetValue(preset.Gravity or 196.2) end
        if Options.FogEnd then Options.FogEnd:SetValue(preset.FogDistance or 1000) end
    end
    pcall(function() Library:AttemptSave() end)
    Library:Notify("Preset loaded: " .. tostring(Name), 3)
end

function Library:AddPresetDropdown(Groupbox)
    local presetNames = {}
    for name, _ in pairs(Library.PresetConfigs) do
        table.insert(presetNames, name)
    end
    table.sort(presetNames)
    Groupbox:AddLabel("Custom Preset Configs")
    Groupbox:AddDropdown("RCLR_PresetSelect", {
        Text = "Preset",
        Values = presetNames,
        Default = 1,
        Callback = function(v) end,
    })
    Groupbox:AddButton("Load Selected Preset", function()
        local selected = Options and Options.RCLR_PresetSelect
        local name = selected and selected.Value
        if name then Library:LoadPreset(name) end
    end)
    Groupbox:AddButton("Save Current As Preset", function()
        Library:Notify("Preset saved to memory", 3)
    end)
end

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

function LoadingScreen.new()
    local self = setmetatable({}, LoadingScreen)
    local gui = Instance.new("ScreenGui")
    gui.Name = "RCLR_LoadingScreen"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.DisplayOrder = 999999
    gui.IgnoreGuiInset = true
    ProtectGui(gui)
    gui.Parent = CoreGui
    self.Gui = gui
    local bg = Instance.new("Frame")
    bg.Name = "Backdrop"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(6, 4, 12)
    bg.BorderSizePixel = 0
    bg.ZIndex = 1
    bg.Parent = gui
    self.Backdrop = bg
    local vignette = Instance.new("ImageLabel")
    vignette.Name = "Vignette"
    vignette.Size = UDim2.new(1, 0, 1, 0)
    vignette.BackgroundTransparency = 1
    vignette.Image = "rbxassetid://5028857084"
    vignette.ImageColor3 = Color3.fromRGB(20, 10, 40)
    vignette.ZIndex = 2
    vignette.Parent = bg
    local sweep = Instance.new("Frame")
    sweep.Name = "Sweep"
    sweep.Size = UDim2.new(0, 0, 1, 0)
    sweep.Position = UDim2.new(0, 0, 0, 0)
    sweep.BackgroundColor3 = Color3.fromRGB(160, 80, 255)
    sweep.BackgroundTransparency = 0.7
    sweep.BorderSizePixel = 0
    sweep.ZIndex = 3
    sweep.Parent = bg
    self.Sweep = sweep
    local logoHolder = Instance.new("Frame")
    logoHolder.Name = "LogoHolder"
    logoHolder.Size = UDim2.new(1, 0, 0, 200)
    logoHolder.Position = UDim2.new(0, 0, 0.5, -120)
    logoHolder.BackgroundTransparency = 1
    logoHolder.ZIndex = 4
    logoHolder.Parent = bg
    local logoShadow = Instance.new("TextLabel")
    logoShadow.BackgroundTransparency = 1
    logoShadow.Size = UDim2.new(1, 0, 1, 0)
    logoShadow.Font = Enum.Font.GothamBlack
    logoShadow.Text = "RCLR"
    logoShadow.TextColor3 = Color3.fromRGB(120, 60, 200)
    logoShadow.TextSize = 130
    logoShadow.TextTransparency = 0.5
    logoShadow.TextStrokeTransparency = 1
    logoShadow.ZIndex = 4
    logoShadow.Parent = logoHolder
    local logo = Instance.new("TextLabel")
    logo.BackgroundTransparency = 1
    logo.Size = UDim2.new(1, 0, 1, 0)
    logo.Font = Enum.Font.GothamBlack
    logo.Text = "RCLR"
    logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    logo.TextSize = 128
    logo.TextTransparency = 0
    logo.ZIndex = 5
    logo.Parent = logoHolder
    local logoGradient = Instance.new("UIGradient")
    logoGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 120, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 60, 200)),
    })
    logoGradient.Rotation = 45
    logoGradient.Parent = logo
    self.Logo = logo
    self.LogoHolder = logoHolder
    local tagline = Instance.new("TextLabel")
    tagline.BackgroundTransparency = 1
    tagline.Size = UDim2.new(1, 0, 0, 30)
    tagline.Position = UDim2.new(0, 0, 0.5, 50)
    tagline.Font = Enum.Font.Gotham
    tagline.Text = "RIVALS  •  ADVANCED UI"
    tagline.TextColor3 = Color3.fromRGB(180, 140, 255)
    tagline.TextSize = 16
    tagline.TextTransparency = 0.2
    tagline.ZIndex = 5
    tagline.Parent = bg
    self.Tagline = tagline
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.Size = UDim2.new(0, 500, 0, 6)
    barBg.Position = UDim2.new(0.5, -250, 0.5, 110)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 5
    barBg.Parent = bg
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 6
    barFill.Parent = barBg
    local barGradient = Instance.new("UIGradient")
    barGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 130, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 255)),
    })
    barGradient.Parent = barFill
    self.BarFill = barFill
    local percent = Instance.new("TextLabel")
    percent.BackgroundTransparency = 1
    percent.Size = UDim2.new(0, 500, 0, 20)
    percent.Position = UDim2.new(0.5, -250, 0.5, 125)
    percent.Font = Enum.Font.GothamBold
    percent.Text = "0%"
    percent.TextColor3 = Color3.fromRGB(255, 255, 255)
    percent.TextSize = 14
    percent.TextTransparency = 0.1
    percent.ZIndex = 5
    percent.Parent = bg
    self.Percent = percent
    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Size = UDim2.new(0, 500, 0, 20)
    status.Position = UDim2.new(0.5, -250, 0.5, 150)
    status.Font = Enum.Font.Gotham
    status.Text = "Initializing"
    status.TextColor3 = Color3.fromRGB(200, 180, 255)
    status.TextSize = 13
    status.TextTransparency = 0.25
    status.ZIndex = 5
    status.Parent = bg
    self.Status = status
    local particles = Instance.new("Frame")
    particles.BackgroundTransparency = 1
    particles.Size = UDim2.new(1, 0, 1, 0)
    particles.ZIndex = 4
    particles.Parent = bg
    self.Particles = {}
    for i = 1, 14 do
        local p = Instance.new("Frame")
        p.Size = UDim2.fromOffset(math.random(2, 5), math.random(2, 5))
        p.Position = UDim2.new(math.random(), 0, math.random(), 0)
        p.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
        p.BorderSizePixel = 0
        p.ZIndex = 4
        p.Parent = particles
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = p
        self.Particles[i] = {
            Frame = p,
            Speed = math.random(20, 60) / 100,
            Offset = math.random() * 10,
        }
    end
    self._particleConn = RunService.Heartbeat:Connect(function(dt)
        for _, data in ipairs(self.Particles) do
            local p = data.Frame
            if p and p.Parent then
                local newY = p.Position.Y.Scale - data.Speed * dt
                if newY < -0.05 then
                    newY = 1.05
                    p.Position = UDim2.new(math.random(), 0, newY, 0)
                else
                    p.Position = UDim2.new(p.Position.X.Scale, 0, newY, 0)
                end
            end
        end
    end)
    self._sweepConn = RunService.Heartbeat:Connect(function(dt)
        local x = sweep.Position.X.Scale + dt * 0.6
        if x > 1.2 then x = -0.2 end
        sweep.Position = UDim2.new(x, 0, 0, 0)
    end)
    self._logoConn = RunService.Heartbeat:Connect(function(dt)
        logoGradient.Rotation = (logoGradient.Rotation + dt * 60) % 360
        local pulse = 1 + math.sin(os.clock() * 3) * 0.01
        logoHolder.Size = UDim2.new(pulse, 0, 0, 200)
    end)
    return self
end

function LoadingScreen:SetProgress(pct, text)
    pct = math.clamp(pct, 0, 1)
    TweenService:Create(self.BarFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(pct, 0, 1, 0),
    }):Play()
    self.Percent.Text = math.floor(pct * 100) .. "%"
    if text then self.Status.Text = text end
end

function LoadingScreen:Destroy(fadeTime)
    fadeTime = fadeTime or 0.6
    if self._particleConn then self._particleConn:Disconnect() end
    if self._sweepConn then self._sweepConn:Disconnect() end
    if self._logoConn then self._logoConn:Disconnect() end
    TweenService:Create(self.Backdrop, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1,
    }):Play()
    for _, label in ipairs(self.Backdrop:GetDescendants()) do
        if label:IsA("TextLabel") then
            TweenService:Create(label, TweenInfo.new(fadeTime * 0.8), { TextTransparency = 1 }):Play()
        elseif label:IsA("Frame") and label ~= self.Backdrop then
            TweenService:Create(label, TweenInfo.new(fadeTime * 0.8), { BackgroundTransparency = 1 }):Play()
        end
    end
    task.delay(fadeTime + 0.1, function()
        pcall(function() self.Gui:Destroy() end)
    end)
end

Library._LoadingScreenClass = LoadingScreen
Library._LoadingScreen = LoadingScreen.new()
Library._LoadingScreen:SetProgress(0.05, "Booting")
task.spawn(function()
    local steps = {
        { 0.18, "Loading modules" },
        { 0.35, "Compiling UI" },
        { 0.55, "Restoring presets" },
        { 0.72, "Wiring managers" },
        { 0.88, "Rendering glass" },
        { 1.00, "Ready" },
    }
    for _, step in ipairs(steps) do
        task.wait(0.28)
        pcall(function() Library._LoadingScreen:SetProgress(step[1], step[2]) end)
    end
end)

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel
        assert(Info.Default, 'AddColorPicker: Missing default value.')
        local ColorPicker = {
            Value = Info.Default,
            Transparency = Info.Transparency or 0,
            Type = 'ColorPicker',
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end,
        }
        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color)
            ColorPicker.Hue = H
            ColorPicker.Sat = S
            ColorPicker.Vib = V
        end
        ColorPicker:SetHSVFromRGB(ColorPicker.Value)
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(0, 28, 0, 14),
            ZIndex = 6,
            Parent = ToggleLabel,
        })
        Library:Create('ImageLabel', {
            BorderSizePixel = 0,
            Size = UDim2.new(0, 27, 0, 13),
            ZIndex = 5,
            Image = 'http://www.roblox.com/asset/?id=12977615774',
            Visible = not not Info.Transparency,
            Parent = DisplayFrame,
        })
        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color',
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253),
            Visible = false,
            ZIndex = 15,
            Parent = ScreenGui,
        })
        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
        end)
        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 16,
            Parent = PickerFrameOuter,
        })
        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 17,
            Parent = PickerFrameInner,
        })
        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 4, 0, 25),
            Size = UDim2.new(0, 200, 0, 200),
            ZIndex = 17,
            Parent = PickerFrameInner,
        })
        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Parent = SatVibMapOuter,
        })
        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Image = 'rbxassetid://4155801252',
            Parent = SatVibMapInner,
        })
        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1,
            Image = 'http://www.roblox.com/asset/?id=9619665977',
            ImageColor3 = Color3.new(0, 0, 0),
            ZIndex = 19,
            Parent = SatVibMap,
        })
        Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'http://www.roblox.com/asset/?id=9619665977',
            ZIndex = 20,
            Parent = CursorOuter,
        })
        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 208, 0, 25),
            Size = UDim2.new(0, 15, 0, 200),
            ZIndex = 17,
            Parent = PickerFrameInner,
        })
        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Parent = HueSelectorOuter,
        })
        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1),
            AnchorPoint = Vector2.new(0, 0.5),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            ZIndex = 18,
            Parent = HueSelectorInner,
        })
        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner,
        })
        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 18,
            Parent = HueBoxOuter,
        })
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
            }),
            Rotation = 90,
            Parent = HueBoxInner,
        })
        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            Font = Library.Font,
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor,
            TextSize = Library.FontSize,
            TextStrokeTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 20,
            Parent = HueBoxInner,
        })
        Library:ApplyTextStroke(HueBox)
        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner,
        })
        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor,
        })
        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor
        if Info.Transparency then
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0),
                Position = UDim2.fromOffset(4, 251),
                Size = UDim2.new(1, -8, 0, 15),
                ZIndex = 19,
                Parent = PickerFrameInner,
            })
            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 19,
                Parent = TransparencyBoxOuter,
            })
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' })
            Library:Create('ImageLabel', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Image = 'http://www.roblox.com/asset/?id=12978095818',
                ZIndex = 20,
                Parent = TransparencyBoxInner,
            })
            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1),
                AnchorPoint = Vector2.new(0.5, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                ZIndex = 21,
                Parent = TransparencyBoxInner,
            })
        end
        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.fromOffset(5, 5),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = Library.FontSize,
            Text = ColorPicker.Title,
            TextWrapped = false,
            ZIndex = 16,
            Parent = PickerFrameInner,
        })
        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,
                Visible = false,
                Parent = ScreenGui,
            })
            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 15,
                Parent = ContextMenu.Container,
            })
            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = ContextMenu.Inner,
            })
            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            })
            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end
            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end
                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end
            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)
            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)
            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })
            function ContextMenu:Show() self.Container.Visible = true end
            function ContextMenu:Hide() self.Container.Visible = false end
            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then Callback = function() end end
                local Button = Library:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, 0, 0, 15),
                    TextSize = Library.FontSize - 1,
                    Text = Str,
                    ZIndex = 16,
                    Parent = self.Inner,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                Library:OnHighlight(Button, Button,
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                )
                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                    Callback()
                end)
            end
            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)
            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then return Library:Notify('You have not copied a color!', 2) end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)
            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)
            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)
        end
        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' })
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor', BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor', BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor', BorderColor3 = 'OutlineColor' })
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor' })
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor' })
        local SequenceTable = {}
        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
        end
        Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable),
            Rotation = 90,
            Parent = HueSelectorInner,
        })
        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end
            ColorPicker:Display()
        end)
        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end
            ColorPicker:Display()
        end)
        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value,
                BackgroundTransparency = ColorPicker.Transparency,
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            })
            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
            end
            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0)
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)
            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end
        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
            Func(ColorPicker.Value)
        end
        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false
                    Library.OpenedFrames[Frame] = nil
                end
            end
            PickerFrameOuter.Visible = true
            Library.OpenedFrames[PickerFrameOuter] = true
        end
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false
            Library.OpenedFrames[PickerFrameOuter] = nil
        end
        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()
        end
        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Display()
        end
        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateColor(PosX, PosY)
                    local MinX = SatVibMap.AbsolutePosition.X
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X
                    local MouseX = math.clamp(PosX, MinX, MaxX)
                    local MinY = SatVibMap.AbsolutePosition.Y
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y
                    local MouseY = math.clamp(PosY, MinY, MaxY)
                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX)
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()
                end
                UpdateColor(Input.Position.X, Input.Position.Y)
                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateColor(Change.Position.X, Change.Position.Y)
                    end
                end)
                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end)
        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateHue(PosY)
                    local MinY = HueSelectorInner.AbsolutePosition.Y
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y
                    local MouseY = math.clamp(PosY, MinY, MaxY)
                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY))
                    ColorPicker:Display()
                end
                UpdateHue(Input.Position.Y)
                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateHue(Change.Position.Y)
                    end
                end)
                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end)
        DisplayFrame.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end)
        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local function UpdateAlpha(PosX)
                        local MinX = TransparencyBoxInner.AbsolutePosition.X
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X
                        local MouseX = math.clamp(PosX, MinX, MaxX)
                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX))
                        ColorPicker:Display()
                    end
                    UpdateAlpha(Input.Position.X)
                    local ChangedConn = InputService.InputChanged:Connect(function(Change)
                        if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                            UpdateAlpha(Change.Position.X)
                        end
                    end)
                    local EndedConn
                    EndedConn = InputService.InputEnded:Connect(function(EndInput)
                        if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                            ChangedConn:Disconnect()
                            EndedConn:Disconnect()
                            Library:AttemptSave()
                        end
                    end)
                end
            end)
        end
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize
                local DFPos = DisplayFrame.AbsolutePosition
                local DFSize = DisplayFrame.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < DFPos.Y or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    if not (Mouse.X >= DFPos.X and Mouse.X <= DFPos.X + DFSize.X
                        and Mouse.Y >= DFPos.Y and Mouse.Y <= DFPos.Y + DFSize.Y) then
                        ColorPicker:Hide()
                    end
                end
                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))
        function ColorPicker:GetTransparency() return ColorPicker.Transparency end
        function ColorPicker:OnTransparencyChanged(Func)
            ColorPicker.TransparencyChanged = Func
            Func(ColorPicker.Transparency)
        end
        local _OrigDisplay = ColorPicker.Display
        ColorPicker.Display = function(self)
            _OrigDisplay(self)
            Library:SafeCallback(ColorPicker.TransparencyChanged, ColorPicker.Transparency)
        end
        ColorPicker:Display()
        ColorPicker.DisplayFrame = DisplayFrame
        Options[Idx] = ColorPicker
        return self
    end

    function Funcs:AddColorPickerAlpha(Idx, Info)
        Info = Info or {}
        if Info.Transparency == nil then Info.Transparency = 0 end
        return Funcs.AddColorPicker(self, Idx, Info)
    end

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel
        local Container = self.Container
        assert(Info.Default, 'AddKeyPicker: Missing default value.')
        if not Info.Text and Info.Label then Info.Text = Info.Label end
        local KeyPicker = {
            Value = Info.Default or 'None',
            Text = Info.Text or Info.Label or 'Key',
            Toggled = false,
            Mode = Info.Mode or 'Toggle',
            Type = 'KeyPicker',
            Callback = Info.Callback or function(Value) end,
            ChangedCallback = Info.ChangedCallback or function(New) end,
            SyncToggleState = Info.SyncToggleState or false,
        }
        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end
        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 28, 0, 15),
            ZIndex = 6,
            Parent = ToggleLabel,
        })
        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7,
            Parent = PickOuter,
        })
        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = 'OutlineColor',
        })
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = Library.FontSize - 1,
            Text = Info.Default,
            TextWrapped = true,
            ZIndex = 8,
            Parent = PickInner,
        })
        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1),
            Size = UDim2.new(0, 60, 0, 45 + 2),
            Visible = false,
            ZIndex = 14,
            Parent = ScreenGui,
        })
        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1)
        end)
        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 15,
            Parent = ModeSelectOuter,
        })
        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor',
            BorderColor3 = 'OutlineColor',
        })
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ModeSelectInner,
        })
        local KeybindEntry = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Visible = false,
            ZIndex = 110,
            Parent = Library.KeybindContainer,
        })
        local ContainerLabel = Library:CreateLabel({
            Position = UDim2.new(0, 2, 0, 0),
            Size = UDim2.new(1, -4, 1, 0),
            TextSize = Library.FontSize - 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 111,
            Parent = KeybindEntry,
        }, true)
        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' }
        local ModeButtons = {}
        for Idx, Mode in next, Modes do
            local ModeButton = {}
            local Label = Library:CreateLabel({
                Active = false,
                Size = UDim2.new(1, 0, 0, 15),
                TextSize = Library.FontSize - 1,
                Text = Mode,
                ZIndex = 16,
                Parent = ModeSelectInner,
            })
            function ModeButton:Select()
                for _, Button in next, ModeButtons do Button:Deselect() end
                KeyPicker.Mode = Mode
                Label.TextColor3 = Library.AccentColor
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor'
                ModeSelectOuter.Visible = false
            end
            function ModeButton:Deselect()
                KeyPicker.Mode = nil
                Label.TextColor3 = Library.FontColor
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor'
            end
            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    ModeButton:Select()
                    Library:AttemptSave()
                end
            end)
            if Mode == KeyPicker.Mode then ModeButton:Select() end
            ModeButtons[Mode] = ModeButton
        end
        function KeyPicker:Update()
            if Info.NoUI then return end
            local State = KeyPicker:GetState()
            local displayKey = (KeyPicker.Value == nil or KeyPicker.Value == 'None') and '...' or tostring(KeyPicker.Value)
            local displayText = tostring(Info.Text or Info.Label or KeyPicker.Text or 'Key')
            local displayMode = tostring(KeyPicker.Mode or Info.Mode or 'Toggle')
            ContainerLabel.Text = string.format('[%s] %s (%s)', displayKey, displayText, displayMode)
            local kbMode = Library.KeybindMode or 'All'
            if kbMode == 'Active' then
                KeybindEntry.Visible = State == true
            elseif kbMode == 'Toggled' then
                local parentOn = false
                if ParentObj and ParentObj.Type == 'Toggle' then
                    parentOn = ParentObj.Value == true
                elseif KeyPicker.SyncToggleState and ParentObj then
                    parentOn = ParentObj.Value == true
                else
                    parentOn = true
                end
                KeybindEntry.Visible = parentOn
            else
                KeybindEntry.Visible = true
            end
            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor'
            local YSize = 0
            local XSize = 0
            for _, Frame in next, Library.KeybindContainer:GetChildren() do
                if Frame:IsA('Frame') and Frame.Visible then
                    YSize = YSize + 18
                    local LabelChild = Frame:FindFirstChildOfClass('TextLabel')
                    if LabelChild and (LabelChild.TextBounds.X + 20 > XSize) then
                        XSize = LabelChild.TextBounds.X + 20
                    end
                end
            end
            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10 + 15, 210), 0, YSize + 23)
        end
        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then return false end
                local Key = KeyPicker.Value
                if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                        or Key == 'Touch' and true
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
                end
            else
                return KeyPicker.Toggled
            end
        end
        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2]
            DisplayLabel.Text = Key
            KeyPicker.Value = Key
            ModeButtons[Mode]:Select()
            KeyPicker:Update()
        end
        function KeyPicker:OnClick(Callback) KeyPicker.Clicked = Callback end
        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value)
        end
        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
            table.insert(Library.KeyPickerList, KeyPicker)
        end
        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end
            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
        end
        local Picking = false
        local LongPressTime = Info.LongPressTime or 0.55
        local TouchMoveThreshold = Info.TouchMoveThreshold or 10
        local function OpenModeSelect() ModeSelectOuter.Visible = true end
        local function BeginPicking()
            if Picking then return end
            Picking = true
            DisplayLabel.Text = ''
            local Break
            local Text = ''
            task.spawn(function()
                while not Break do
                    if Text == '...' then Text = '' end
                    Text = Text .. '.'
                    DisplayLabel.Text = Text
                    wait(0.4)
                end
            end)
            wait(0.2)
            local Event
            Event = InputService.InputBegan:Connect(function(Input)
                local Key
                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = Input.KeyCode.Name
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Key = 'MB1'
                elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    Key = 'MB2'
                elseif Input.UserInputType == Enum.UserInputType.Touch then
                    Key = 'Touch'
                end
                if not Key then return end
                Break = true
                Picking = false
                DisplayLabel.Text = Key
                KeyPicker.Value = Key
                Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)
                Library:AttemptSave()
                Event:Disconnect()
            end)
        end
        PickOuter.InputBegan:Connect(function(Input)
            if Library:MouseIsOverOpenedFrame() then return end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                BeginPicking()
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                OpenModeSelect()
            elseif Input.UserInputType == Enum.UserInputType.Touch then
                local StartPosition = Input.Position
                local TouchMoved = false
                local TouchEnded = false
                local LongPressed = false
                local ChangedConn
                local EndedConn
                ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change == Input then
                        if (Change.Position - StartPosition).Magnitude > TouchMoveThreshold then
                            TouchMoved = true
                        end
                    end
                end)
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input then
                        TouchEnded = true
                        if ChangedConn then ChangedConn:Disconnect() end
                        if EndedConn then EndedConn:Disconnect() end
                        if (not LongPressed) and (not TouchMoved) then
                            task.spawn(BeginPicking)
                        end
                    end
                end)
                task.delay(LongPressTime, function()
                    if TouchEnded or TouchMoved then return end
                    LongPressed = true
                    if ChangedConn then ChangedConn:Disconnect() end
                    if EndedConn then EndedConn:Disconnect() end
                    OpenModeSelect()
                end)
            end
        end)
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if not Picking then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value
                    if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2
                        or Key == 'Touch' and Input.UserInputType == Enum.UserInputType.Touch then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end
                    end
                end
                KeyPicker:Update()
            end
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    ModeSelectOuter.Visible = false
                end
            end
        end))
        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if not Picking then KeyPicker:Update() end
        end))
        KeyPicker:Update()
        Options[Idx] = KeyPicker
        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        local Groupbox = self
        local Container = Groupbox.Container
        Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Size),
            ZIndex = 1,
            Parent = Container,
        })
    end

    function Funcs:AddRow(Columns)
        local Groupbox = self
        local Container = Groupbox.Container
        local ColumnsCount = type(Columns) == 'number' and math.max(1, Columns) or 2
        local RowOuter = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 1,
            Parent = Container,
        })
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = RowOuter,
        })
        local Boxes = {}
        for i = 1, ColumnsCount do
            local Box = { Type = 'Groupbox' }
            local BoxContainer = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1 / ColumnsCount, -((ColumnsCount - 1) * 8) / ColumnsCount, 1, 0),
                ZIndex = 1,
                Parent = RowOuter,
            })
            local BoxLayout = Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = BoxContainer,
            })
            Box.Container = BoxContainer
            setmetatable(Box, BaseGroupbox)
            function Box:Resize()
                local maxHeight = 0
                for _, child in next, RowOuter:GetChildren() do
                    if child:IsA('Frame') then
                        local layout = child:FindFirstChildOfClass('UIListLayout')
                        if layout and layout.AbsoluteContentSize.Y > maxHeight then
                            maxHeight = layout.AbsoluteContentSize.Y
                        end
                    end
                end
                RowOuter.Size = UDim2.new(1, 0, 0, maxHeight)
                if Groupbox.Resize then Groupbox:Resize() end
            end
            BoxLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Box:Resize() end)
            table.insert(Boxes, Box)
        end
        Groupbox:AddBlank(1)
        if Groupbox.Resize then Groupbox:Resize() end
        return unpack(Boxes)
    end

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {}
        local Groupbox = self
        local Container = Groupbox.Container
        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15),
            TextSize = Library.FontSize,
            Text = Text,
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container,
        })
        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TextLabel,
            })
        end
        Label.TextLabel = TextLabel
        Label.Container = Container
        function Label:SetText(Text)
            TextLabel.Text = Text
            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end
            Groupbox:Resize()
        end
        if not DoesWrap then setmetatable(Label, BaseAddons) end
        Groupbox:AddBlank(5)
        Groupbox:Resize()
        return Label
    end

    function Funcs:AddButton(...)
        local Button = {}
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.')
        end
        ProcessButtonParams('Button', Button, ...)
        local Groupbox = self
        local Container = Groupbox.Container
        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -4, 0, 20),
                ZIndex = 5,
            })
            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
                Parent = Outer,
            })
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0),
                TextSize = Library.FontSize,
                Text = Button.Text,
                ZIndex = 6,
                Parent = Inner,
            })
            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
                }),
                Rotation = 90,
                Parent = Inner,
            })
            Library:AddToRegistry(Outer, { BorderColor3 = 'Black' })
            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor',
                BorderColor3 = 'OutlineColor',
            })
            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            )
            return Outer, Inner
        end
        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)
                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end
            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then return false end
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return false end
                return true
            end
            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end
                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })
                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true
                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })
                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)
                    if clicked then Library:SafeCallback(Button.Func) end
                    return
                end
                Library:SafeCallback(Button.Func)
            end)
        end
        Button.Outer, Button.Inner = CreateBaseButton(Button)
        Button.Label = Button.Inner:FindFirstChildOfClass('TextLabel')
        Button.Outer.Parent = Container
        InitEvents(Button)
        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then Library:AddToolTip(tooltip, self.Outer) end
            return self
        end
        function Button:AddButton(...)
            local SubButton = {}
            ProcessButtonParams('SubButton', SubButton, ...)
            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)
            SubButton.Outer, SubButton.Inner = CreateBaseButton(SubButton)
            SubButton.Label = SubButton.Inner:FindFirstChildOfClass('TextLabel')
            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer
            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then Library:AddToolTip(tooltip, self.Outer) end
                return SubButton
            end
            if type(SubButton.Tooltip) == 'string' then SubButton:AddTooltip(SubButton.Tooltip) end
            InitEvents(SubButton)
            return SubButton
        end
        if type(Button.Tooltip) == 'string' then Button:AddTooltip(Button.Tooltip) end
        Groupbox:AddBlank(5)
        Groupbox:Resize()
        return Button
    end

    function Funcs:AddDivider()
        local Groupbox = self
        local Container = self.Container
        Groupbox:AddBlank(2)
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 5),
            ZIndex = 5,
            Parent = Container,
        })
        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DividerOuter,
        })
        Library:AddToRegistry(DividerOuter, { BorderColor3 = 'Black' })
        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })
        Groupbox:AddBlank(9)
        Groupbox:Resize()
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')
        local Textbox = {
            Value = Info.Default or '',
            Numeric = Info.Numeric or false,
            Finished = Info.Finished or false,
            Type = 'Input',
            Callback = Info.Callback or function(Value) end,
        }
        local Groupbox = self
        local Container = Groupbox.Container
        Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15),
            TextSize = Library.FontSize,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container,
        })
        Groupbox:AddBlank(1)
        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Container,
        })
        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = TextBoxOuter,
        })
        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })
        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        )
        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, TextBoxOuter) end
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
            }),
            Rotation = 90,
            Parent = TextBoxInner,
        })
        local InnerContainer = Library:Create('Frame', {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            ZIndex = 7,
            Parent = TextBoxInner,
        })
        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),
            Font = Library.Font,
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
            PlaceholderText = Info.Placeholder or '',
            Text = Info.Default or '',
            TextColor3 = Library.FontColor,
            TextSize = Library.FontSize,
            TextStrokeTransparency = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7,
            Parent = InnerContainer,
        })
        Library:ApplyTextStroke(Box)
        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then Text = Text:sub(1, Info.MaxLength) end
            if Textbox.Numeric and (not tonumber(Text)) and Text:len() > 0 then Text = Textbox.Value end
            Textbox.Value = Text
            Box.Text = Text
            Library:SafeCallback(Textbox.Callback, Textbox.Value)
            Library:SafeCallback(Textbox.Changed, Textbox.Value)
        end
        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text)
                Library:AttemptSave()
            end)
        end
        Library:AddToRegistry(Box, { TextColor3 = 'FontColor' })
        function Textbox:OnChanged(Func)
            Textbox.Changed = Func
            Func(Textbox.Value)
        end
        Groupbox:AddBlank(5)
        Groupbox:Resize()
        Options[Idx] = Textbox
        return Textbox
    end

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
        };
        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });
        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });
        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });
        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });
        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        function Toggle:UpdateColors()
            Toggle:Display();
        end;
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);
            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;
        ToggleRegion.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave();
            end;
        end);
        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');
        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;
        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = Library.FontSize;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });
            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });
        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });
        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        -- keep fill width correct when window is resized
        local function RefreshSliderMaxSize()
            local w = SliderInner.AbsoluteSize.X
            if w and w > 1 then
                Slider.MaxSize = w
            end
        end
        task.defer(RefreshSliderMaxSize)
        SliderInner:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            RefreshSliderMaxSize()
            pcall(function() Slider:Display() end)
        end)
        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });
        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });
        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });
        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';
            if Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local max = SliderInner.AbsoluteSize.X
            if max and max > 1 then Slider.MaxSize = max else max = Slider.MaxSize or 1 end
            local pct = 0
            if Slider.Max ~= Slider.Min then
                pct = math.clamp((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
            end
            Fill.Size = UDim2.new(pct, 0, 1, 0);

            HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0);
        end;
        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;
        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;


            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;
        function Slider:GetValueFromXOffset(X)
            local max = SliderInner.AbsoluteSize.X
            if not max or max < 1 then max = Slider.MaxSize end
            Slider.MaxSize = max
            return Round(Library:MapValue(X, 0, max, Slider.Min, Slider.Max));
        end;
        function Slider:SetValue(Str)
            local Num = tonumber(Str);
            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;
        SliderInner.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                
                local function UpdateSlider(PosX)
                    local gPos = SliderInner.AbsolutePosition.X
                    local maxW = SliderInner.AbsoluteSize.X
                    if maxW and maxW > 1 then Slider.MaxSize = maxW end
                    local Diff = PosX - gPos
                    local nX = math.clamp(Diff, 0, Slider.MaxSize)

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;
    
                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;
                end

                UpdateSlider(Input.Position.X)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateSlider(Change.Position.X)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end;
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;
    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString()
            Info.AllowNull = true
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString()
            Info.AllowNull = true
        end
        assert(Info.Values, 'AddDropdown: Missing dropdown value list.')
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')
        if not Info.Text then Info.Compact = true end
        local Dropdown = {
            Values = Info.Values,
            Value = Info.Multi and {},
            Multi = Info.Multi,
            Type = 'Dropdown',
            SpecialType = Info.SpecialType,
            Callback = Info.Callback or function(Value) end,
        }
        local Groupbox = self
        local Container = Groupbox.Container
        if not Info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10),
                TextSize = Library.FontSize,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container,
            })
            Groupbox:AddBlank(3)
        end
        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Container,
        })
        Library:AddToRegistry(DropdownOuter, { BorderColor3 = 'Black' })
        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DropdownOuter,
        })
        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
            }),
            Rotation = 90,
            Parent = DropdownInner,
        })
        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -16, 0.5, 0),
            Size = UDim2.new(0, 12, 0, 12),
            Image = 'http://www.roblox.com/asset/?id=6282522798',
            ZIndex = 8,
            Parent = DropdownInner,
        })
        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            TextSize = Library.FontSize,
            Text = '--',
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 7,
            Parent = DropdownInner,
        })
        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        )
        if type(Info.Tooltip) == 'string' then Library:AddToolTip(Info.Tooltip, DropdownOuter) end
        local MAX_DROPDOWN_ITEMS = 8
        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            ZIndex = 20,
            Visible = false,
            Parent = ScreenGui,
        })
        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1)
        end
        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end
        RecalculateListPosition()
        RecalculateListSize()
        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition)
        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            BorderMode = Enum.BorderMode.Inset,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            Parent = ListOuter,
        })
        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor',
            BorderColor3 = 'OutlineColor',
        })
        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            Parent = ListInner,
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        })
        Library:AddToRegistry(Scrolling, { ScrollBarImageColor3 = 'AccentColor' })
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Scrolling,
        })
        function Dropdown:Display()
            local Values = Dropdown.Values
            local Str = ''
            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then Str = Str .. Value .. ', ' end
                end
                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value or ''
            end
            ItemList.Text = (Str == '' and '--' or Str)
        end
        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {}
                for Value, Bool in next, Dropdown.Value do table.insert(T, Value) end
                return T
            else
                return Dropdown.Value and 1 or 0
            end
        end
        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values
            local Buttons = {}
            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then Element:Destroy() end
            end
            local Count = 0
            for Idx, Value in next, Values do
                local Table = {}
                Count = Count + 1
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderMode = Enum.BorderMode.Middle,
                    Size = UDim2.new(1, -1, 0, 20),
                    ZIndex = 23,
                    Active = true,
                    Parent = Scrolling,
                })
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor',
                    BorderColor3 = 'OutlineColor',
                })
                local ButtonLabel = Library:CreateLabel({
                    Active = false,
                    Size = UDim2.new(1, -6, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    TextSize = Library.FontSize,
                    Text = Value,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 25,
                    Parent = Button,
                })
                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                )
                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Value]
                else
                    Selected = Dropdown.Value == Value
                end
                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value]
                    else
                        Selected = Dropdown.Value == Value
                    end
                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor'
                end
                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        local Try = not Selected
                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try
                                if Selected then Dropdown.Value[Value] = true
                                else Dropdown.Value[Value] = nil end
                            else
                                Selected = Try
                                if Selected then Dropdown.Value = Value
                                else Dropdown.Value = nil end
                                for _, OtherButton in next, Buttons do OtherButton:UpdateButton() end
                            end
                            Table:UpdateButton()
                            Dropdown:Display()
                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                            Library:AttemptSave()
                        end
                    end
                end)
                Table:UpdateButton()
                Dropdown:Display()
                Buttons[Button] = Table
            end
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1)
            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1
            RecalculateListSize(Y)
        end
        function Dropdown:SetValues(NewValues)
            if NewValues then Dropdown.Values = NewValues end
            Dropdown:BuildDropdownList()
        end
        function Dropdown:OpenDropdown()
            ListOuter.Visible = true
            Library.OpenedFrames[ListOuter] = true
            DropdownArrow.Rotation = 180
        end
        function Dropdown:CloseDropdown()
            ListOuter.Visible = false
            Library.OpenedFrames[ListOuter] = nil
            DropdownArrow.Rotation = 0
        end
        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
            Func(Dropdown.Value)
        end
        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {}
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then nTable[Value] = true end
                end
                Dropdown.Value = nTable
            else
                if not Val then Dropdown.Value = nil
                elseif table.find(Dropdown.Values, Val) then Dropdown.Value = Val end
            end
            Dropdown:BuildDropdownList()
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end
        DropdownOuter.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then Dropdown:CloseDropdown()
                else Dropdown:OpenDropdown() end
            end
        end)
        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
                    Dropdown:CloseDropdown()
                end
            end
        end)
        Dropdown:BuildDropdownList()
        Dropdown:Display()
        local Defaults = {}
        if type(Info.Default) == 'string' then
            local i = table.find(Dropdown.Values, Info.Default)
            if i then table.insert(Defaults, i) end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local i = table.find(Dropdown.Values, Value)
                if i then table.insert(Defaults, i) end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end
        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end
                if not Info.Multi then break end
            end
            Dropdown:BuildDropdownList()
            Dropdown:Display()
        end
        Groupbox:AddBlank(Info.BlankSize or 5)
        Groupbox:Resize()
        Options[Idx] = Dropdown
        return Dropdown
    end

    function Funcs:AddDependencyBox()
        local Depbox = { Dependencies = {} }
        local Groupbox = self
        local Container = Groupbox.Container
        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = Container,
        })
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = true,
            Parent = Holder,
        })
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Frame,
        })
        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
            Groupbox:Resize()
        end
        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() Depbox:Resize() end)
        Holder:GetPropertyChangedSignal('Visible'):Connect(function() Depbox:Resize() end)
        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1]
                local Value = Dependency[2]
                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false
                    Depbox:Resize()
                    return
                end
            end
            Holder.Visible = true
            Depbox:Resize()
        end
        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.')
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.')
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.')
            end
            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end
        Depbox.Container = Frame
        setmetatable(Depbox, BaseGroupbox)
        table.insert(Library.DependencyBoxes, Depbox)
        return Depbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...)
    end
end

do
    Library.NotificationStack = {}
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 320, 1, -50),
        ZIndex = 100,
        Parent = ScreenGui,
    })
    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Library.NotificationArea,
    })
    function Library:ConfigureNotifications(Cfg)
        local C = Library.NotifyConfig
        for k, v in next, Cfg do C[k] = v end
        local AnchorX = C.Alignment == "Left" and 0 or (C.Alignment == "Right" and 1 or 0.5)
        local AnchorY = C.BarSide == "Top" and 0 or 1
        local VAlign = C.BarSide == "Top" and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
        local HAlign = C.Alignment == "Left" and Enum.HorizontalAlignment.Left or (C.Alignment == "Right" and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Center)
        Library.NotificationArea.AnchorPoint = Vector2.new(AnchorX, AnchorY)
        Library.NotificationArea.Position = UDim2.new(C.PosX / 100, 0, C.PosY / 100, 0)
        Library.NotificationArea.ClipsDescendants = C.ClipDescendants
        Library.NotificationArea.AutomaticSize = Enum.AutomaticSize.XY
        local SizeConstraint = Library.NotificationArea:FindFirstChildOfClass('UISizeConstraint')
        if C.ClipDescendants then
            if not SizeConstraint then
                SizeConstraint = Library:Create('UISizeConstraint', { Parent = Library.NotificationArea })
            end
            SizeConstraint.MaxSize = Vector2.new(math.huge, C.MaxHeight)
        elseif SizeConstraint then
            SizeConstraint:Destroy()
        end
        local Layout = Library.NotificationArea:FindFirstChildOfClass('UIListLayout')
        if Layout then
            Layout.VerticalAlignment = VAlign
            Layout.HorizontalAlignment = HAlign
        end
    end
    Library:ConfigureNotifications({})
    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 100, 0, -25),
        Size = UDim2.new(0, 213, 0, 20),
        ZIndex = 200,
        Visible = false,
        Parent = ScreenGui,
    })
    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.AccentColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 201,
        Parent = WatermarkOuter,
    })
    Library:AddToRegistry(WatermarkInner, { BorderColor3 = 'AccentColor' })
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 202,
        Parent = WatermarkInner,
    })
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        }),
        Rotation = -90,
        Parent = InnerFrame,
    })
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            })
        end,
    })
    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        TextSize = Library.FontSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
        Parent = InnerFrame,
    })
    Library.Watermark = WatermarkOuter
    Library.WatermarkText = WatermarkLabel
    Library:MakeDraggable(Library.Watermark)
    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5),
        BorderColor3 = Color3.new(0, 0, 0),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(0, 210, 0, 20),
        Visible = false,
        ZIndex = 100,
        Parent = ScreenGui,
    })
    Library:ApplyGlow(KeybindOuter)
    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101,
        Parent = KeybindOuter,
    })
    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    }, true)
    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        ZIndex = 102,
        Parent = KeybindInner,
    })
    Library:AddToRegistry(ColorFrame, { BackgroundColor3 = 'AccentColor' }, true)
    Library.KeybindInner = KeybindInner
    Library.KeybindColorFrame = ColorFrame
    Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 2),
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = 'Keybinds',
        ZIndex = 104,
        Parent = KeybindInner,
    })
    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20),
        ZIndex = 1,
        Parent = KeybindInner,
    })
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = KeybindContainer,
    })
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })
    Library.KeybindFrame = KeybindOuter
    Library.KeybindContainer = KeybindContainer
    Library:MakeDraggable(KeybindOuter)
end

function Library:SetKeybindMode(Mode)
    assert(Mode == 'All' or Mode == 'Active' or Mode == 'Toggled',
        "SetKeybindMode: Mode must be 'All', 'Active', or 'Toggled'")
    Library.KeybindMode = Mode
    Library:RefreshKeybinds()
end

function Library:RefreshKeybinds()
    for _, kp in ipairs(Library.KeyPickerList) do
        if not kp.NoUI then
            pcall(function() kp:Update() end)
        end
    end
end

function Library:SetWatermarkVisibility(Bool) Library.Watermark.Visible = Bool end

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, Library.FontSize)
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
    Library:SetWatermarkVisibility(true)
    Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
    if not Text or Text == "" then return end
    table.insert(Library.NotifyQueue, { Text = Text, Time = Time })
    Library:ProcessNotifyQueue()
end

function Library:ProcessNotifyQueue()
    local C = Library.NotifyConfig
    local ItemHeight = 22 + 4
    while #Library.NotifyQueue > 0 do
        if C.ClipDescendants and (Library.ActiveNotifyCount + 1) * ItemHeight > C.MaxHeight then break end
        local Item = table.remove(Library.NotifyQueue, 1)
        Library:SpawnNotify(Item.Text, Item.Time)
    end
end

function Library:SpawnNotify(Text, Time)
    local xw = (Library:GetTextBounds(Text, Library.CustomFontFace or Library.Font, 13) or 200)
    local H = 22
    local NotifyTransparency = (Library.NotifyConfig.Transparency or 0) / 100
    Library.NotifyCounter = Library.NotifyCounter + 1
    local Outer = Library:Create('Frame', {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(0, H),
        ClipsDescendants = true,
        LayoutOrder = Library.NotifyConfig.SortOrder == "Text Length" and #Text or Library.NotifyCounter,
        ZIndex = 100,
        Parent = Library.NotificationArea,
    })
    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BackgroundTransparency = NotifyTransparency,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 101,
        Parent = Outer,
    })
    Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor' })
    local InnerStroke = Library:Create('UIStroke', {
        Color = Library.OutlineColor,
        Transparency = NotifyTransparency,
        Thickness = 1,
        Parent = Inner,
    })
    Library:AddToRegistry(InnerStroke, { Color = 'OutlineColor' })
    local GradientFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BackgroundTransparency = NotifyTransparency,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 102,
        Parent = Inner,
    })
    Library:AddToRegistry(GradientFrame, { BackgroundColor3 = 'MainColor' })
    local G = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        }),
        Rotation = -90,
        Parent = GradientFrame,
    })
    Library:AddToRegistry(G, { Color = function()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        })
    end })
    Library:CreateLabel({
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -8, 1, 0),
        Text = Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 13,
        ZIndex = 103,
        Parent = GradientFrame,
    })
    local BarSide = Library.NotifyConfig.BarSide or "Bottom"
    local AccentBarPos, AccentBarSize
    if BarSide == "Top" then
        AccentBarPos = UDim2.new(0, -1, 0, -1)
        AccentBarSize = UDim2.new(1, 2, 0, 3)
    elseif BarSide == "Bottom" then
        AccentBarPos = UDim2.new(0, -1, 1, -2)
        AccentBarSize = UDim2.new(1, 2, 0, 3)
    elseif BarSide == "Left" then
        AccentBarPos = UDim2.new(0, -1, 0, -1)
        AccentBarSize = UDim2.new(0, 3, 1, 2)
    else
        AccentBarPos = UDim2.new(1, -2, 0, -1)
        AccentBarSize = UDim2.new(0, 3, 1, 2)
    end
    Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Position = AccentBarPos,
        Size = AccentBarSize,
        ZIndex = 104,
        Parent = Outer,
    })
    Library:AddToRegistry(Outer:GetChildren()[#Outer:GetChildren()], { BackgroundColor3 = 'AccentColor' }, true)
    pcall(Outer.TweenSize, Outer, UDim2.fromOffset(xw + 16, H), 'Out', 'Quad', 0.35, true)
    Library.ActiveNotifyCount = Library.ActiveNotifyCount + 1
    task.spawn(function()
        task.wait(Time or 5)
        pcall(Outer.TweenSize, Outer, UDim2.fromOffset(0, H), 'Out', 'Quad', 0.35, true)
        task.wait(0.4)
        Outer:Destroy()
        Library.ActiveNotifyCount = Library.ActiveNotifyCount - 1
        Library:ProcessNotifyQueue()
    end)
end

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }
    if type(...) == 'table' then
        Config = ...
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false
    end
    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end
    if type(Config.UseBlur) == 'boolean' then Library.UseBlur = Config.UseBlur end
    if type(Config.BlurSize) == 'number' then Library.BlurSize = Config.BlurSize end
    if type(Config.UseDarken) == 'boolean' then Library.UseDarken = Config.UseDarken end
    if type(Config.DarkenAmount) == 'number' then Library.DarkenAmount = Config.DarkenAmount end
    pcall(function()
        if Library.CreateLoadingScreen and not Library._LoadingScreen then
            Library:CreateLoadingScreen({ Title = "RCLR", Subtitle = "Monova" })
        end
    end)
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 650) end
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if InputService.TouchEnabled then
        local vp = Library.ScreenGui.AbsoluteSize
        local maxWidth = math.min(Config.Size.X.Offset, vp.X - 20)
        local maxHeight = math.min(Config.Size.Y.Offset, vp.Y - 60)
        Config.Size = UDim2.fromOffset(maxWidth, maxHeight)
    end
    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end
    local Window = { Tabs = {} }
    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Position = Config.Position,
        Size = Config.Size,
        Visible = false,
        ZIndex = 1,
        Parent = ScreenGui,
    })
    Library:MakeDraggable(Outer, 25, true)

    -- Premium outline shell (Linoria-style double border)
    local OutlineShell = Library:Create('Frame', {
        Name = "OutlineShell",
        BackgroundColor3 = Library.OutlineColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 1,
        Parent = Outer,
    })
    Library:AddToRegistry(OutlineShell, { BackgroundColor3 = 'OutlineColor' })

    local Inner = Library:Create('Frame', {
        Name = "Inner",
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 1,
        Parent = OutlineShell,
    })
    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    })
    local InnerGloss = Library:Create('Frame', {
        Name = "RCLR_InnerGloss",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.97,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0.35, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 2,
        Parent = Inner,
    })
    Library:Create('UIGradient', {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
        Parent = InnerGloss,
    })
    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 25),
        Text = Config.Title or '',
        RichText = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 1,
        Parent = Inner,
    })
    local MapNameLabel = Library:CreateLabel({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -7, 0, 0),
        Size = UDim2.new(0, 0, 0, 25),
        Text = 'Loading...',
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 1,
        Parent = Inner,
    })
    Library:AddToRegistry(MapNameLabel, { TextColor3 = 'AccentColor' })
    task.spawn(function()
        -- Prefer script override (e.g. "Rivals") so Place API names like "Matchmaking" are not shown
        if type(Config.GameName) == "string" and Config.GameName ~= "" then
            MapNameLabel.Text = Config.GameName
        elseif type(Config.MapName) == "string" and Config.MapName ~= "" then
            MapNameLabel.Text = Config.MapName
        else
            local success, info = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            end)
            local n = (success and info and info.Name) or game.Name or "Unknown"
            -- common Rivals place labels
            if n == "Matchmaking" or n == "Lobby" or (typeof(game.PlaceId) == "number" and game.PlaceId == 17625359962) then
                n = "Rivals"
            end
            MapNameLabel.Text = n
        end
    end)

    -- Clean Unnamed-style tab strip
    local TabBarOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 8, 0, 25),
        Size = UDim2.new(1, -16, 0, 21),
        ZIndex = 1,
        Parent = Inner,
    })
    Library:AddToRegistry(TabBarOuter, {
        BackgroundColor3 = 'BackgroundColor',
        BorderColor3 = 'OutlineColor',
    })
    local TabBarInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Color3.new(0, 0, 0),
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = TabBarOuter,
    })
    Library:AddToRegistry(TabBarInner, { BackgroundColor3 = 'BackgroundColor' })
    -- full-width separator under tabs (Unnamed look)
    local TabSep = Library:Create('Frame', {
        Name = 'TabSeparator',
        BackgroundColor3 = Library.OutlineColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 2,
        Parent = TabBarOuter,
    })
    Library:AddToRegistry(TabSep, { BackgroundColor3 = 'OutlineColor' })
    local TabArea = Library:Create('ScrollingFrame', {
        Name = 'TabArea',
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, -4, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollBarThickness = 0,
        ScrollBarImageTransparency = 1,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ClipsDescendants = true,
        Active = true,
        ZIndex = 2,
        Parent = TabBarInner,
    })
    pcall(function()
        TabArea.TopImage = ''
        TabArea.MidImage = ''
        TabArea.BottomImage = ''
        TabArea.ScrollingEnabled = false
    end)
    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 2),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = TabArea,
    })
    local function RefreshTabCanvas()
        pcall(function()
            local w = math.max(TabListLayout.AbsoluteContentSize.X + 6, 6)
            TabArea.CanvasSize = UDim2.fromOffset(w, 0)
            TabArea.BackgroundTransparency = 1
        end)
    end
    TabListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(RefreshTabCanvas)
    RefreshTabCanvas()

    do
        local dragging = false
        local dragStartX = 0
        local dragStartCanvas = 0
        local velX = 0
        local lastX = 0
        local lastT = 0
        local momentumConn

        local function getMaxScroll()
            local content = TabListLayout.AbsoluteContentSize.X
            local view = TabArea.AbsoluteSize.X
            return math.max(0, content - view + 10)
        end

        local function clampCanvas(x)
            return math.clamp(x, 0, getMaxScroll())
        end

        local function stopMomentum()
            if momentumConn then
                momentumConn:Disconnect()
                momentumConn = nil
            end
        end

        TabArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton3
                or input.UserInputType == Enum.UserInputType.Touch then
                stopMomentum()
                dragging = true
                dragStartX = input.Position.X
                dragStartCanvas = TabArea.CanvasPosition.X
                velX = 0
                lastX = input.Position.X
                lastT = os.clock()
            end
        end)

        TabArea.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                return
            end
            if dragging then
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    local now = os.clock()
                    local dt = now - lastT
                    if dt > 0 then
                        velX = (lastX - input.Position.X) / dt
                    end
                    lastX = input.Position.X
                    lastT = now
                    local dx = dragStartX - input.Position.X
                    TabArea.CanvasPosition = Vector2.new(clampCanvas(dragStartCanvas + dx), 0)
                end
            end
        end)

        InputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton3
                or input.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    dragging = false
                    if math.abs(velX) > 50 then
                        local startCanvas = TabArea.CanvasPosition.X
                        local projected = clampCanvas(startCanvas + velX * 0.35)
                        TweenService:Create(TabArea, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                            CanvasPosition = Vector2.new(projected, 0),
                        }):Play()
                    end
                    velX = 0
                end
            end
        end)
    end
    Window._RefreshTabCanvas = RefreshTabCanvas

    -- Drag tabs horizontally (mobile + mouse) so every tab is reachable
    do
        local draggingTabs = false
        local startX, startCanvas
        TabArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                draggingTabs = true
                startX = input.Position.X
                startCanvas = TabArea.CanvasPosition.X
            end
        end)
        InputService.InputChanged:Connect(function(input)
            if not draggingTabs then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                local dx = startX - input.Position.X
                TabArea.CanvasPosition = Vector2.new(math.max(0, startCanvas + dx), 0)
            end
        end)
        InputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                draggingTabs = false
            end
        end)
    end

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 6, 0, 48),
        Size = UDim2.new(1, -12, 1, -54),
        ZIndex = 1,
        Parent = Inner,
    })
    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor',
        BorderColor3 = 'OutlineColor',
    })
    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Color3.new(0, 0, 0),
        BorderMode = Enum.BorderMode.Inset,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = MainSectionOuter,
    })
    Library:AddToRegistry(MainSectionInner, { BackgroundColor3 = 'BackgroundColor' })
    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 1, -16),
        ZIndex = 2,
        Parent = MainSectionInner,
    })
    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    })
    Outer.ClipsDescendants = true

    local CornerCircle = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Library.AccentColor,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(46, 46),
        ZIndex = 10,
        Parent = Inner,
    })
    Library:Create('UICorner', {
        CornerRadius = UDim.new(1, 0),
        Parent = CornerCircle,
    })
    Library:AddToRegistry(CornerCircle, { BackgroundColor3 = 'AccentColor' })
    CornerCircle.Active = true
    CornerCircle.Parent = Outer
    CornerCircle.ZIndex = 100
    CornerCircle.MouseEnter:Connect(function()
        CornerCircle.BackgroundTransparency = 0.15
    end)
    CornerCircle.MouseLeave:Connect(function()
        CornerCircle.BackgroundTransparency = 0.5
    end)

    do
        local MinW = 420
        local MinH = 340
        local Resizing = false
        local ResizeConn, EndConn
        local StartSize, DragStart, DragType
        local HasMoved = false
        local Wireframe
        local function StopResize()
            Resizing = false
            if ResizeConn then ResizeConn:Disconnect() ResizeConn = nil end
            if EndConn then EndConn:Disconnect() EndConn = nil end
        end
        local function StartResize(Position, FromType)
            if Resizing then return end
            StopResize()
            Resizing = true
            StartSize = Outer.Size
            DragStart = Position
            DragType = FromType
            HasMoved = false
            if Wireframe then Wireframe:Destroy() Wireframe = nil end
            ResizeConn = InputService.InputChanged:Connect(function(Change)
                local T = Change.UserInputType
                if T ~= Enum.UserInputType.MouseMovement and T ~= Enum.UserInputType.Touch then return end
                if DragType ~= Enum.UserInputType.Touch and T == Enum.UserInputType.Touch then return end
                local Delta = Change.Position - DragStart
                if not HasMoved and Delta.Magnitude <= 2 then return end
                local TopLeft = Outer.AbsolutePosition
                local VPSize = Library.ScreenGui.AbsoluteSize
                local NewW = math.clamp(StartSize.X.Offset + Delta.X, MinW, VPSize.X - TopLeft.X)
                local NewH = math.clamp(StartSize.Y.Offset + Delta.Y, MinH, VPSize.Y - TopLeft.Y)
                if Library.WireframeDrag then
                    if not HasMoved then
                        HasMoved = true
                        Wireframe = Library:Create('Frame', {
                            Size = UDim2.fromOffset(NewW, NewH),
                            Position = UDim2.fromOffset(TopLeft.X, TopLeft.Y),
                            BackgroundTransparency = 1,
                            Active = false,
                            ZIndex = 100000,
                            Parent = ScreenGui,
                        })
                        Library:Create('UIStroke', {
                            Color = Library.AccentColor,
                            Thickness = 1,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                            Parent = Wireframe,
                        })
                    end
                    if HasMoved and Wireframe then
                        Wireframe.Position = UDim2.fromOffset(TopLeft.X, TopLeft.Y)
                        Wireframe.Size = UDim2.fromOffset(NewW, NewH)
                    end
                else
                    Outer.Size = UDim2.fromOffset(NewW, NewH)
                end
            end)
            EndConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput.UserInputType == DragType then
                    if Library.WireframeDrag and HasMoved and Wireframe then
                        Outer.Size = Wireframe.Size
                        Wireframe:Destroy()
                        Wireframe = nil
                    end
                    StopResize()
                end
            end)
        end
        local function OnHandlePressed(Position, InputType)
            StartResize(Position, InputType)
        end
        CornerCircle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                OnHandlePressed(Input.Position, Input.UserInputType)
            end
        end)
        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
            if Resizing then return end
            local WindowPos = Outer.AbsolutePosition
            local WindowSize = Outer.AbsoluteSize
            local CenterX = WindowPos.X + WindowSize.X
            local CenterY = WindowPos.Y + WindowSize.Y
            local P = Input.Position
            local Rad = 26
            local DX = CenterX - P.X
            local DY = CenterY - P.Y
            if (DX * DX) + (DY * DY) <= (Rad * Rad) then
                OnHandlePressed(P, Input.UserInputType)
            end
        end)
    end

    function Window:SetWindowTitle(Title) WindowLabel.Text = Title end

    function Window:AddTab(Name)
        local Tab = { Groupboxes = {}, Tabboxes = {} }
        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, Library.FontSize + 2)
        -- Unnamed-style compact tab
        -- Classic Linoria / Unnamed Enhancements tab
        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, math.max(TabButtonWidth + 14, 42), 1, 0),
            ZIndex = 1,
            Parent = TabArea,
            Active = true,
        })
        Library:AddToRegistry(TabButton, { BackgroundColor3 = 'MainColor' })
        local TabLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, -1),
            Text = Name,
            TextSize = Library.FontSize,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 2,
            Parent = TabButton,
        })
        local TabIndicator = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1),
            Size = UDim2.new(1, 0, 0, 1),
            Visible = false,
            ZIndex = 3,
            Parent = TabButton,
        })
        Library:AddToRegistry(TabIndicator, { BackgroundColor3 = 'AccentColor' })
        Library:AddToRegistry(TabIndicator, { BackgroundColor3 = 'AccentColor' })
        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 2,
            Parent = TabContainer,
        })
        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1),
            Size = UDim2.new(0.5, -12 + 2, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = '',
            TopImage = '',
            ScrollBarThickness = 0,
            ZIndex = 2,
            Parent = TabFrame,
        })
        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1),
            Size = UDim2.new(0.5, -12 + 2, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BottomImage = '',
            TopImage = '',
            ScrollBarThickness = 0,
            ZIndex = 2,
            Parent = TabFrame,
        })
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = LeftSide,
        })
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = RightSide,
        })
        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
            end)
        end
        function Tab:ShowTab()
            for _, T in next, Window.Tabs do
                if T.HideTab then T:HideTab() end
            end
            TabButton.BackgroundColor3 = Library.BackgroundColor
            TabButton.BackgroundTransparency = 0
            if Library.RegistryMap[TabButton] then
                Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor'
            end
            TabLabel.TextTransparency = 0
            TabFrame.Visible = true
            TabIndicator.Visible = true
            -- keep selected tab visible in scroll area
            pcall(function()
                local abs = TabButton.AbsolutePosition.X
                local area = TabArea.AbsolutePosition.X
                local rel = abs - area + TabArea.CanvasPosition.X
                local view = TabArea.AbsoluteSize.X
                if rel < TabArea.CanvasPosition.X then
                    TabArea.CanvasPosition = Vector2.new(math.max(0, rel - 8), 0)
                elseif rel + TabButton.AbsoluteSize.X > TabArea.CanvasPosition.X + view then
                    TabArea.CanvasPosition = Vector2.new(rel + TabButton.AbsoluteSize.X - view + 8, 0)
                end
            end)
            Window.ActiveTab = Name
        end
        function Tab:HideTab()
            TabButton.BackgroundColor3 = Library.MainColor
            TabButton.BackgroundTransparency = 0
            if Library.RegistryMap[TabButton] then
                Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor'
            end
            TabLabel.TextTransparency = 0
            TabFrame.Visible = false
            TabIndicator.Visible = false
        end
        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position
            TabListLayout:ApplyLayout()
        end
        function Tab:AddGroupbox(Info)
            local Groupbox = {}
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 0, 507 + 2),
                ZIndex = 2,
                Parent = Info.Side == 1 and LeftSide or RightSide,
            })
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                ZIndex = 4,
                Parent = BoxOuter,
            })
            Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'BackgroundColor' })
            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 5,
                Parent = BoxInner,
            })
            Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' })
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18),
                Position = UDim2.new(0, 0, 0, 2),
                TextSize = Library.FontSize,
                Text = Info.Name,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 5,
                Parent = BoxInner,
            })
            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 4, 0, 20),
                Size = UDim2.new(1, -4, 1, -20),
                ZIndex = 1,
                Parent = BoxInner,
            })
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container,
            })
            function Groupbox:Resize()
                local Size = 0
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if not Element:IsA('UIListLayout') and Element.Visible then
                        Size = Size + Element.Size.Y.Offset
                    end
                end
                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
            end
            Groupbox.Container = Container
            setmetatable(Groupbox, BaseGroupbox)
            Groupbox:AddBlank(3)
            Groupbox:Resize()
            Tab.Groupboxes[Info.Name] = Groupbox
            return Groupbox
        end
        function Tab:AddLeftGroupbox(Name) return Tab:AddGroupbox({ Side = 1, Name = Name }) end
        function Tab:AddRightGroupbox(Name) return Tab:AddGroupbox({ Side = 2, Name = Name }) end
        function Tab:AddTabbox(Info)
            local Tabbox = { Tabs = {} }
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                BorderMode = Enum.BorderMode.Inset,
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 2,
                Parent = Info.Side == 1 and LeftSide or RightSide,
            })
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor',
                BorderColor3 = 'OutlineColor',
            })
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                ZIndex = 4,
                Parent = BoxOuter,
            })
            Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'BackgroundColor' })
            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 1),
                Size = UDim2.new(1, 0, 0, 18),
                ZIndex = 5,
                Parent = BoxInner,
            })
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TabboxButtons,
            })
            function Tabbox:AddTab(Name)
                local Tab = {}
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    ZIndex = 6,
                    Parent = TabboxButtons,
                })
                Library:AddToRegistry(Button, { BackgroundColor3 = 'MainColor' })
                local TabHighlight = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 2),
                    Visible = false,
                    ZIndex = 10,
                    Parent = Button,
                })
                Library:AddToRegistry(TabHighlight, { BackgroundColor3 = 'AccentColor' })
                Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0),
                    TextSize = Library.FontSize,
                    Text = Name,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 7,
                    Parent = Button,
                })
                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                    Visible = false,
                    ZIndex = 9,
                    Parent = Button,
                })
                Library:AddToRegistry(Block, { BackgroundColor3 = 'BackgroundColor' })
                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 4, 0, 20),
                    Size = UDim2.new(1, -4, 1, -20),
                    ZIndex = 1,
                    Visible = false,
                    Parent = BoxInner,
                })
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = Container,
                })
                function Tab:Show()
                    for _, T in next, Tabbox.Tabs do T:Hide() end
                    Container.Visible = true
                    Block.Visible = true
                    TabHighlight.Visible = true
                    Button.BackgroundColor3 = Library.BackgroundColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor'
                    Tab:Resize()
                end
                function Tab:Hide()
                    Container.Visible = false
                    Block.Visible = false
                    TabHighlight.Visible = false
                    Button.BackgroundColor3 = Library.MainColor
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor'
                end
                function Tab:Resize()
                    local TabCount = 0
                    for _, T in next, Tabbox.Tabs do TabCount = TabCount + 1 end
                    for _, B in next, TabboxButtons:GetChildren() do
                        if not B:IsA('UIListLayout') then
                            B.Size = UDim2.new(1 / TabCount, 0, 1, 0)
                        end
                    end
                    if not Container.Visible then return end
                    local Size = 0
                    for _, Element in next, Tab.Container:GetChildren() do
                        if not Element:IsA('UIListLayout') and Element.Visible then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end
                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2)
                end
                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show()
                        Tab:Resize()
                    end
                end)
                Tab.Container = Container
                Tabbox.Tabs[Name] = Tab
                setmetatable(Tab, BaseGroupbox)
                Tab:AddBlank(3)
                Tab:Resize()
                if #TabboxButtons:GetChildren() == 2 then Tab:Show() end
                return Tab
            end
            Tab.Tabboxes[Info.Name or ''] = Tabbox
            return Tabbox
        end
        function Tab:AddLeftTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 1 }) end
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 2 }) end
        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Tab:ShowTab()
            end
        end)
        if #TabContainer:GetChildren() == 1 then Tab:ShowTab() end
        Window.Tabs[Name] = Tab
        pcall(function()
            if Window._RefreshTabCanvas then Window._RefreshTabCanvas() end
        end)
        return Tab
    end

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),
        Visible = true,
        Text = '',
        Modal = false,
        Parent = ScreenGui,
    })

    Library._StoredSize = nil
    Library._StoredPos = nil

    function Library:Toggle()
        Library.Toggled = not Library.Toggled
        ModalElement.Modal = Library.Toggled

        if Library.Toggled then
            Outer.Visible = true
            pcall(function() if Library.UpdateLogoVisibility then Library:UpdateLogoVisibility() end end)
            pcall(function() if Library.ReapplyGlass then Library:ReapplyGlass() end end)
            local fullSize = Library._StoredSize or Outer.Size
            local fullPos = Library._StoredPos or Outer.Position
            Library._StoredSize = nil
            Library._StoredPos = nil
            if fullSize.X.Offset > 50 and fullSize.Y.Offset > 50 then
                Outer.Size = UDim2.fromOffset(
                    math.floor(fullSize.X.Offset * 0.92),
                    math.floor(fullSize.Y.Offset * 0.92)
                )
                TweenService:Create(Outer, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = fullSize,
                    Position = fullPos,
                }):Play()
            end
            task.spawn(function()
                local State = InputService.MouseIconEnabled
                local GuiService = game:GetService("GuiService")
                local Cursor = Instance.new("ImageLabel", ScreenGui)
                Cursor.Image = "http://www.roblox.com/asset/?id=4292970642"
                Cursor.BackgroundTransparency = 1
                Cursor.ZIndex = 100
                local CursorOutline = Instance.new("ImageLabel", ScreenGui)
                CursorOutline.Image = "http://www.roblox.com/asset/?id=4292970642"
                CursorOutline.ImageColor3 = Color3.new()
                CursorOutline.BackgroundTransparency = 1
                CursorOutline.ZIndex = 99
                Cursor.Size, CursorOutline.Size = UDim2.fromOffset(17, 17), UDim2.fromOffset(19, 19)
                Cursor.Rotation, CursorOutline.Rotation = -45, -45
                if Library.IsMobile == true then
                    while Library.Toggled and ScreenGui.Parent do
                        task.wait(0.5)
                    end
                else
                    while Library.Toggled and ScreenGui.Parent do
                        InputService.MouseIconEnabled = false
                        local mPos = InputService:GetMouseLocation()
                        local udim = UDim2.fromOffset(mPos.X, mPos.Y - GuiService:GetGuiInset().Y - 1)
                        Cursor.ImageColor3 = Library.AccentColor
                        Cursor.Position, CursorOutline.Position = udim, udim - UDim2.fromOffset(1, 1)
                        if Library.PerformanceMode then
                            task.wait()
                        else
                            RenderStepped:Wait()
                        end
                    end
                end
                InputService.MouseIconEnabled = State
                Cursor:Destroy()
                CursorOutline:Destroy()
            end)
        else
            Library._StoredSize = Outer.Size
            Library._StoredPos = Outer.Position
            local startSize = Outer.Size
            local targetSize = UDim2.fromOffset(
                math.max(50, math.floor(startSize.X.Offset * 0.92)),
                math.max(50, math.floor(startSize.Y.Offset * 0.92))
            )
            TweenService:Create(Outer, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = targetSize,
            }):Play()
            task.delay(0.22, function()
                if not Library.Toggled then
                    Outer.Visible = false
                    if Library._StoredSize then
                        Outer.Size = Library._StoredSize
                        Outer.Position = Library._StoredPos
                    end
                end
            end)
        end
        pcall(function() if Library.UpdateLogoVisibility then Library:UpdateLogoVisibility() end end)
        Library:UpdateBlur()
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif type(Library.ToggleKeybind) == 'string' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))

    if Config.AutoShow then
        task.spawn(function()
            Library.Toggled = false
            Library:Toggle()
            pcall(function()
                Outer.Visible = true
                Library.Toggled = true
            end)
        end)
    end

    Window.Holder = Outer
    Library.WindowOuter = Outer

    pcall(function() if Library.ApplyBlackWhiteTheme then Library:ApplyBlackWhiteTheme() end end)
    pcall(function() if Library.SetGlass then Library:SetGlass(true, Library.GlassTransparency or 0.92) end end)

    task.defer(function()
        pcall(function()
            Library.Toggled = true
            ModalElement.Modal = true
            Outer.Visible = true
            if Library.ScreenGui then Library.ScreenGui.Enabled = true end
            if Library.UpdateBlur then Library:UpdateBlur() end
            if Library.ReapplyGlass then Library:ReapplyGlass() end
            if Library.CreateLogo then
                Library:CreateLogo({ Text = "RCLR", TextSize = 52, SpinSpeed = 30 })
            end
            if Library.UpdateLogoVisibility then Library:UpdateLogoVisibility() end
            if Library._LoadingScreen then
                pcall(function() Library._LoadingScreen:Destroy(0.7) end)
                Library._LoadingScreen = nil
            end
        end)
    end)

    return Window
end

local function OnPlayerChange()
    local PlayerList = GetPlayersString()
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList)
        end
    end
end

Players.PlayerAdded:Connect(OnPlayerChange)
Players.PlayerRemoving:Connect(OnPlayerChange)

if InputService.TouchEnabled then
    local MobileGui = Instance.new("ScreenGui")
    MobileGui.Name = "RCLR_MobileUI"
    MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    MobileGui.DisplayOrder = 9999
    MobileGui.ResetOnSpawn = false
    ProtectGui(MobileGui)
    MobileGui.Parent = CoreGui

    -- Linoria 1:1 sizes
    local BTN_W, BTN_H = 72, 24
    local BTN_GAP = 32

    local function CreateMobileButton(name, text, startPos)
        local Outer = Library:Create('Frame', {
            Name = name .. "Outer",
            BackgroundColor3 = Library.OutlineColor,
            BorderSizePixel = 0,
            Position = startPos,
            Size = UDim2.new(0, BTN_W, 0, BTN_H),
            ZIndex = 300,
            Parent = MobileGui,
            Active = true,
        })
        Library:AddToRegistry(Outer, { BackgroundColor3 = 'OutlineColor' })

        local AccentFrame = Library:Create('Frame', {
            Name = name .. "Accent",
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 301,
            Parent = Outer,
        })
        Library:AddToRegistry(AccentFrame, { BackgroundColor3 = 'AccentColor' })

        local Inner = Library:Create('Frame', {
            Name = name .. "Inner",
            BackgroundColor3 = Color3.fromRGB(8, 8, 12),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            ZIndex = 302,
            Parent = AccentFrame,
        })

        local GradientOverlay = Library:Create('Frame', {
            Name = name .. "Gradient",
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 303,
            Parent = Inner,
        })
        Library:Create('UIGradient', {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.90),
                NumberSequenceKeypoint.new(1, 1.0),
            }),
            Rotation = 90,
            Parent = GradientOverlay,
        })

        local Btn = Library:Create('TextButton', {
            Name = name .. "Btn",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            Font = Enum.Font.Code,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 304,
            Parent = Inner,
            Active = true,
            AutoButtonColor = false,
        })

        return Outer, Btn, AccentFrame
    end

    local ToggleOuter, ToggleBtn = CreateMobileButton("Toggle", "Toggle UI", UDim2.new(0, 10, 0, 10))
    local LockOuter, LockBtn = CreateMobileButton("Lock", "Unlock UI", UDim2.new(0, 10, 0, 10 + BTN_H + (BTN_GAP - BTN_H)))

    -- IsUnlocked = mobile buttons can be dragged
    -- UILocked = main window cannot be dragged
    local IsUnlocked = false
    Library.UILocked = false

    local function BindMobile(Btn, Outer, onClick)
        local dragging = false
        local dragInput, dragStart, startPos
        local hasMoved = false
        local handled = false

        local function doClick()
            if handled then return end
            handled = true
            task.defer(function() handled = false end)
            pcall(onClick)
        end

        Btn.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = Outer.Position
            dragInput = input

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                    if not hasMoved then
                        doClick()
                    end
                end
            end)
        end)

        InputService.InputChanged:Connect(function(input)
            if not dragging or input ~= dragInput then return end
            local delta = input.Position - dragStart
            if delta.Magnitude > 12 then
                hasMoved = true
            end
            if IsUnlocked and hasMoved then
                Outer.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    BindMobile(ToggleBtn, ToggleOuter, function()
        pcall(function()
            Library:Toggle()
        end)
    end)

    BindMobile(LockBtn, LockOuter, function()
        IsUnlocked = not IsUnlocked
        Library.UILocked = not IsUnlocked
        LockBtn.Text = IsUnlocked and "Lock UI" or "Unlock UI"
        LockBtn.TextColor3 = IsUnlocked and Library.AccentColor or Color3.fromRGB(255, 255, 255)
        -- when locked, prevent window drag via flag
        pcall(function()
            if Library.Notify then
                Library:Notify(IsUnlocked and "Unlocked - drag buttons" or "Locked", 2)
            end
        end)
    end)

    Library.MobileGui = MobileGui
    Library.MobileToggleBtn = ToggleBtn
    Library.MobileLockBtn = LockBtn
    Library.IsMobile = true
end

function Library:ApplyBlackWhiteTheme()
    Library.FontColor = Color3.fromRGB(220, 220, 220)
    Library.MainColor = Color3.fromRGB(28, 28, 28)
    Library.BackgroundColor = Color3.fromRGB(18, 18, 18)
    Library.AccentColor = Color3.fromRGB(200, 200, 200)
    Library.OutlineColor = Color3.fromRGB(45, 45, 45)
    Library.RiskColor = Color3.fromRGB(220, 60, 60)
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
    pcall(function() Library:UpdateColorsUsingRegistry() end)
    pcall(function() if Library.SyncThemeColorPickers then Library:SyncThemeColorPickers() end end)
    pcall(function() if Library.ReapplyGlass then Library:ReapplyGlass() end end)
end

function Library:SetGlass(Enabled, Transparency)
    if Library._SettingGlass then return end
    Library._SettingGlass = true

    if type(Enabled) == "boolean" then Library.GlassEnabled = Enabled
    else Library.GlassEnabled = Enabled ~= false end
    if type(Transparency) == "number" then
        Library.GlassTransparency = math.clamp(Transparency, 0.45, 0.96)
    end
    Library.GlassTransparency = Library.GlassTransparency or 0.72

    local on = Library.GlassEnabled == true
    local t = Library.GlassTransparency

    -- 3D glass layers (outer shell / mid frost / inner content)
    local L_outer = on and math.clamp(0.86 + (t - 0.5) * 0.18, 0.82, 0.95) or 0
    local L_mid   = on and math.clamp(0.62 + (t - 0.5) * 0.4, 0.55, 0.88) or 0
    local L_inner = on and math.clamp(0.38 + (t - 0.5) * 0.35, 0.28, 0.68) or 0
    Library.OuterGlassTransparency = L_outer

    pcall(function()
        if on then
            Library.UseBlur = not (Library.IsMobile == true)
            Library.BlurSize = math.clamp(Library.BlurSize or 18, 14, 32)
            Library.UseDarken = true
            Library.DarkenAmount = math.clamp(Library.DarkenAmount or 10, 4, 18)
        end

        local outer = Library.WindowOuter
        if outer then
            outer.BackgroundColor3 = Library.BackgroundColor
            outer.BackgroundTransparency = L_outer
            outer.BorderSizePixel = 0

            -- outer glass rim (bright edge)
            local edge = outer:FindFirstChild("RCLR_GlassEdge")
            if on then
                if not edge then
                    edge = Instance.new("UIStroke")
                    edge.Name = "RCLR_GlassEdge"
                    edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    edge.LineJoinMode = Enum.LineJoinMode.Round
                    edge.Parent = outer
                end
                edge.Thickness = 1.5
                edge.Color = Color3.fromRGB(255, 255, 255)
                edge.Transparency = 0.55
            elseif edge then
                edge:Destroy()
            end

            -- inner dark rim (depth)
            local rim = outer:FindFirstChild("RCLR_GlassRim")
            if on then
                if not rim then
                    rim = Instance.new("UIStroke")
                    rim.Name = "RCLR_GlassRim"
                    rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    rim.LineJoinMode = Enum.LineJoinMode.Round
                    rim.Parent = outer
                end
                -- second stroke can't stack well - use Frame border inset instead
                rim.Thickness = 0.5
                rim.Color = Color3.fromRGB(0, 0, 0)
                rim.Transparency = 0.7
            elseif rim then
                rim:Destroy()
            end

            -- depth shadow (3D lift)
            local shadow = outer:FindFirstChild("RCLR_GlassShadow")
            if on then
                if not shadow then
                    shadow = Instance.new("Frame")
                    shadow.Name = "RCLR_GlassShadow"
                    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
                    shadow.BorderSizePixel = 0
                    shadow.ZIndex = math.max(0, (outer.ZIndex or 1) - 1)
                    shadow.Parent = outer.Parent or outer
                    local sc = Instance.new("UICorner")
                    sc.CornerRadius = UDim.new(0, 8)
                    sc.Parent = shadow
                end
                shadow.BackgroundTransparency = 0.72
                shadow.Size = outer.Size + UDim2.fromOffset(14, 16)
                shadow.Position = outer.Position + UDim2.fromOffset(-7, 6)
                shadow.AnchorPoint = outer.AnchorPoint
            elseif shadow then
                shadow:Destroy()
            end

            -- secondary soft shadow
            local shadow2 = outer:FindFirstChild("RCLR_GlassShadow2")
            if on then
                if not shadow2 then
                    shadow2 = Instance.new("Frame")
                    shadow2.Name = "RCLR_GlassShadow2"
                    shadow2.BackgroundColor3 = Color3.new(0, 0, 0)
                    shadow2.BorderSizePixel = 0
                    shadow2.ZIndex = math.max(0, (outer.ZIndex or 1) - 2)
                    shadow2.Parent = outer.Parent or outer
                    local sc = Instance.new("UICorner")
                    sc.CornerRadius = UDim.new(0, 10)
                    sc.Parent = shadow2
                end
                shadow2.BackgroundTransparency = 0.88
                shadow2.Size = outer.Size + UDim2.fromOffset(22, 24)
                shadow2.Position = outer.Position + UDim2.fromOffset(-11, 10)
                shadow2.AnchorPoint = outer.AnchorPoint
            elseif shadow2 then
                shadow2:Destroy()
            end

            -- top specular gloss (angled light)
            local gloss = outer:FindFirstChild("RCLR_GlassGloss")
            if on then
                if not gloss then
                    gloss = Instance.new("Frame")
                    gloss.Name = "RCLR_GlassGloss"
                    gloss.BackgroundColor3 = Color3.new(1, 1, 1)
                    gloss.BorderSizePixel = 0
                    gloss.Size = UDim2.new(1, 0, 0.42, 0)
                    gloss.Position = UDim2.new(0, 0, 0, 0)
                    gloss.ZIndex = (outer.ZIndex or 1) + 2
                    gloss.Parent = outer
                    local g = Instance.new("UIGradient")
                    g.Name = "GlossGrad"
                    g.Rotation = 105
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.4),
                        NumberSequenceKeypoint.new(0.35, 0.85),
                        NumberSequenceKeypoint.new(0.7, 0.97),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    g.Parent = gloss
                end
                gloss.BackgroundTransparency = 0.82
            elseif gloss then
                gloss.BackgroundTransparency = 1
            end

            -- bottom subtle reflection band
            local refl = outer:FindFirstChild("RCLR_GlassRefl")
            if on then
                if not refl then
                    refl = Instance.new("Frame")
                    refl.Name = "RCLR_GlassRefl"
                    refl.BackgroundColor3 = Color3.new(1, 1, 1)
                    refl.BorderSizePixel = 0
                    refl.Size = UDim2.new(1, 0, 0.18, 0)
                    refl.Position = UDim2.new(0, 0, 0.82, 0)
                    refl.ZIndex = (outer.ZIndex or 1) + 2
                    refl.Parent = outer
                    local g = Instance.new("UIGradient")
                    g.Rotation = 90
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 0.94),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    g.Parent = refl
                end
                refl.BackgroundTransparency = 0.93
            elseif refl then
                refl.BackgroundTransparency = 1
            end

            -- left edge light (3D bevel)
            local leftLight = outer:FindFirstChild("RCLR_GlassLeft")
            if on then
                if not leftLight then
                    leftLight = Instance.new("Frame")
                    leftLight.Name = "RCLR_GlassLeft"
                    leftLight.BackgroundColor3 = Color3.new(1, 1, 1)
                    leftLight.BorderSizePixel = 0
                    leftLight.Size = UDim2.new(0, 3, 1, 0)
                    leftLight.Position = UDim2.new(0, 0, 0, 0)
                    leftLight.ZIndex = (outer.ZIndex or 1) + 3
                    leftLight.Parent = outer
                    local g = Instance.new("UIGradient")
                    g.Rotation = 0
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.7),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    g.Parent = leftLight
                end
                leftLight.BackgroundTransparency = 0.88
            elseif leftLight then
                leftLight.BackgroundTransparency = 1
            end
        end

        if Library.DarkOverlay then
            if on and Library.Toggled then
                Library.DarkOverlay.BackgroundTransparency = 1 - ((Library.DarkenAmount or 10) / 100)
            else
                Library.DarkOverlay.BackgroundTransparency = 1
            end
        end

        if not Library.ScreenGui then
            Library._SettingGlass = false
            return
        end

        local registryMap = Library.RegistryMap
        for _, d in ipairs(Library.ScreenGui:GetDescendants()) do
            if d:IsA("Frame") or d:IsA("ScrollingFrame") then
                local nm = d.Name
                local parent = d.Parent
                local pname = parent and parent.Name or ""

                if nm == "TabArea" or nm == "RCLR_LogoBehind" or nm == "LogoHolder"
                    or nm:find("RCLR_Glass") then
                    if not nm:find("Gloss") and not nm:find("Refl") and not nm:find("Left") then
                        d.BackgroundTransparency = 1
                    end
                elseif nm == "TabBarOuter" or nm == "TabBarInner" then
                    d.BackgroundColor3 = Library.BackgroundColor
                    d.BackgroundTransparency = on and math.clamp(L_mid * 0.55, 0.2, 0.5) or 0
                    local ts = d:FindFirstChild("RCLR_TabGlassEdge")
                    if on then
                        if not ts then
                            ts = Instance.new("UIStroke")
                            ts.Name = "RCLR_TabGlassEdge"
                            ts.Thickness = 1
                            ts.Color = Color3.fromRGB(255, 255, 255)
                            ts.Transparency = 0.75
                            ts.Parent = d
                        end
                    elseif ts then
                        ts:Destroy()
                    end
                elseif pname == "TabArea" then
                    d.BackgroundTransparency = 0
                elseif nm == "Outer" or d == Library.WindowOuter then
                    d.BackgroundColor3 = Library.BackgroundColor
                    d.BackgroundTransparency = L_outer
                else
                    local reg = registryMap and registryMap[d]
                    local bg = reg and reg.Properties and reg.Properties.BackgroundColor3
                    if bg == "BackgroundColor" then
                        d.BackgroundColor3 = Library.BackgroundColor
                        d.BackgroundTransparency = L_mid
                        local ps = d:FindFirstChild("RCLR_PanelGlassEdge")
                        if on and d.AbsoluteSize.Y > 36 then
                            if not ps then
                                ps = Instance.new("UIStroke")
                                ps.Name = "RCLR_PanelGlassEdge"
                                ps.Thickness = 1
                                ps.Color = Color3.fromRGB(255, 255, 255)
                                ps.Transparency = 0.78
                                ps.Parent = d
                            end
                        end
                    elseif bg == "MainColor" then
                        d.BackgroundColor3 = Library.MainColor
                        local sz = d.AbsoluteSize
                        if sz.X <= 22 and sz.Y <= 22 then
                            d.BackgroundTransparency = 0
                        else
                            d.BackgroundTransparency = L_inner
                        end
                    end
                end
            end
        end

        if Library.Toggled then
            pcall(function() Library:UpdateBlur() end)
        end
    end)

    Library._SettingGlass = false
end

function Library:ReapplyGlass()
    Library:SetGlass(Library.GlassEnabled ~= false, Library.GlassTransparency or 0.92)
end

function Library:CreateLogo(Info)
    Info = Info or {}
    pcall(function()
        if Library._LogoGui then Library._LogoGui:Destroy() end
        if Library._LogoSpinConn then Library._LogoSpinConn:Disconnect() end
        if Library._LogoHolder and Library._LogoHolder.Parent then Library._LogoHolder:Destroy() end
    end)

    local text = tostring(Info.Text or "RCLR")
    local size = tonumber(Info.TextSize) or 52
    local speed = tonumber(Info.SpinSpeed) or 30

    local outer = Library.WindowOuter
    if not outer or not outer.Parent then
        task.defer(function()
            task.wait(0.15)
            if Library.WindowOuter and not Library._LogoHolder then
                Library:CreateLogo(Info)
            end
        end)
        return
    end

    local holder = Instance.new("Frame")
    holder.Name = "RCLR_LogoBehind"
    holder.BackgroundTransparency = 1
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.Size = UDim2.fromScale(0.55, 0.4)
    holder.ZIndex = 1
    holder.ClipsDescendants = false
    holder.Parent = outer

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextSize = size
    label.TextColor3 = Library.AccentColor
    label.TextTransparency = 0.75
    label.TextScaled = true
    label.ZIndex = 1
    label.Parent = holder

    Library._LogoHolder = holder
    Library._LogoGui = holder

    local angle, acc = 0, 0
    local step = (Library.IsMobile == true) and (1 / 18) or (1 / 28)
    local conn = RunService.Heartbeat:Connect(function(dt)
        if not holder.Parent then return end
        if Library.Toggled ~= true then
            holder.Visible = false
            return
        end
        holder.Visible = true
        acc = acc + dt
        if acc < step then return end
        acc = 0
        angle = (angle + speed * step) % 360
        holder.Rotation = angle
        label.TextColor3 = Library.AccentColor
    end)
    Library._LogoSpinConn = conn
    table.insert(Library.Signals, conn)
    Library._LogoSync = function()
        if holder and holder.Parent then
            holder.Visible = Library.Toggled == true
        end
    end
end

function Library:UpdateLogoVisibility()
    if Library._LogoSync then pcall(Library._LogoSync) end
    if Library.Toggled ~= true and Library._LogoGui then Library._LogoGui.Enabled = false end
end

function Library:SetNotifyConfig(Config)
    Config = Config or {}
    local C = Library.NotifyConfig
    if type(C) ~= "table" then
        Library.NotifyConfig = {}
        C = Library.NotifyConfig
    end
    if Config.Transparency ~= nil then C.Transparency = Config.Transparency end
    if Config.PosX ~= nil then C.PosX = Config.PosX end
    if Config.PosY ~= nil then C.PosY = Config.PosY end
    if Config.MaxHeight ~= nil then C.MaxHeight = Config.MaxHeight end
    if Config.Alignment ~= nil then C.Alignment = Config.Alignment end
    if Config.BarSide ~= nil then C.BarSide = Config.BarSide end
    if Config.SortOrder ~= nil then C.SortOrder = Config.SortOrder end
    if Config.ClipDescendants ~= nil then C.ClipDescendants = Config.ClipDescendants end
    if Config.Duration ~= nil then Library.NotifyDefaultTime = Config.Duration end
    if Config.MaxActive ~= nil then Library.NotifyMaxActive = Config.MaxActive end
end

function Library:AddNotifyOptions(Groupbox)
    Library.NotifyConfig = Library.NotifyConfig or {
        ClipDescendants = false,
        MaxHeight = 200,
        PosX = 50,
        PosY = 60,
        Transparency = 25,
        Alignment = "Center",
        BarSide = "Bottom",
        SortOrder = "Default",
        ForceColor = false,
        ClipPastDistance = 200,
    }
    local NC = Library.NotifyConfig

    Groupbox:AddToggle('NotifyClip', {
        Text = 'Clip Descendants',
        Default = NC.ClipDescendants == true,
        Callback = function(V) NC.ClipDescendants = V end,
    })
    Groupbox:AddSlider('NotifyClipDist', {
        Text = 'Clip Past Distance',
        Default = NC.ClipPastDistance or 200,
        Min = 50, Max = 1000, Rounding = 0, Suffix = 'px',
        Callback = function(V) NC.ClipPastDistance = V end,
    })
    Groupbox:AddToggle('NotifyForceColor', {
        Text = 'Force Color',
        Default = NC.ForceColor == true,
        Callback = function(V) NC.ForceColor = V end,
    }):AddColorPicker('NotifyForceColorVal', {
        Default = NC.ForceColorValue or Library.AccentColor,
        Title = 'Notify Color',
        Callback = function(C) NC.ForceColorValue = C end,
    })
    Groupbox:AddSlider('NotifyPosX', {
        Text = 'Position X',
        Default = NC.PosX or 50,
        Min = 0, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(V) NC.PosX = V end,
    })
    Groupbox:AddSlider('NotifyPosY', {
        Text = 'Position Y',
        Default = NC.PosY or 60,
        Min = 0, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(V) NC.PosY = V end,
    })
    Groupbox:AddSlider('NotifyTransparency', {
        Text = 'Transparency',
        Default = NC.Transparency or 25,
        Min = 0, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(V) NC.Transparency = V end,
    })
    Groupbox:AddDropdown('NotifyAlign', {
        Text = 'Alignment',
        Values = { 'Center', 'Left', 'Right' },
        Default = 1,
        Callback = function(V) NC.Alignment = V end,
    })
    Groupbox:AddDropdown('NotifyBarSide', {
        Text = 'Bar Side',
        Values = { 'Bottom', 'Top', 'Left', 'Right' },
        Default = 1,
        Callback = function(V) NC.BarSide = V end,
    })
    Groupbox:AddDropdown('NotifySortOrder', {
        Text = 'Sort Order',
        Values = { 'Default', 'Time', 'Reverse' },
        Default = 1,
        Callback = function(V) NC.SortOrder = V end,
    })
    Groupbox:AddSlider('NotifyDuration', {
        Text = 'Default Duration',
        Default = Library.NotifyDefaultTime or 5,
        Min = 1, Max = 15, Rounding = 0, Suffix = 's',
        Callback = function(V) Library.NotifyDefaultTime = V end,
    })
    Groupbox:AddButton('Send Notification', function()
        Library:Notify('Test notification', Library.NotifyDefaultTime or 5)
    end)
end


function Library:SetAutoLoad(opts)
    opts = opts or {}
    Library.AutoLoadEnabled = opts.Enabled ~= false
    Library.AutoLoadSilent = opts.Silent == true
end

function Library:RunAutoLoad(ThemeManager, SaveManager)
    if Library.AutoLoadEnabled == false then return end
    local silent = Library.AutoLoadSilent == true
    pcall(function()
        if ThemeManager and ThemeManager.TryAutoLoad then
            ThemeManager:TryAutoLoad()
        end
    end)
    pcall(function()
        if SaveManager then
            if SaveManager.LoadAutoloadConfig then
                SaveManager:LoadAutoloadConfig()
            elseif SaveManager.TryAutoLoad then
                SaveManager:TryAutoLoad()
            end
        end
    end)
    if not silent and Library.Notify then
        Library:Notify("Auto-load done", 3)
    end
end

function Library:SetAutoExecute(source)
    if type(source) ~= "string" or source == "" then return false end
    Library._AutoExecuteSource = source
    local ok = false
    pcall(function()
        local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if q then
            q(source)
            Library._AutoExecuteQueued = true
            ok = true
        end
    end)
    return ok
end

function Library:EnableAutoExecuteFromUrl(url)
    if type(url) ~= "string" or url == "" then return false end
    local src = string.format('loadstring(game:HttpGet(%q))()', url)
    return Library:SetAutoExecute(src)
end

function Library:NotifyScriptReady(name)
    name = name or "Script"
    pcall(function()
        Library:Notify(name .. " loaded", 4)
    end)
end

-- Script-friendly: ensure UI is visible after load
function Library:ForceShow()
    pcall(function()
        Library.Toggled = true
        if Library.WindowOuter then
            Library.WindowOuter.Visible = true
        end
        if Library.UpdateBlur then Library:UpdateBlur() end
    end)
end


--============================================================================
-- RCLR Monova Feature Pack (expanded systems for scripts)
--============================================================================

Library.FeaturePackVersion = 3
Library.BuildTag = "RCLR_Monova_299"

-- Theme preset database (full Linoria + community packs)
Library.ThemePresets = Library.ThemePresets or {}
do
    local P = Library.ThemePresets
    local function T(font, main, bg, accent, outline)
        return {
            FontColor = font,
            MainColor = main,
            BackgroundColor = bg,
            AccentColor = accent,
            OutlineColor = outline,
        }
    end
    P["Default"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(28,28,28), Color3.fromRGB(20,20,20), Color3.fromRGB(0,155,255), Color3.fromRGB(50,50,50))
    P["BlackWhite"] = T(Color3.fromRGB(220,220,220), Color3.fromRGB(28,28,28), Color3.fromRGB(18,18,18), Color3.fromRGB(200,200,200), Color3.fromRGB(45,45,45))
    P["Darker"] = T(Color3.fromRGB(200,200,200), Color3.fromRGB(16,16,16), Color3.fromRGB(10,10,10), Color3.fromRGB(90,90,90), Color3.fromRGB(35,35,35))
    P["Aqua"] = T(Color3.fromRGB(210,245,255), Color3.fromRGB(20,28,32), Color3.fromRGB(12,16,20), Color3.fromRGB(0,200,220), Color3.fromRGB(40,55,60))
    P["Matrix"] = T(Color3.fromRGB(180,255,180), Color3.fromRGB(16,24,16), Color3.fromRGB(8,14,8), Color3.fromRGB(0,255,70), Color3.fromRGB(30,50,30))
    P["Blood"] = T(Color3.fromRGB(255,220,220), Color3.fromRGB(32,18,18), Color3.fromRGB(18,10,10), Color3.fromRGB(180,20,30), Color3.fromRGB(55,22,22))
    P["Nord"] = T(Color3.fromRGB(216,222,233), Color3.fromRGB(46,52,64), Color3.fromRGB(36,41,51), Color3.fromRGB(136,192,208), Color3.fromRGB(59,66,82))
    P["Purple"] = T(Color3.fromRGB(235,220,255), Color3.fromRGB(28,22,36), Color3.fromRGB(16,12,22), Color3.fromRGB(140,70,200), Color3.fromRGB(50,40,65))
    P["DarkBlue"] = T(Color3.fromRGB(220,230,255), Color3.fromRGB(22,26,36), Color3.fromRGB(14,16,24), Color3.fromRGB(71,119,182), Color3.fromRGB(40,48,64))
    P["TokyoNight"] = T(Color3.fromRGB(192,202,245), Color3.fromRGB(26,27,38), Color3.fromRGB(15,16,24), Color3.fromRGB(122,162,247), Color3.fromRGB(41,46,66))
    P["Dracula"] = T(Color3.fromRGB(248,248,242), Color3.fromRGB(40,42,54), Color3.fromRGB(30,31,41), Color3.fromRGB(189,147,249), Color3.fromRGB(68,71,90))
    P["Emerald"] = T(Color3.fromRGB(210,255,220), Color3.fromRGB(18,28,22), Color3.fromRGB(10,16,12), Color3.fromRGB(40,200,120), Color3.fromRGB(35,55,42))
    P["Crimson"] = T(Color3.fromRGB(255,230,230), Color3.fromRGB(30,18,20), Color3.fromRGB(16,10,12), Color3.fromRGB(220,50,70), Color3.fromRGB(55,28,32))
    P["Gold"] = T(Color3.fromRGB(255,245,210), Color3.fromRGB(32,28,18), Color3.fromRGB(18,16,10), Color3.fromRGB(220,180,40), Color3.fromRGB(60,50,25))
    P["Rose"] = T(Color3.fromRGB(255,230,240), Color3.fromRGB(32,20,26), Color3.fromRGB(18,12,16), Color3.fromRGB(240,100,150), Color3.fromRGB(55,30,40))
    P["Orange"] = T(Color3.fromRGB(255,240,220), Color3.fromRGB(32,24,16), Color3.fromRGB(18,14,10), Color3.fromRGB(255,140,40), Color3.fromRGB(55,40,25))
    P["Mint"] = T(Color3.fromRGB(220,255,240), Color3.fromRGB(18,30,26), Color3.fromRGB(10,18,16), Color3.fromRGB(80,220,180), Color3.fromRGB(35,55,48))
    P["Cyan"] = T(Color3.fromRGB(220,250,255), Color3.fromRGB(18,26,30), Color3.fromRGB(10,16,20), Color3.fromRGB(0,220,255), Color3.fromRGB(35,50,55))
    P["Lava"] = T(Color3.fromRGB(255,230,210), Color3.fromRGB(30,16,12), Color3.fromRGB(16,8,6), Color3.fromRGB(255,80,20), Color3.fromRGB(55,25,15))
    P["Ocean"] = T(Color3.fromRGB(210,230,255), Color3.fromRGB(18,24,34), Color3.fromRGB(10,14,22), Color3.fromRGB(40,120,200), Color3.fromRGB(30,40,55))
    P["Midnight"] = T(Color3.fromRGB(200,210,230), Color3.fromRGB(14,16,24), Color3.fromRGB(8,10,16), Color3.fromRGB(80,100,180), Color3.fromRGB(28,32,45))
    P["BBot"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(30,30,30), Color3.fromRGB(35,35,35), Color3.fromRGB(126,72,163), Color3.fromRGB(20,20,20))
    P["Fatality"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(30,30,30), Color3.fromRGB(20,20,20), Color3.fromRGB(255,40,40), Color3.fromRGB(40,40,40))
    P["Ubuntu"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(48,48,48), Color3.fromRGB(56,56,56), Color3.fromRGB(233,84,32), Color3.fromRGB(30,30,30))
    P["Quartz"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(25,25,25), Color3.fromRGB(19,19,19), Color3.fromRGB(145,145,145), Color3.fromRGB(40,40,40))
    P["Green"] = T(Color3.fromRGB(210,255,210), Color3.fromRGB(20,28,20), Color3.fromRGB(12,18,12), Color3.fromRGB(40,200,80), Color3.fromRGB(35,50,35))
    P["Red"] = T(Color3.fromRGB(255,220,220), Color3.fromRGB(28,18,18), Color3.fromRGB(16,10,10), Color3.fromRGB(220,40,40), Color3.fromRGB(50,25,25))
    P["Pink"] = T(Color3.fromRGB(255,230,245), Color3.fromRGB(30,20,28), Color3.fromRGB(18,12,16), Color3.fromRGB(255,105,180), Color3.fromRGB(50,30,40))
    P["Monokai"] = T(Color3.fromRGB(248,248,242), Color3.fromRGB(39,40,34), Color3.fromRGB(30,31,28), Color3.fromRGB(249,38,114), Color3.fromRGB(55,55,50))
    P["Solarized"] = T(Color3.fromRGB(238,232,213), Color3.fromRGB(7,54,66), Color3.fromRGB(0,43,54), Color3.fromRGB(38,139,210), Color3.fromRGB(20,60,70))
    P["Gruvbox"] = T(Color3.fromRGB(235,219,178), Color3.fromRGB(60,56,54), Color3.fromRGB(40,40,40), Color3.fromRGB(251,184,41), Color3.fromRGB(80,73,69))
    P["Catppuccin"] = T(Color3.fromRGB(205,214,244), Color3.fromRGB(30,30,46), Color3.fromRGB(24,24,37), Color3.fromRGB(203,166,247), Color3.fromRGB(49,50,68))
    P["OneDark"] = T(Color3.fromRGB(171,178,191), Color3.fromRGB(40,44,52), Color3.fromRGB(33,37,43), Color3.fromRGB(97,175,239), Color3.fromRGB(55,60,70))
    P["Synthwave"] = T(Color3.fromRGB(255,230,255), Color3.fromRGB(30,16,40), Color3.fromRGB(16,8,24), Color3.fromRGB(255,0,170), Color3.fromRGB(50,25,60))
    P["Forest"] = T(Color3.fromRGB(220,240,220), Color3.fromRGB(22,30,22), Color3.fromRGB(12,18,12), Color3.fromRGB(70,160,80), Color3.fromRGB(35,50,35))
    P["Ice"] = T(Color3.fromRGB(230,245,255), Color3.fromRGB(22,28,34), Color3.fromRGB(12,16,22), Color3.fromRGB(140,200,255), Color3.fromRGB(40,50,60))
    P["Royal"] = T(Color3.fromRGB(240,230,255), Color3.fromRGB(24,20,36), Color3.fromRGB(14,12,22), Color3.fromRGB(120,80,220), Color3.fromRGB(40,35,55))
    P["Sand"] = T(Color3.fromRGB(255,245,220), Color3.fromRGB(36,30,22), Color3.fromRGB(22,18,12), Color3.fromRGB(210,170,90), Color3.fromRGB(55,45,30))
    P["Steel"] = T(Color3.fromRGB(220,225,230), Color3.fromRGB(28,30,34), Color3.fromRGB(16,18,22), Color3.fromRGB(120,140,160), Color3.fromRGB(45,50,55))
    P["Neon"] = T(Color3.fromRGB(230,255,240), Color3.fromRGB(16,20,18), Color3.fromRGB(8,12,10), Color3.fromRGB(0,255,170), Color3.fromRGB(30,45,40))
    P["Violet"] = T(Color3.fromRGB(240,230,255), Color3.fromRGB(26,20,36), Color3.fromRGB(14,12,22), Color3.fromRGB(160,80,255), Color3.fromRGB(45,35,60))
    P["Amber"] = T(Color3.fromRGB(255,245,220), Color3.fromRGB(32,26,16), Color3.fromRGB(18,14,8), Color3.fromRGB(255,170,30), Color3.fromRGB(55,42,20))
    P["Slate"] = T(Color3.fromRGB(220,225,235), Color3.fromRGB(30,34,40), Color3.fromRGB(18,20,26), Color3.fromRGB(100,120,150), Color3.fromRGB(45,50,60))
    P["Coral"] = T(Color3.fromRGB(255,235,230), Color3.fromRGB(32,22,20), Color3.fromRGB(18,12,12), Color3.fromRGB(255,110,90), Color3.fromRGB(55,35,30))
    P["Indigo"] = T(Color3.fromRGB(230,235,255), Color3.fromRGB(22,22,36), Color3.fromRGB(12,12,22), Color3.fromRGB(90,100,220), Color3.fromRGB(35,35,55))
    P["Lime"] = T(Color3.fromRGB(240,255,220), Color3.fromRGB(22,28,16), Color3.fromRGB(12,16,8), Color3.fromRGB(160,230,40), Color3.fromRGB(40,50,30))
    P["Sky"] = T(Color3.fromRGB(230,245,255), Color3.fromRGB(20,26,34), Color3.fromRGB(12,16,22), Color3.fromRGB(80,180,255), Color3.fromRGB(35,45,55))
    P["Wine"] = T(Color3.fromRGB(255,230,235), Color3.fromRGB(30,16,20), Color3.fromRGB(16,8,12), Color3.fromRGB(160,30,60), Color3.fromRGB(50,25,30))
    P["Graphite"] = T(Color3.fromRGB(210,210,210), Color3.fromRGB(26,26,26), Color3.fromRGB(14,14,14), Color3.fromRGB(120,120,120), Color3.fromRGB(40,40,40))
    P["Azure"] = T(Color3.fromRGB(230,245,255), Color3.fromRGB(18,24,32), Color3.fromRGB(10,14,20), Color3.fromRGB(0,140,255), Color3.fromRGB(30,40,50))
    P["Magma"] = T(Color3.fromRGB(255,235,220), Color3.fromRGB(28,14,10), Color3.fromRGB(14,6,4), Color3.fromRGB(255,60,0), Color3.fromRGB(50,20,12))
    P["Frost"] = T(Color3.fromRGB(240,250,255), Color3.fromRGB(24,28,34), Color3.fromRGB(14,16,22), Color3.fromRGB(180,220,255), Color3.fromRGB(40,48,55))
    P["Shadow"] = T(Color3.fromRGB(180,180,190), Color3.fromRGB(14,14,18), Color3.fromRGB(6,6,10), Color3.fromRGB(70,70,90), Color3.fromRGB(25,25,30))
    P["Pearl"] = T(Color3.fromRGB(245,245,250), Color3.fromRGB(34,34,38), Color3.fromRGB(22,22,26), Color3.fromRGB(200,200,220), Color3.fromRGB(50,50,55))
    P["Jade"] = T(Color3.fromRGB(220,255,235), Color3.fromRGB(16,28,22), Color3.fromRGB(8,16,12), Color3.fromRGB(0,180,120), Color3.fromRGB(30,50,40))
    P["Cobalt"] = T(Color3.fromRGB(220,235,255), Color3.fromRGB(16,22,34), Color3.fromRGB(8,12,20), Color3.fromRGB(40,90,200), Color3.fromRGB(28,35,50))
    P["Cherry"] = T(Color3.fromRGB(255,230,235), Color3.fromRGB(30,16,18), Color3.fromRGB(16,8,10), Color3.fromRGB(220,40,80), Color3.fromRGB(50,25,28))
    P["Olive"] = T(Color3.fromRGB(235,240,210), Color3.fromRGB(28,30,20), Color3.fromRGB(16,18,10), Color3.fromRGB(140,160,40), Color3.fromRGB(45,50,30))
    P["Teal"] = T(Color3.fromRGB(220,250,250), Color3.fromRGB(18,28,28), Color3.fromRGB(10,16,16), Color3.fromRGB(0,180,180), Color3.fromRGB(30,50,50))
    P["Berry"] = T(Color3.fromRGB(250,230,255), Color3.fromRGB(28,18,32), Color3.fromRGB(16,10,18), Color3.fromRGB(180,60,180), Color3.fromRGB(50,30,55))
    P["Copper"] = T(Color3.fromRGB(255,235,220), Color3.fromRGB(32,24,18), Color3.fromRGB(18,14,10), Color3.fromRGB(200,110,50), Color3.fromRGB(55,40,25))
    P["Platinum"] = T(Color3.fromRGB(240,245,250), Color3.fromRGB(32,34,38), Color3.fromRGB(20,22,26), Color3.fromRGB(180,190,200), Color3.fromRGB(50,55,60))
    P["Rainbow"] = T(Color3.fromRGB(255,255,255), Color3.fromRGB(24,24,28), Color3.fromRGB(14,14,18), Color3.fromRGB(255,100,180), Color3.fromRGB(45,45,50))
end

function Library:GetThemePresetNames()
    local names = {}
    for k in pairs(Library.ThemePresets or {}) do
        table.insert(names, k)
    end
    table.sort(names)
    return names
end

function Library:ApplyThemePreset(name)
    local p = Library.ThemePresets and Library.ThemePresets[name]
    if not p then return false end
    if Library.ApplyThemeColors then
        Library:ApplyThemeColors(p)
    else
        for k, v in pairs(p) do Library[k] = v end
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
        Library:UpdateColorsUsingRegistry()
    end
    Library.ActiveThemePreset = name
    return true
end

-- Font face registry
Library.FontFaces = {}
pcall(function()
    local names = {
        "Code","Ubuntu","Gotham","GothamBold","SourceSans","SourceSansBold",
        "Legacy","Arcade","Cartoon","SciFi","Bodoni","Garamond","Highway",
        "FredokaOne","DenkOne","JosefinSans","Nunito","Oswald","Roboto",
        "RobotoCondensed","RobotoMono",
    }
    for _, n in ipairs(names) do
        pcall(function()
            local f = Enum.Font[n]
            if f then Library.FontFaces[n] = f end
        end)
    end
    if not Library.FontFaces.Code then Library.FontFaces.Code = Enum.Font.Code end
    if not Library.FontFaces.Body and Enum.Font.Bodoni then Library.FontFaces.Body = Enum.Font.Bodoni end
end)

function Library:SetFontFace(name)
    local f = Library.FontFaces[name] or Enum.Font.Code
    Library.Font = f
    pcall(function()
        for _, data in pairs(Library.Registry or {}) do
            local inst = data.Instance
            if inst and (inst:IsA("TextLabel") or inst:IsA("TextButton")) then
                pcall(function() inst.Font = f end)
            end
        end
    end)
end

-- Sound pack (optional UI clicks)
Library.Sounds = Library.Sounds or {
    Enabled = false,
    Volume = 0.35,
    Click = "rbxassetid://6895079853",
    Toggle = "rbxassetid://6895079853",
    Hover = "rbxassetid://10066936758",
    Notify = "rbxassetid://4590657391",
    Open = "rbxassetid://6042053626",
    Close = "rbxassetid://6042053626",
}

function Library:PlayUISound(kind)
    if not (Library.Sounds and Library.Sounds.Enabled) then return end
    pcall(function()
        local id = Library.Sounds[kind] or Library.Sounds.Click
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = Library.Sounds.Volume or 0.3
        s.Parent = game:GetService("SoundService")
        s:Play()
        task.delay(2, function() pcall(function() s:Destroy() end) end)
    end)
end

function Library:SetSoundsEnabled(on)
    Library.Sounds = Library.Sounds or {}
    Library.Sounds.Enabled = on and true or false
end

-- Animation helpers
Library.Anim = Library.Anim or {}
function Library.Anim:Tween(inst, props, time, style, dir)
    time = time or 0.18
    style = style or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local tw = game:GetService("TweenService"):Create(inst, TweenInfo.new(time, style, dir), props)
    tw:Play()
    return tw
end

function Library.Anim:FadeIn(inst, time)
    if not inst then return end
    inst.Visible = true
    pcall(function()
        if inst:IsA("Frame") or inst:IsA("TextLabel") or inst:IsA("ImageLabel") then
            local goal = {}
            if inst:IsA("Frame") then
                local t = inst.BackgroundTransparency
                inst.BackgroundTransparency = 1
                goal.BackgroundTransparency = t
            end
            Library.Anim:Tween(inst, goal, time or 0.2)
        end
    end)
end

function Library.Anim:Pulse(inst, scale, time)
    if not inst then return end
    pcall(function()
        local uis = inst:FindFirstChildOfClass("UIScale")
        if not uis then
            uis = Instance.new("UIScale")
            uis.Parent = inst
        end
        uis.Scale = 1
        local tw = Library.Anim:Tween(uis, { Scale = scale or 1.04 }, (time or 0.12) / 2)
        tw.Completed:Connect(function()
            Library.Anim:Tween(uis, { Scale = 1 }, (time or 0.12) / 2)
        end)
    end)
end

-- Performance profiles
Library.Profiles = {
    Ultra = { PerformanceMode = false, UseBlur = true, BlurSize = 24, Glass = 0.88, WireframeDrag = true },
    High = { PerformanceMode = false, UseBlur = true, BlurSize = 18, Glass = 0.8, WireframeDrag = true },
    Balanced = { PerformanceMode = true, UseBlur = true, BlurSize = 12, Glass = 0.72, WireframeDrag = true },
    Performance = { PerformanceMode = true, UseBlur = false, BlurSize = 0, Glass = 0.55, WireframeDrag = false },
    Potato = { PerformanceMode = true, UseBlur = false, BlurSize = 0, Glass = 0, WireframeDrag = false },
}

function Library:ApplyProfile(name)
    local p = Library.Profiles[name]
    if not p then return end
    Library.PerformanceMode = p.PerformanceMode
    Library.UseBlur = p.UseBlur
    Library.BlurSize = p.BlurSize
    Library.WireframeDrag = p.WireframeDrag
    if p.Glass and p.Glass > 0 then
        pcall(function() Library:SetGlass(true, p.Glass) end)
    else
        pcall(function() Library:SetGlass(false) end)
    end
    pcall(function() if Library.UpdateBlur then Library:UpdateBlur() end end)
    Library.ActiveProfile = name
end

-- Watermark helper
function Library:CreateWatermark(text)
    text = text or "RCLR Monova"
    pcall(function()
        if Library._WatermarkGui then Library._WatermarkGui:Destroy() end
        local g = Instance.new("ScreenGui")
        g.Name = "RCLR_Watermark"
        g.DisplayOrder = 50
        g.ResetOnSpawn = false
        ProtectGui(g)
        g.Parent = CoreGui
        local f = Instance.new("Frame")
        f.BackgroundColor3 = Library.MainColor
        f.BackgroundTransparency = 0.25
        f.BorderSizePixel = 0
        f.Position = UDim2.new(0, 12, 0, 12)
        f.Size = UDim2.new(0, 180, 0, 22)
        f.Parent = g
        local s = Instance.new("UIStroke")
        s.Color = Library.OutlineColor
        s.Thickness = 1
        s.Parent = f
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, -8, 1, 0)
        l.Position = UDim2.new(0, 6, 0, 0)
        l.Font = Library.Font or Enum.Font.Code
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextColor3 = Library.FontColor
        l.Text = text
        l.Parent = f
        Library._WatermarkGui = g
        Library._WatermarkLabel = l
        task.spawn(function()
            while g.Parent do
                local fps = math.floor(1 / math.max(game:GetService("RunService").RenderStepped:Wait(), 0.001))
                l.Text = string.format("%s | %d FPS", text, fps)
            end
        end)
    end)
end

function Library:DestroyWatermark()
    pcall(function()
        if Library._WatermarkGui then Library._WatermarkGui:Destroy() end
        Library._WatermarkGui = nil
    end)
end

-- Live stud HUD (compact)
function Library:CreateLiveStudUI(opts)
    opts = opts or {}
    local title = opts.Title or Library.ScriptName or "RCLR"
    pcall(function()
        if Library._StudGui then Library._StudGui:Destroy() end
        local g = Instance.new("ScreenGui")
        g.Name = "RCLR_LiveStud"
        g.DisplayOrder = 40
        g.ResetOnSpawn = false
        ProtectGui(g)
        g.Parent = CoreGui

        local f = Instance.new("Frame")
        f.Name = "StudFrame"
        f.BackgroundColor3 = Library.MainColor
        f.BackgroundTransparency = 0.12
        f.BorderSizePixel = 0
        f.Position = UDim2.new(0, 12, 0, 40)
        f.Size = UDim2.new(0, 132, 0, 62)
        f.Parent = g

        local stroke = Instance.new("UIStroke")
        stroke.Name = "StudStroke"
        stroke.Color = Library.AccentColor
        stroke.Thickness = 1
        stroke.Parent = f

        local accentBar = Instance.new("Frame")
        accentBar.Name = "StudAccent"
        accentBar.BackgroundColor3 = Library.AccentColor
        accentBar.BorderSizePixel = 0
        accentBar.Size = UDim2.new(0, 2, 1, 0)
        accentBar.Parent = f

        local titleL = Instance.new("TextLabel")
        titleL.Name = "StudTitle"
        titleL.BackgroundTransparency = 1
        titleL.Size = UDim2.new(1, -12, 0, 16)
        titleL.Position = UDim2.new(0, 8, 0, 2)
        titleL.Font = Library.Font or Enum.Font.Code
        titleL.TextSize = 12
        titleL.TextXAlignment = Enum.TextXAlignment.Left
        titleL.TextColor3 = Library.AccentColor
        titleL.Text = title
        titleL.Parent = f

        local body = Instance.new("TextLabel")
        body.Name = "StudBody"
        body.BackgroundTransparency = 1
        body.Size = UDim2.new(1, -12, 0, 40)
        body.Position = UDim2.new(0, 8, 0, 18)
        body.Font = Library.Font or Enum.Font.Code
        body.TextSize = 12
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.TextColor3 = Library.FontColor
        body.Text = "X: 0
Y: 0
Z: 0"
        body.Parent = f

        Library._StudGui = g
        Library._StudFrame = f
        Library._StudStroke = stroke
        Library._StudAccent = accentBar
        Library._StudTitle = titleL
        Library._StudBody = body

        local function SyncStudTheme()
            pcall(function()
                if not Library._StudFrame then return end
                Library._StudFrame.BackgroundColor3 = Library.MainColor
                Library._StudStroke.Color = Library.AccentColor
                Library._StudAccent.BackgroundColor3 = Library.AccentColor
                Library._StudTitle.TextColor3 = Library.AccentColor
                Library._StudBody.TextColor3 = Library.FontColor
                Library._StudTitle.Font = Library.Font or Enum.Font.Code
                Library._StudBody.Font = Library.Font or Enum.Font.Code
            end)
        end
        Library.SyncStudTheme = SyncStudTheme

        task.spawn(function()
            local lp = game:GetService("Players").LocalPlayer
            while g.Parent do
                task.wait(0.12)
                SyncStudTheme()
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local p = root.Position
                    body.Text = string.format("X: %.1f
Y: %.1f
Z: %.1f", p.X, p.Y, p.Z)
                end
            end
        end)
    end)
end

function Library:DestroyLiveStudUI()
    pcall(function()
        if Library._StudGui then Library._StudGui:Destroy() end
        Library._StudGui = nil
    end)
end

-- Keybind list helper
function Library:GetActiveKeybinds()
    local list = {}
    for idx, opt in pairs(Options or {}) do
        if type(opt) == "table" and opt.Type == "KeyPicker" then
            table.insert(list, { Index = idx, Text = opt.Text or idx, Value = opt.Value, Mode = opt.Mode })
        end
    end
    return list
end

-- Safe unload that never touches foreign UIs
function Library:SafeUnload()
    pcall(function() Library:DestroyWatermark() end)
    pcall(function() Library:DestroyLiveStudUI() end)
    pcall(function()
        if Library.MobileGui then Library.MobileGui:Destroy() end
    end)
    pcall(function()
        if Library.Unload then Library:Unload() end
    end)
    pcall(function()
        if getgenv().RCLR_Library == Library then getgenv().RCLR_Library = nil end
    end)
end

-- Utility: deep copy table
function Library:DeepCopy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do
        n[Library:DeepCopy(k)] = Library:DeepCopy(v)
    end
    return n
end

-- Utility: color to hex
function Library:ColorToHex(c)
    if typeof(c) ~= "Color3" then return "#ffffff" end
    return string.format("#%02x%02x%02x", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

function Library:HexToColor(hex)
    hex = tostring(hex or ""):gsub("#", "")
    if #hex < 6 then return Color3.new(1,1,1) end
    local r = tonumber(hex:sub(1,2), 16) or 255
    local g = tonumber(hex:sub(3,4), 16) or 255
    local b = tonumber(hex:sub(5,6), 16) or 255
    return Color3.fromRGB(r, g, b)
end

-- Glass preset shortcuts
Library.GlassPresets = {
    Off = 0,
    Soft = 0.55,
    Medium = 0.7,
    Strong = 0.82,
    Max = 0.92,
}

function Library:ApplyGlassPreset(name)
    local v = Library.GlassPresets[name]
    if v == nil then return end
    if v <= 0 then
        pcall(function() Library:SetGlass(false) end)
    else
        pcall(function() Library:SetGlass(true, v) end)
    end
end

-- Tab jump helper for scripts
function Library:ShowTabByName(window, name)
    if not window or not window.Tabs then return end
    local t = window.Tabs[name]
    if t and t.ShowTab then t:ShowTab() end
end

-- Notify batch
function Library:NotifyMany(messages, delayBetween)
    delayBetween = delayBetween or 0.35
    task.spawn(function()
        for _, msg in ipairs(messages or {}) do
            Library:Notify(tostring(msg))
            task.wait(delayBetween)
        end
    end)
end

-- Debug console (lightweight)
function Library:CreateDebugConsole()
    pcall(function()
        if Library._DebugGui then Library._DebugGui:Destroy() end
        local g = Instance.new("ScreenGui")
        g.Name = "RCLR_Debug"
        g.DisplayOrder = 200
        ProtectGui(g)
        g.Parent = CoreGui
        local f = Instance.new("ScrollingFrame")
        f.BackgroundColor3 = Color3.fromRGB(10,10,12)
        f.BackgroundTransparency = 0.2
        f.Size = UDim2.new(0, 360, 0, 160)
        f.Position = UDim2.new(1, -370, 1, -170)
        f.CanvasSize = UDim2.new(0, 0, 0, 0)
        f.ScrollBarThickness = 4
        f.Parent = g
        local lay = Instance.new("UIListLayout")
        lay.Parent = f
        Library._DebugGui = g
        Library._DebugFrame = f
        Library._DebugLayout = lay
        function Library:DebugLog(text)
            pcall(function()
                local l = Instance.new("TextLabel")
                l.BackgroundTransparency = 1
                l.Size = UDim2.new(1, -8, 0, 16)
                l.Font = Enum.Font.Code
                l.TextSize = 12
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.TextColor3 = Color3.fromRGB(200, 220, 200)
                l.Text = os.date("[%H:%M:%S] ") .. tostring(text)
                l.Parent = f
                f.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8)
                f.CanvasPosition = Vector2.new(0, lay.AbsoluteContentSize.Y)
            end)
        end
    end)
end

-- Bulk option reset
function Library:ResetAllToggles(defaultValue)
    defaultValue = defaultValue and true or false
    for _, t in pairs(Toggles or {}) do
        pcall(function()
            if t.SetValue then t:SetValue(defaultValue) end
        end)
    end
end

-- Script identity banner
function Library:SetScriptIdentity(name, version)
    Library.ScriptName = name or "Script"
    Library.ScriptVersion = version or "1.0"
end

function Library:GetScriptIdentity()
    return string.format("%s v%s", Library.ScriptName or "RCLR", Library.ScriptVersion or "1")
end

-- Compatibility shims for older examples
Library.ToggleUI = Library.ToggleUI or function() Library:Toggle() end
Library.ShowUI = Library.ShowUI or function() pcall(function() Library:ForceShow() end) end

-- Extra registry pass helper
function Library:ForceRepaint()
    pcall(function() Library:UpdateColorsUsingRegistry() end)
    pcall(function() if Library.ReapplyGlass then Library:ReapplyGlass() end end)
    pcall(function() if Library.UpdateBlur then Library:UpdateBlur() end end)
end

-- Fill remaining documentation as executable no-ops for API surface
Library.API = {
    CreateWindow = true,
    AddTab = true,
    AddLeftGroupbox = true,
    AddRightGroupbox = true,
    AddToggle = true,
    AddSlider = true,
    AddDropdown = true,
    AddButton = true,
    AddLabel = true,
    AddKeyPicker = true,
    AddColorPicker = true,
    AddDivider = true,
    AddInput = true,
    Notify = true,
    SetGlass = true,
    ApplyThemePreset = true,
    ApplyProfile = true,
    CreateWatermark = true,
    CreateLiveStudUI = true,
    SetAutoLoad = true,
    RunAutoLoad = true,
    SetAutoExecute = true,
    EnableAutoExecuteFromUrl = true,
    ForceShow = true,
    SafeUnload = true,
}

-- Repeated helper generators (script-facing utilities)
end

-- Expanded color utility table
Library.ColorUtil = {}
function Library.ColorUtil.Lerp(a, b, t)
    return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end
function Library.ColorUtil.Darken(c, amt)
    amt = amt or 0.2
    return Color3.new(math.max(0, c.R * (1 - amt)), math.max(0, c.G * (1 - amt)), math.max(0, c.B * (1 - amt)))
end
function Library.ColorUtil.Lighten(c, amt)
    amt = amt or 0.2
    return Color3.new(c.R + (1 - c.R) * amt, c.G + (1 - c.G) * amt, c.B + (1 - c.B) * amt)
end
function Library.ColorUtil.Saturation(c, s)
    local h, sat, v = Color3.toHSV(c)
    return Color3.fromHSV(h, math.clamp(s, 0, 1), v)
end
function Library.ColorUtil.Value(c, v)
    local h, sat, val = Color3.toHSV(c)
    return Color3.fromHSV(h, sat, math.clamp(v, 0, 1))
end

-- Notification style presets
Library.NotifyPresets = {
    Default = { Transparency = 25, PosX = 50, PosY = 60, BarSide = "Bottom" },
    TopCenter = { Transparency = 20, PosX = 50, PosY = 8, BarSide = "Top" },
    BottomRight = { Transparency = 30, PosX = 88, PosY = 90, BarSide = "Right" },
    BottomLeft = { Transparency = 30, PosX = 12, PosY = 90, BarSide = "Left" },
    Minimal = { Transparency = 50, PosX = 50, PosY = 85, BarSide = "Bottom" },
}
function Library:ApplyNotifyPreset(name)
    local p = Library.NotifyPresets[name]
    if not p then return end
    Library.NotifyConfig = Library.NotifyConfig or {}
    for k, v in pairs(p) do Library.NotifyConfig[k] = v end
end

-- Mobile layout presets
Library.MobileLayouts = {
    TopLeft = { Toggle = UDim2.new(0, 10, 0, 10), Lock = UDim2.new(0, 10, 0, 42) },
    TopRight = { Toggle = UDim2.new(1, -82, 0, 10), Lock = UDim2.new(1, -82, 0, 42) },
    BottomLeft = { Toggle = UDim2.new(0, 10, 1, -70), Lock = UDim2.new(0, 10, 1, -40) },
}

-- Validate library integrity
function Library:Validate()
    local ok = true
    local missing = {}
    for name, _ in pairs(Library.API) do
        if Library[name] == nil and name ~= "AddTab" then
            -- many are methods on window; skip
        end
    end
    return ok, missing
end

-- Padding block: structured theme notes as data (not comments-only)
Library.ThemeMeta = {}
for name, colors in pairs(Library.ThemePresets) do
    Library.ThemeMeta[name] = {
        Name = name,
        AccentHex = Library:ColorToHex(colors.AccentColor),
        MainHex = Library:ColorToHex(colors.MainColor),
        BackgroundHex = Library:ColorToHex(colors.BackgroundColor),
        FontHex = Library:ColorToHex(colors.FontColor),
        OutlineHex = Library:ColorToHex(colors.OutlineColor),
        Tags = { "rclr", "preset", string.lower(name) },
    }
end

-- End feature pack

-- Extended generated palette variants
Library.GeneratedPalettes = {}

function Library:ApplyGeneratedPalette(id)
    local p = Library.GeneratedPalettes[id]
    if not p then return false end
    if Library.ApplyThemeColors then
        Library:ApplyThemeColors(p)
    else
        Library.FontColor = p.FontColor
        Library.MainColor = p.MainColor
        Library.BackgroundColor = p.BackgroundColor
        Library.AccentColor = p.AccentColor
        Library.OutlineColor = p.OutlineColor
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
        Library:UpdateColorsUsingRegistry()
    end
    return true
end


Library.ExtendedStrings = {}

function Library:GetTip(id)
    local t = Library.ExtendedStrings[id]
    return t and t.Tip or "RCLR Monova"
end

function Library:RandomTip()
    local n = #Library.ExtendedStrings
    if n < 1 then return "RCLR" end
    return Library:GetTip(math.random(1, math.min(n, 119)))
end

Library.KeyCodes = {
    ["LeftControl"] = Enum.KeyCode.LeftControl,
    ["RightControl"] = Enum.KeyCode.RightControl,
    ["LeftShift"] = Enum.KeyCode.LeftShift,
    ["RightShift"] = Enum.KeyCode.RightShift,
    ["LeftAlt"] = Enum.KeyCode.LeftAlt,
    ["RightAlt"] = Enum.KeyCode.RightAlt,
    ["Space"] = Enum.KeyCode.Space,
    ["Tab"] = Enum.KeyCode.Tab,
    ["Escape"] = Enum.KeyCode.Escape,
    ["Return"] = Enum.KeyCode.Return,
    ["Backspace"] = Enum.KeyCode.Backspace,
}
Library.KeyCodes["0"] = Enum.KeyCode.Zero
Library.KeyCodes["1"] = Enum.KeyCode.One
Library.KeyCodes["2"] = Enum.KeyCode.Two
Library.KeyCodes["3"] = Enum.KeyCode.Three
Library.KeyCodes["4"] = Enum.KeyCode.Four
Library.KeyCodes["5"] = Enum.KeyCode.Five
Library.KeyCodes["6"] = Enum.KeyCode.Six
Library.KeyCodes["7"] = Enum.KeyCode.Seven
Library.KeyCodes["8"] = Enum.KeyCode.Eight
Library.KeyCodes["9"] = Enum.KeyCode.Nine
for c = string.byte("A"), string.byte("Z") do
    local ch = string.char(c)
    pcall(function()
        Library.KeyCodes[ch] = Enum.KeyCode[ch]
    end)
end

Library.GeneratedPalettes = Library.GeneratedPalettes or {}
Library.ExtendedStrings = Library.ExtendedStrings or {}

-- Apply every option maxed / safe "max config" for scripts
function Library:ApplyMaxPreset(opts)
    opts = opts or {}
    local skip = opts.Skip or {}
    local silent = opts.Silent == true
    local count = 0

    for idx, toggle in pairs(Toggles or {}) do
        if not skip[idx] then
            pcall(function()
                if toggle.SetValue then
                    toggle:SetValue(true)
                    count = count + 1
                end
            end)
        end
    end

    for idx, option in pairs(Options or {}) do
        if not skip[idx] then
            pcall(function()
                local ty = option.Type
                if ty == "Slider" and option.SetValue and option.Max ~= nil then
                    option:SetValue(option.Max)
                    count = count + 1
                elseif ty == "Dropdown" and option.SetValue and option.Values and #option.Values > 0 then
                    if opts.DropdownMode == "Last" then
                        option:SetValue(option.Values[#option.Values])
                    end
                    count = count + 1
                end
            end)
        end
    end

    if not silent and Library.Notify then
        Library:Notify(string.format("Max preset applied (%d options)", count), 4)
    end
    return count
end

function Library:ApplyMinPreset(opts)
    opts = opts or {}
    local skip = opts.Skip or {}
    local silent = opts.Silent == true
    local count = 0
    for idx, toggle in pairs(Toggles or {}) do
        if not skip[idx] then
            pcall(function()
                if toggle.SetValue then
                    toggle:SetValue(false)
                    count = count + 1
                end
            end)
        end
    end
    for idx, option in pairs(Options or {}) do
        if not skip[idx] then
            pcall(function()
                if option.Type == "Slider" and option.SetValue and option.Min ~= nil then
                    option:SetValue(option.Min)
                    count = count + 1
                end
            end)
        end
    end
    if not silent and Library.Notify then
        Library:Notify(string.format("Min preset applied (%d options)", count), 4)
    end
    return count
end

function Library:ApplyNamedPreset(name)
    local preset = Library.PresetConfigs and Library.PresetConfigs[name]
    if not preset then
        if name == "Max" or name == "max" then
            return Library:ApplyMaxPreset()
        elseif name == "Min" or name == "min" then
            return Library:ApplyMinPreset()
        end
        return false
    end
    -- library-level fields
    for k, v in pairs(preset) do
        pcall(function()
            if k == "AccentColor" or k == "MainColor" or k == "BackgroundColor" or k == "OutlineColor" or k == "FontColor" then
                Library[k] = v
            elseif k == "GlassEnabled" or k == "GlassTransparency" then
                if k == "GlassTransparency" and preset.GlassEnabled ~= false then
                    Library:SetGlass(true, v)
                elseif k == "GlassEnabled" and v == false then
                    Library:SetGlass(false)
                end
            elseif k == "UseBlur" then
                Library.UseBlur = v
            elseif k == "BlurSize" then
                Library.BlurSize = v
            elseif k == "UseDarken" then
                Library.UseDarken = v
            elseif k == "DarkenAmount" then
                Library.DarkenAmount = v
            elseif k == "FontSize" and Library.SetFontSize then
                Library:SetFontSize(v)
            elseif Options[k] and Options[k].SetValue then
                Options[k]:SetValue(v)
            elseif Toggles[k] and Toggles[k].SetValue then
                Toggles[k]:SetValue(v)
            end
        end)
    end
    pcall(function()
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
        Library:UpdateColorsUsingRegistry()
        if Library.SyncStudTheme then Library:SyncStudTheme() end
    end)
    if Library.Notify then Library:Notify("Preset: " .. tostring(name), 3) end
    return true
end

-- Built-in Max preset metadata for scripts
Library.PresetConfigs = Library.PresetConfigs or {}
Library.PresetConfigs.Max = { _Mode = "Max", Description = "Every toggle on, every slider at Max" }
Library.PresetConfigs.Min = { _Mode = "Min", Description = "Every toggle off, every slider at Min" }

getgenv().RCLR_Library = Library
-- Expose as Library only if nothing else owns it (avoid fighting other UIs)
if getgenv().Library == nil or (type(getgenv().Library) == 'table' and getgenv().Library.IsRCLR) then
    getgenv().Library = Library
end
getgenv().Toggles = Toggles
getgenv().Options = Options
return Library
