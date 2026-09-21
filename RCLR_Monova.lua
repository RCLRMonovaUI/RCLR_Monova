local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local Lighting = game:GetService('Lighting');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local OldLibrary = getgenv().Library;
if type(OldLibrary) == 'table' and OldLibrary.ScreenGui then
    pcall(function()
        if OldLibrary.Unload then OldLibrary:Unload(); end
        OldLibrary.ScreenGui:Destroy();
    end);
    getgenv().Library = nil;
end

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(22, 22, 22);
    BackgroundColor = Color3.fromRGB(12, 12, 12);
    AccentColor = Color3.fromRGB(255, 255, 255);
    OutlineColor = Color3.fromRGB(50, 50, 50);
    RiskColor = Color3.fromRGB(255, 50, 50),
    GlassEnabled = true;
    GlassTransparency = 0.45;
    OuterGlassTransparency = 0.5;

    Black = Color3.new(0, 0, 0);

    Font = Enum.Font.Code,
    FontSize = 14,

    OpenedFrames = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;

    Toggled = false;
    WireframeDrag = true;
    UseBlur = true;
    BlurSize = 24;
    UseDarken = true;
    DarkenAmount = 55;

    KeybindMode = 'All';

    NotifyConfig = {
        ClipDescendants  = false;
        MaxHeight        = 200;
        PosX             = 50;
        PosY             = 60;
        Transparency     = 60;
        Alignment        = "Center";
        BarSide          = "Bottom";
        SortOrder        = "Time";
    };
    NotifyQueue       = {};
    ActiveNotifyCount = 0;
    NotifyCounter     = 0;
};

Library.KeyPickerList = {};

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
    local open = Library.Toggled and Library.UseBlur;
    local targetSize = open and Library.BlurSize or 0;

    if open then
        Library.BlurEffect.Enabled = true;
    end

    Library.BlurEffect.Size = targetSize;

    if Library.DarkOverlay then
        local dark = Library.Toggled and Library.UseDarken;
        Library.DarkOverlay.BackgroundTransparency = dark and (1 - (Library.DarkenAmount / 100)) or 1;
    end

    if not open then
        Library.BlurEffect.Enabled = false;
    end
end

function Library:SetBlur(Size)
    Library.BlurSize = math.clamp(Size, 0, 56);
    if Library.Toggled and Library.UseBlur then
        Library.BlurEffect.Size = Library.BlurSize;
    end
end

-- Call this with any Groupbox to add a blur toggle + size slider
-- e.g. Library:AddBlurSlider(MyGroupbox)
function Library:AddBlurSlider(Groupbox)
    Groupbox:AddToggle('LinoriaUseBlur', {
        Text    = 'Background Blur';
        Default = Library.UseBlur;
        Tooltip = 'Blur the background when the menu is open';
        Callback = function(Value)
            Library.UseBlur = Value;
            Library:UpdateBlur();
        end;
    });
    Groupbox:AddSlider('LinoriaBlurSize', {
        Text     = 'Blur Amount';
        Default  = Library.BlurSize;
        Min      = 0;
        Max      = 56;
        Rounding = 0;
        Callback = function(Value)
            Library:SetBlur(Value);
        end;
    });
end

-- Call this with any Groupbox to add a darken toggle + amount slider
-- e.g. Library:AddDarkenSlider(MyGroupbox)
function Library:AddDarkenSlider(Groupbox)
    Groupbox:AddToggle('LinoriaUseDarken', {
        Text    = 'Background Darken';
        Default = Library.UseDarken;
        Tooltip = 'Darken the background when the menu is open';
        Callback = function(Value)
            Library.UseDarken = Value;
            Library:UpdateBlur();
        end;
    });
    Groupbox:AddSlider('LinoriaDarkenAmount', {
        Text     = 'Darken Amount';
        Default  = Library.DarkenAmount;
        Min      = 0;
        Max      = 100;
        Rounding = 0;
        Suffix   = '%';
        Callback = function(Value)
            Library.DarkenAmount = Value;
            Library:UpdateBlur();
        end;
    });
end

-- Control keybind frame background transparency (0 = opaque, 1 = invisible)
function Library:SetKeybindTransparency(Value)
    Value = math.clamp(Value, 0, 1);
    local Inner = Library.KeybindInner;
    if Library.KeybindFrame then
        Library.KeybindFrame.BackgroundTransparency = Value;
        Library.KeybindFrame.BorderSizePixel = Value >= 1 and 0 or 1;
        if not Inner then
            Inner = Library.KeybindFrame:FindFirstChildOfClass('Frame');
        end
    end
    if Inner then
        Inner.BackgroundTransparency = Value;
        Inner.BorderSizePixel = Value >= 1 and 0 or 1;
    end
    if Library.KeybindColorFrame then
        Library.KeybindColorFrame.BackgroundTransparency = Value;
    end
end

-- Call this with any Groupbox to add a keybind frame transparency slider
-- e.g. Library:AddKeybindTransparencySlider(MyGroupbox)
function Library:AddKeybindTransparencySlider(Groupbox)
    Groupbox:AddSlider('LinoriaKeybindTransparency', {
        Text     = 'Keybind Transparency';
        Default  = 0;
        Min      = 0;
        Max      = 100;
        Rounding = 0;
        Suffix   = '%';
        Callback = function(Value)
            Library:SetKeybindTransparency(Value / 100);
        end;
    });
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
    local mobileUI = CoreGui:FindFirstChild("LinoriaMobileUI")
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

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);
        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;
    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    
    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;
    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);
    if not success then
        local _, i = event:find(":%d+: ");
        if not i then
            return Library:Notify(event);
        end;
        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;
    for Property, Value in next, Properties do
        pcall(function()
            _Instance[Property] = Value;
        end);
    end;

    if _Instance:IsA("TextLabel") or _Instance:IsA("TextBox") or _Instance:IsA("TextButton") then
        if Properties.TextSize then
            _Instance:SetAttribute("FontSizeOffset", Properties.TextSize - Library.FontSize)
        else
            _Instance:SetAttribute("FontSizeOffset", 0)
        end
    end

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:ApplyGlow(Inst)

end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = Library.FontSize + 2;
        TextStrokeTransparency = 0;
    });
    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);
    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff, IsWindow)
    Instance.Active = true;
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            local StartPos = Instance.Position
            local DragStart = Input.Position

            if (DragStart.Y - Instance.AbsolutePosition.Y) > (Cutoff or 40) then
                return
            end

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
                                Parent = ScreenGui
                            })
                         
                            local stroke = Library:Create("UIStroke", {
                                Color = Library.AccentColor,
                                Thickness = 1,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                Parent = Wireframe
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
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, Library.FontSize);
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
        Size = UDim2.fromOffset(X, Y);
        TextSize = Library.FontSize;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });
    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });
    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

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
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;

local function fontScale(font)
    if font == Enum.Font.Code then return 0.9 end;
    if font == Enum.Font.RobotoMono then return 0.92 end;
    if font == Enum.Font.GothamBold then return 0.95 end;
    if font == Enum.Font.SciFi then return 0.84 end;
    if font == Enum.Font.Arcade then return 0.78 end;
    if font == Enum.Font.FredokaOne then return 0.86 end;
    if font == Enum.Font.Cartoon then return 0.88 end;
    return 1;
end;

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;
end;

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

    if Library.OnUnload then
        Library.OnUnload()
    end
    
    if Library.BlurEffect then
        Library.BlurEffect:Destroy()
    end

    if Library.DarkOverlay and Library.DarkOverlay.Parent then
        Library.DarkOverlay.Parent:Destroy()
    end

    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};
do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });
        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });
        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });
        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });
        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });
        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });
        local HueCursor = Library:Create('Frame', { 
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });
        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });
        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });
        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor;
        
        if Info.Transparency then 
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });
            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });
            TransparencyCursor = Library:Create('Frame', { 
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = Library.FontSize;
            Text = ColorPicker.Title,
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });
        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,
                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });
            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });
            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });
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
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = Library.FontSize - 1;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });
                Library:OnHighlight(Button, Button, 
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );
                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
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

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local SequenceTable = {};
        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });
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
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = ColorPicker.Transparency;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });
            if TransparencyBoxInner then
                TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;
        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateColor(PosX, PosY)
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(PosX, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
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
        end);
        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateHue(PosY)
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
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
        end);
        DisplayFrame.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local function UpdateAlpha(PosX)
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local MouseX = math.clamp(PosX, MinX, MaxX);

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));
                        ColorPicker:Display();
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
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;
                local DFPos = DisplayFrame.AbsolutePosition;
                local DFSize = DisplayFrame.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < DFPos.Y or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    if not (Mouse.X >= DFPos.X and Mouse.X <= DFPos.X + DFSize.X
                        and Mouse.Y >= DFPos.Y and Mouse.Y <= DFPos.Y + DFSize.Y) then
                        ColorPicker:Hide();
                    end
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        function ColorPicker:GetTransparency()
            return ColorPicker.Transparency;
        end;

        function ColorPicker:OnTransparencyChanged(Func)
            ColorPicker.TransparencyChanged = Func;
            Func(ColorPicker.Transparency);
        end;

        local _OrigDisplay = ColorPicker.Display;
        ColorPicker.Display = function(self)
            _OrigDisplay(self);
            Library:SafeCallback(ColorPicker.TransparencyChanged, ColorPicker.Transparency);
        end;

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddColorPickerAlpha(Idx, Info)
        Info = Info or {};
        if Info.Transparency == nil then
            Info.Transparency = 0;
        end;
        return Funcs.AddColorPicker(self, Idx, Info);
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
        };
        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });
        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize - 1;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });
        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        });
        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);
        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });
        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });
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

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};
            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = Library.FontSize - 1;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });
            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;
            function ModeButton:Deselect()
                KeyPicker.Mode = nil;
                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);
            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local State = KeyPicker:GetState();

            local displayKey = (KeyPicker.Value == 'None') and '...' or KeyPicker.Value
            ContainerLabel.Text = string.format('[%s] %s (%s)', displayKey, Info.Text, KeyPicker.Mode);
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

            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0
            local XSize = 0

            for _, Frame in next, Library.KeybindContainer:GetChildren() do
                if Frame:IsA('Frame') and Frame.Visible then
                    YSize = YSize + 18;
                    local LabelChild = Frame:FindFirstChildOfClass('TextLabel')
                    if LabelChild and (LabelChild.TextBounds.X + 20 > XSize) then
                        XSize = LabelChild.TextBounds.X + 20 
                    end
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10 + 15, 210), 0, YSize + 23)
        end;
        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end

                local Key = KeyPicker.Value;
                if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                        or Key == 'Touch' and true
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key;
            KeyPicker.Value = Key;
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

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

        local Picking = false;
        local LongPressTime = Info.LongPressTime or 0.55;
        local TouchMoveThreshold = Info.TouchMoveThreshold or 10;

        local function OpenModeSelect()
            ModeSelectOuter.Visible = true;
        end;

        local function BeginPicking()
            if Picking then
                return;
            end;

            Picking = true;

            DisplayLabel.Text = '';

            local Break;
            local Text = '';

            task.spawn(function()
                while (not Break) do
                    if Text == '...' then
                        Text = '';
                    end;

                    Text = Text .. '.';
                    DisplayLabel.Text = Text;

                    wait(0.4);
                end;
            end);

            wait(0.2);

            local Event;
            Event = InputService.InputBegan:Connect(function(Input)
                local Key;

                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = Input.KeyCode.Name;
                elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Key = 'MB1';
                elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                    Key = 'MB2';
                elseif Input.UserInputType == Enum.UserInputType.Touch then
                    Key = 'Touch';
                end;

                if not Key then
                    return;
                end;

                Break = true;
                Picking = false;

                DisplayLabel.Text = Key;
                KeyPicker.Value = Key;
                Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
                Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

                Library:AttemptSave();
                Event:Disconnect();
            end);
        end;

        PickOuter.InputBegan:Connect(function(Input)
            if Library:MouseIsOverOpenedFrame() then
                return;
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                BeginPicking();
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                OpenModeSelect();
            elseif Input.UserInputType == Enum.UserInputType.Touch then
                local StartPosition = Input.Position;
                local TouchMoved = false;
                local TouchEnded = false;
                local LongPressed = false;
                local ChangedConn;
                local EndedConn;

                ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change == Input then
                        if (Change.Position - StartPosition).Magnitude > TouchMoveThreshold then
                            TouchMoved = true;
                        end;
                    end;
                end);

                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input then
                        TouchEnded = true;

                        if ChangedConn then
                            ChangedConn:Disconnect();
                        end;

                        if EndedConn then
                            EndedConn:Disconnect();
                        end;

                        if (not LongPressed) and (not TouchMoved) then
                            task.spawn(BeginPicking);
                        end;
                    end;
                end);

                task.delay(LongPressTime, function()
                    if TouchEnded or TouchMoved then
                        return;
                    end;

                    LongPressed = true;

                    if ChangedConn then
                        ChangedConn:Disconnect();
                    end;

                    if EndedConn then
                        EndedConn:Disconnect();
                    end;

                    OpenModeSelect();
                end);
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 
                        or Key == 'Touch' and Input.UserInputType == Enum.UserInputType.Touch then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;

                KeyPicker:Update();
            end;
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end))

        KeyPicker:Update();
        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};
    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddRow(Columns)
        local Groupbox = self
        local Container = Groupbox.Container

        local ColumnsCount = type(Columns) == 'number' and math.max(1, Columns) or 2

        local RowOuter = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 1,
            Parent = Container
        })

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = RowOuter
        })

        local Boxes = {}

        for i = 1, ColumnsCount do
            local Box = { Type = 'Groupbox' }

            local BoxContainer = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1 / ColumnsCount, -((ColumnsCount - 1) * 8) / ColumnsCount, 1, 0),
                ZIndex = 1,
                Parent = RowOuter
            })

            local BoxLayout = Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = BoxContainer
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
                if Groupbox.Resize then
                    Groupbox:Resize()
                end
            end

            BoxLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Box:Resize()
            end)

            table.insert(Boxes, Box)
        end

        Groupbox:AddBlank(1)
        if Groupbox.Resize then Groupbox:Resize() end

        return unpack(Boxes)
    end;
    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = Library.FontSize;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });
        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;
        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, Library.FontSize, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;
    function Funcs:AddButton(...)
        local Button = {};
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

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });
            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = Library.FontSize;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });
            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });
            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });
            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );
            return Outer, Inner, Label
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
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                    return false
                end

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

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end

        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
            SubButton.Outer.Parent = self.Outer

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer)
                 end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });
        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });
        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });
        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Callback = Info.Callback or function(Value) end;
        };
        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });
        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });
        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);
        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    local currentCursorPos = Box.Position.X.Offset + width

                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

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

            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize));
            Fill.Size = UDim2.new(0, X, 1, 0);

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
            return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max));
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
                    local gPos = Fill.AbsolutePosition.X
                    
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
            Info.Values = GetPlayersString();
            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;
        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
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

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });
        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });
        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });
        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = Library.FontSize;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });
        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;
        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });
        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
        end;

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
        end;
        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });
        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });
        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });
        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;
        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};
                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:BuildDropdownList()
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};
                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = Library.FontSize;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );
                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;
                ButtonLabel.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            RecalculateListSize(Y);
        end;

        function Dropdown:SetValues(NewValues)
            if NewValues then
                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);
        InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end);
        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
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
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        return Dropdown;
    end;
    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };
        
        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });
        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);
        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);
        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                if Elem.Type == 'Toggle' and Elem.Value ~= Value then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;
do
    Library.NotificationStack = {};

    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency  = 1;
        Position                = UDim2.new(0, 0, 0, 40);
        Size                    = UDim2.new(0, 320, 1, -50);
        ZIndex                  = 100;
        Parent                  = ScreenGui;
    });
    Library:Create('UIListLayout', {
        Padding        = UDim.new(0, 4);
        FillDirection  = Enum.FillDirection.Vertical;
        SortOrder      = Enum.SortOrder.LayoutOrder;
        Parent         = Library.NotificationArea;
    });

    function Library:ConfigureNotifications(Cfg)
        local C = Library.NotifyConfig;
        for k, v in next, Cfg do C[k] = v end;

        local AnchorX = C.Alignment == "Left" and 0 or (C.Alignment == "Right" and 1 or 0.5);
        local AnchorY = C.BarSide == "Top" and 0 or 1;
        local VAlign  = C.BarSide == "Top" and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom;
        local HAlign  = C.Alignment == "Left" and Enum.HorizontalAlignment.Left or (C.Alignment == "Right" and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Center);

        Library.NotificationArea.AnchorPoint        = Vector2.new(AnchorX, AnchorY);
        Library.NotificationArea.Position           = UDim2.new(C.PosX / 100, 0, C.PosY / 100, 0);
        Library.NotificationArea.ClipsDescendants   = C.ClipDescendants;
        Library.NotificationArea.AutomaticSize      = Enum.AutomaticSize.XY;

        local SizeConstraint = Library.NotificationArea:FindFirstChildOfClass('UISizeConstraint');
        if C.ClipDescendants then
            if not SizeConstraint then
                SizeConstraint = Library:Create('UISizeConstraint', { Parent = Library.NotificationArea });
            end;
            SizeConstraint.MaxSize = Vector2.new(math.huge, C.MaxHeight);
        elseif SizeConstraint then
            SizeConstraint:Destroy();
        end;

        local Layout = Library.NotificationArea:FindFirstChildOfClass('UIListLayout');
        if Layout then
            Layout.VerticalAlignment    = VAlign;
            Layout.HorizontalAlignment  = HAlign;
        end;
    end;

    Library:ConfigureNotifications({});

    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });
    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });
    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = Library.FontSize;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });
    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);

    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });
    Library:ApplyGlow(KeybindOuter);

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });
    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });
    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    Library.KeybindInner = KeybindInner;
    Library.KeybindColorFrame = ColorFrame;
    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.new(0, 0, 0, 2);
        TextXAlignment = Enum.TextXAlignment.Center,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });
    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

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

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, Library.FontSize);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
    Library:SetWatermarkVisibility(true)

    Library.WatermarkText.Text = Text;
end;
function Library:Notify(Text, Time)
    if not Text or Text == "" then return end;
    table.insert(Library.NotifyQueue, { Text = Text, Time = Time });
    Library:ProcessNotifyQueue();
end;

function Library:ProcessNotifyQueue()
    local C = Library.NotifyConfig;
    local ItemHeight = 22 + 4;
    while #Library.NotifyQueue > 0 do
        if C.ClipDescendants and (Library.ActiveNotifyCount + 1) * ItemHeight > C.MaxHeight then break end;
        local Item = table.remove(Library.NotifyQueue, 1);
        Library:SpawnNotify(Item.Text, Item.Time);
    end;
end;

function Library:SpawnNotify(Text, Time)
    local xw = (Library:GetTextBounds(Text, Library.CustomFontFace or Library.Font, 13) or 200);
    local H = 22;
    local NotifyTransparency = (Library.NotifyConfig.Transparency or 0) / 100;
    Library.NotifyCounter = Library.NotifyCounter + 1;
    local Outer = Library:Create('Frame', {
        BackgroundTransparency  = 1;
        BorderSizePixel         = 0;
        Size                    = UDim2.fromOffset(0, H);
        ClipsDescendants        = true;
        LayoutOrder             = Library.NotifyConfig.SortOrder == "Text Length" and #Text or Library.NotifyCounter;
        ZIndex                  = 100;
        Parent                  = Library.NotificationArea;
    });
    local Inner = Library:Create('Frame', {
        BackgroundColor3  = Library.MainColor;
        BackgroundTransparency = NotifyTransparency;
        BorderSizePixel   = 0;
        Size              = UDim2.new(1, 0, 1, 0);
        ZIndex            = 101;
        Parent            = Outer;
    });
    Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor' });
    local InnerStroke = Library:Create('UIStroke', {
        Color       = Library.OutlineColor;
        Transparency = NotifyTransparency;
        Thickness   = 1;
        Parent      = Inner;
    });
    Library:AddToRegistry(InnerStroke, { Color = 'OutlineColor' });
    local GradientFrame = Library:Create('Frame', { BackgroundColor3 = Library.MainColor; BackgroundTransparency = NotifyTransparency; BorderSizePixel = 0; Position = UDim2.new(0, 1, 0, 1); Size = UDim2.new(1, -2, 1, -2); ZIndex = 102; Parent = Inner });
    Library:AddToRegistry(GradientFrame, { BackgroundColor3 = 'MainColor' });
    local G = Library:Create('UIGradient', { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor) }); Rotation = -90; Parent = GradientFrame });
    Library:AddToRegistry(G, { Color = function() return ColorSequence.new({ ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)), ColorSequenceKeypoint.new(1, Library.MainColor) }) end });
    Library:CreateLabel({ Position = UDim2.new(0, 8, 0, 0); Size = UDim2.new(1, -8, 1, 0); Text = Text; TextXAlignment = Enum.TextXAlignment.Left; TextSize = 13; ZIndex = 103; Parent = GradientFrame });
    local BarSide = Library.NotifyConfig.BarSide or "Bottom";
    local AccentBarPos, AccentBarSize;
    if BarSide == "Top" then
        AccentBarPos  = UDim2.new(0, -1, 0, -1);
        AccentBarSize = UDim2.new(1, 2, 0, 3);
    elseif BarSide == "Bottom" then
        AccentBarPos  = UDim2.new(0, -1, 1, -2);
        AccentBarSize = UDim2.new(1, 2, 0, 3);
    elseif BarSide == "Left" then
        AccentBarPos  = UDim2.new(0, -1, 0, -1);
        AccentBarSize = UDim2.new(0, 3, 1, 2);
    else
        AccentBarPos  = UDim2.new(1, -2, 0, -1);
        AccentBarSize = UDim2.new(0, 3, 1, 2);
    end;
    Library:Create('Frame', {
        BackgroundColor3  = Library.AccentColor;
        BorderSizePixel   = 0;
        Position          = AccentBarPos;
        Size              = AccentBarSize;
        ZIndex            = 104;
        Parent            = Outer;
    });
    Library:AddToRegistry(Outer:GetChildren()[#Outer:GetChildren()], { BackgroundColor3 = 'AccentColor' }, true);
    pcall(Outer.TweenSize, Outer, UDim2.fromOffset(xw + 16, H), 'Out', 'Quad', 0.35, true);
    Library.ActiveNotifyCount = Library.ActiveNotifyCount + 1;
    task.spawn(function()
        task.wait(Time or 5);
        pcall(Outer.TweenSize, Outer, UDim2.fromOffset(0, H), 'Out', 'Quad', 0.35, true);
        task.wait(0.4);
        Outer:Destroy();
        Library.ActiveNotifyCount = Library.ActiveNotifyCount - 1;
        Library:ProcessNotifyQueue();
    end);
end;

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

    if type(Config.UseBlur) == 'boolean' then Library.UseBlur = Config.UseBlur end
    if type(Config.BlurSize) == 'number' then Library.BlurSize = Config.BlurSize end
    if type(Config.UseDarken) == 'boolean' then Library.UseDarken = Config.UseDarken end
    if type(Config.DarkenAmount) == 'number' then Library.DarkenAmount = Config.DarkenAmount end

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

    local Window = {
        Tabs = {};
    };

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });
    Library:MakeDraggable(Outer, 25, true);

    local Inner = Library:Create('Frame', {
        Name = "Inner",
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });
    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 25);
        Text = Config.Title or '';
        RichText = true; 
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 1;
        Parent = Inner;
    });
    local MapNameLabel = Library:CreateLabel({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -7, 0, 0),
        Size = UDim2.new(0, 0, 0, 25),
        Text = 'Loading...',
        TextColor3 = Library.AccentColor,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 1,
        Parent = Inner;
    });
    Library:AddToRegistry(MapNameLabel, {
        TextColor3 = 'AccentColor';
    });
    task.spawn(function()
        local success, info = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        if success and info and info.Name then
            MapNameLabel.Text = info.Name
        else
            MapNameLabel.Text = game.Name or "Unknown Map"
        end
    end)


    local TabBarOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 0, 29);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:AddToRegistry(TabBarOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });
    local TabBarInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = TabBarOuter;
    });
    Library:AddToRegistry(TabBarInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 4, 0, 4);
        Size = UDim2.new(1, -8, 1, -8);
        ZIndex = 1;
        Parent = TabBarInner;
    });
    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });
    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 58);
        Size = UDim2.new(1, -16, 1, -66);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });
    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });
    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 1, -16);
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Outer.ClipsDescendants = true;
    local CornerCircle = Library:Create('Frame', {
        AnchorPoint      = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.AccentColor;
        BackgroundTransparency = 0.5;
        BorderSizePixel  = 0;
        Position         = UDim2.new(1, 0, 1, 0);
        Size             = UDim2.fromOffset(46, 46);
        ZIndex           = 10;
        Parent           = Inner;
    });
    Library:Create('Frame' --[[no corner]], {
        CornerRadius = UDim.new(1, 0);
        Parent       = CornerCircle;
    });
    Library:AddToRegistry(CornerCircle, {
        BackgroundColor3 = 'AccentColor';
    });
    CornerCircle.Active = true;
    CornerCircle.Parent = Outer;
    CornerCircle.ZIndex = 100;

    do
        local MinW = 420;
        local MinH = 340;

        local Resizing = false;
        local ResizeConn, EndConn;
        local StartSize, DragStart, DragType;
        local HasMoved = false;
        local Wireframe;

        local function StopResize()
            Resizing = false;
            if ResizeConn then ResizeConn:Disconnect(); ResizeConn = nil; end
            if EndConn then EndConn:Disconnect(); EndConn = nil; end
        end;

        local function StartResize(Position, FromType)
            if Resizing then return; end
            StopResize();

            Resizing = true;
            StartSize = Outer.Size;
            DragStart = Position;
            DragType = FromType;
            HasMoved = false;
            if Wireframe then Wireframe:Destroy(); Wireframe = nil; end

            ResizeConn = InputService.InputChanged:Connect(function(Change)
                local T = Change.UserInputType;
                if T ~= Enum.UserInputType.MouseMovement and T ~= Enum.UserInputType.Touch then return; end
                if DragType ~= Enum.UserInputType.Touch and T == Enum.UserInputType.Touch then return; end

                local Delta = Change.Position - DragStart;
                if not HasMoved and Delta.Magnitude <= 2 then return; end

                local TopLeft = Outer.AbsolutePosition;
                local VPSize = Library.ScreenGui.AbsoluteSize;

                local NewW = math.clamp(StartSize.X.Offset + Delta.X, MinW, VPSize.X - TopLeft.X);
                local NewH = math.clamp(StartSize.Y.Offset + Delta.Y, MinH, VPSize.Y - TopLeft.Y);

                if Library.WireframeDrag then
                    if not HasMoved then
                        HasMoved = true;

                        Wireframe = Library:Create('Frame', {
                            Size = UDim2.fromOffset(NewW, NewH);
                            Position = UDim2.fromOffset(TopLeft.X, TopLeft.Y);
                            BackgroundTransparency = 1;
                            Active = false;
                            ZIndex = 100000;
                            Parent = ScreenGui;
                        });

                        Library:Create('UIStroke', {
                            Color = Library.AccentColor;
                            Thickness = 1;
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                            Parent = Wireframe;
                        });
                    end;

                    if HasMoved and Wireframe then
                        Wireframe.Position = UDim2.fromOffset(TopLeft.X, TopLeft.Y);
                        Wireframe.Size = UDim2.fromOffset(NewW, NewH);
                    end;
                else
                    Outer.Size = UDim2.fromOffset(NewW, NewH);
                end;
            end);

            EndConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput.UserInputType == DragType then
                    if Library.WireframeDrag and HasMoved and Wireframe then
                        Outer.Size = Wireframe.Size;
                        Wireframe:Destroy();
                        Wireframe = nil;
                    end;
                    StopResize();
                end;
            end);
        end;

        local function OnHandlePressed(Position, InputType)
            StartResize(Position, InputType);
        end;

        CornerCircle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                OnHandlePressed(Input.Position, Input.UserInputType);
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return; end
            if Resizing then return; end

            local WindowPos = Outer.AbsolutePosition;
            local WindowSize = Outer.AbsoluteSize;
            local CenterX = WindowPos.X + WindowSize.X;
            local CenterY = WindowPos.Y + WindowSize.Y;
            local P = Input.Position;
            local Rad = 26;
            local DX = CenterX - P.X;
            local DY = CenterY - P.Y;

            if (DX * DX) + (DY * DY) <= (Rad * Rad) then
                OnHandlePressed(P, Input.UserInputType);
            end;
        end);
    end;

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;
    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, Library.FontSize + 2);
        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });
        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });
        local TabIndicator = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 0, 2); 
            Visible = false; 
            ZIndex = 4;
            Parent = TabButton;
        });
        Library:AddToRegistry(TabIndicator, { BackgroundColor3 = 'AccentColor' });

        local Blocker = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 0, 0, 0);
            Visible = false;
            Parent = TabButton;
        });
        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });
        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });
        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
            end);
        end;

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;

            Blocker.BackgroundTransparency = 0;
            TabButton.BackgroundColor3 = Library.MainColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            TabFrame.Visible = true;
            TabIndicator.Visible = true;
        end;
        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabButton.BackgroundColor3 = Library.BackgroundColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            TabFrame.Visible = false;
            TabIndicator.Visible = false;
        end;
        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;
        function Tab:AddGroupbox(Info)
            local Groupbox = {};
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });
            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 0, 0, 2);
                TextSize = Library.FontSize;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 5;
                Parent = BoxInner;
            });
            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });
            function Groupbox:Resize()
                local Size = 0;
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);
            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and LeftSide or RightSide;
            });
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });
            function Tabbox:AddTab(Name)
                local Tab = {};
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });
                local TabHighlight = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 2);
                    Visible = false;
                    ZIndex = 10;
                    Parent = Button;
                });
                Library:AddToRegistry(TabHighlight, {
                    BackgroundColor3 = 'AccentColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = Library.FontSize;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });
                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });
                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });
                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });
                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;
                    TabHighlight.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;
                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;
                    TabHighlight.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;
                function Tab:Resize()
                    local TabCount = 0;
                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    if (not Container.Visible) then
                        return;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
                end;
                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;
        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                Tab:ShowTab();
            end;
        end);
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;
        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });
    function Library:Toggle()
        Library.Toggled = not Library.Toggled;
        ModalElement.Modal = Library.Toggled;
        Outer.Visible = Library.Toggled;
        pcall(function() Library:UpdateLogoVisibility() end);
        if Library.Toggled then
            task.spawn(function()
                local State = InputService.MouseIconEnabled;
                local GuiService = game:GetService("GuiService");

                local Cursor = Instance.new("ImageLabel", ScreenGui);
                Cursor.Image = "http://www.roblox.com/asset/?id=4292970642";
                Cursor.BackgroundTransparency = 1;
                Cursor.ZIndex = 100;

                local CursorOutline = Instance.new("ImageLabel", ScreenGui);
                CursorOutline.Image = "http://www.roblox.com/asset/?id=4292970642";
                CursorOutline.ImageColor3 = Color3.new();
                CursorOutline.BackgroundTransparency = 1;
                CursorOutline.ZIndex = 99;

                Cursor.Size, CursorOutline.Size = UDim2.fromOffset(17, 17), UDim2.fromOffset(19, 19);
                Cursor.Rotation, CursorOutline.Rotation = -45, -45;

                while Library.Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false;

                    local mPos = InputService:GetMouseLocation();
                    local udim = UDim2.fromOffset(mPos.X, mPos.Y - GuiService:GetGuiInset().Y - 1);

                    Cursor.ImageColor3 = Library.AccentColor;
                    Cursor.Position, CursorOutline.Position = udim, udim - UDim2.fromOffset(1, 1);

                    RenderStepped:Wait();
                end;

                InputService.MouseIconEnabled = State;

                Cursor:Destroy();
                CursorOutline:Destroy();
            end);
        end;
        Library:UpdateBlur();
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

    if Config.AutoShow then task.spawn(Library.Toggle) end

    Window.Holder = Outer;
    Library.WindowOuter = Outer;
    pcall(function()
        Library:ApplyBlackWhiteTheme()
        Library:SetGlass(true, Library.GlassTransparency or 0.45)
    end)
    task.defer(function()
        pcall(function()
            if not Library._LogoGui then
                Library:CreateLogo({ Text = "RCLR", TextSize = 72, SpinSpeed = 18 })
            end
            Library:UpdateLogoVisibility()
        end)
    end)
    return Window;
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

if InputService.TouchEnabled then
    local MobileGui = Instance.new("ScreenGui")
    MobileGui.Name = "LinoriaMobileUI"
    MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ProtectGui(MobileGui)
    MobileGui.Parent = CoreGui

    local BTN_W, BTN_H = 88, 30
    local BTN_GAP      = 40  

    local function CreateMobileButton(name, text, startPos)
        local Outer = Library:Create('Frame', {
            Name             = name .. "Outer",
            BackgroundColor3 = Library.OutlineColor,
            BorderSizePixel  = 0,
            Position         = startPos,
            Size             = UDim2.new(0, BTN_W, 0, BTN_H),
            ZIndex           = 300,
            Parent           = MobileGui,
            Active           = true,
        })
        Library:AddToRegistry(Outer, { BackgroundColor3 = 'OutlineColor' })

        local AccentFrame = Library:Create('Frame', {
            Name             = name .. "Accent",
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 1, 0, 1),
            Size             = UDim2.new(1, -2, 1, -2),
            ZIndex           = 301,
            Parent           = Outer,
        })
        Library:AddToRegistry(AccentFrame, { BackgroundColor3 = 'AccentColor' })

        local Inner = Library:Create('Frame', {
            Name             = name .. "Inner",
            BackgroundColor3 = Color3.fromRGB(8, 8, 12),
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 1, 0, 1),
            Size             = UDim2.new(1, -2, 1, -2),
            ZIndex           = 302,
            Parent           = AccentFrame,
        })

        local GradientOverlay = Library:Create('Frame', {
            Name             = name .. "Gradient",
            BackgroundColor3 = Color3.new(1, 1, 1), 
            BorderSizePixel  = 0,
            Size             = UDim2.new(1, 0, 1, 0),
            ZIndex           = 303,
            Parent           = Inner,
        })
        Library:Create('UIGradient', {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.90), 
                NumberSequenceKeypoint.new(1, 1.0)   
            }),
            Rotation = 90,
            Parent = GradientOverlay,
        })

        local Btn = Library:Create('TextButton', {
            Name                = name .. "Btn",
            BackgroundTransparency = 1,
            Size                = UDim2.new(1, 0, 1, 0),
            Font                = Enum.Font.Code,
            Text                = text,
            TextColor3          = Color3.fromRGB(255, 255, 255),
            TextSize            = Library.FontSize - 1,
            ZIndex              = 304,
            Parent              = Inner,
            Active              = true,
        })

        return Outer, Btn
    end

    local ToggleOuter, ToggleBtn = CreateMobileButton("Toggle", "Toggle UI",  UDim2.new(0, 10, 0, 10))
    local LockOuter,   LockBtn  = CreateMobileButton("Lock",   "Unlock UI",  UDim2.new(0, 10, 0, 10 + BTN_H + (BTN_GAP - BTN_H)))

    local IsUnlocked = false

    local function BindMobileButtonAction(Btn, Outer, ClickAction)
        local dragging  = false
        local dragInput = nil
        local dragStart = nil
        local startPos  = nil
        local hasMoved  = false

        Btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                hasMoved  = false
                dragStart = input.Position
                startPos  = Outer.Position
                dragInput = input

                local connection
                connection = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        connection:Disconnect()
                        if not hasMoved then
                            ClickAction()
                        end
                    end
                end)
            end
        end)

        InputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 3 then
                    hasMoved = true
                end
                if IsUnlocked and hasMoved then
                    Outer.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)
    end

    BindMobileButtonAction(ToggleBtn, ToggleOuter, function()
        Library:Toggle()
    end)

    BindMobileButtonAction(LockBtn, LockOuter, function()
        IsUnlocked = not IsUnlocked
        LockBtn.Text = IsUnlocked and "Lock UI" or "Unlock UI"
        LockBtn.TextColor3 = IsUnlocked
            and Library.AccentColor
            or  Color3.fromRGB(255, 255, 255)
    end)

    local _origUpdate = Library.UpdateColorsUsingRegistry
    Library.UpdateColorsUsingRegistry = function(self)
        _origUpdate(self)
    end
end


-- ========== RCLR Black & White ==========
function Library:ApplyBlackWhiteTheme()
    Library.FontColor = Color3.fromRGB(255, 255, 255)
    Library.MainColor = Color3.fromRGB(22, 22, 22)
    Library.BackgroundColor = Color3.fromRGB(12, 12, 12)
    Library.AccentColor = Color3.fromRGB(255, 255, 255)
    Library.OutlineColor = Color3.fromRGB(50, 50, 50)
    Library.RiskColor = Color3.fromRGB(255, 50, 50)
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
    pcall(function() Library:UpdateColorsUsingRegistry() end)
    pcall(function() if Library.ReapplyGlass then Library:ReapplyGlass() end end)
end

-- ========== FULL UI GLASS ==========
function Library:SetGlass(Enabled, Transparency)
    if type(Enabled) == "boolean" then
        Library.GlassEnabled = Enabled
    else
        Library.GlassEnabled = Enabled ~= false
    end
    if type(Transparency) == "number" then
        Library.GlassTransparency = math.clamp(Transparency, 0, 0.75)
    end
    Library.GlassTransparency = Library.GlassTransparency or 0.45
    local on = Library.GlassEnabled == true
    local t = Library.GlassTransparency
    local L1 = on and math.clamp(t + 0.08, 0.1, 0.7) or 0
    local L2 = on and math.clamp(t * 0.7, 0.08, 0.55) or 0
    local L3 = on and math.clamp(t * 0.4, 0.05, 0.35) or 0
    Library.OuterGlassTransparency = L1
    Library._GlassLayer1, Library._GlassLayer2, Library._GlassLayer3 = L1, L2, L3

    pcall(function()
        if not Library.ScreenGui then return end
        for _, d in ipairs(Library.ScreenGui:GetDescendants()) do
            if d:IsA("Frame") or d:IsA("ScrollingFrame") then
                local nm = d.Name or ""
                if nm:find("Fill") or nm:find("Accent") or nm:find("Cursor") or nm:find("Indicator") or nm:find("Logo") then
                    -- solid accents
                elseif nm == "Outer" or (Library.WindowOuter and d == Library.WindowOuter) then
                    d.BackgroundColor3 = Library.BackgroundColor
                    d.BackgroundTransparency = L1
                elseif nm == "Inner" or (Library.WindowInner and d == Library.WindowInner) then
                    d.BackgroundColor3 = Library.MainColor
                    d.BackgroundTransparency = L2
                else
                    local reg = Library.RegistryMap and Library.RegistryMap[d]
                    if reg and reg.Properties then
                        local bg = reg.Properties.BackgroundColor3
                        if bg == "BackgroundColor" then
                            d.BackgroundColor3 = Library.BackgroundColor
                            d.BackgroundTransparency = L3
                        elseif bg == "MainColor" then
                            d.BackgroundColor3 = Library.MainColor
                            d.BackgroundTransparency = math.min(L3, 0.28)
                        end
                    elseif on and d.BackgroundTransparency < 0.05 and d.BorderSizePixel <= 1 then
                        if d.AbsoluteSize.Y >= 10 then
                            d.BackgroundTransparency = math.min(L3, 0.25)
                        end
                    end
                end
            end
        end
        if on then
            Library.UseBlur = true
            Library.BlurSize = math.clamp(Library.BlurSize or 28, 8, 48)
            Library.UseDarken = true
            Library.DarkenAmount = math.clamp(Library.DarkenAmount or 50, 15, 80)
            if Library.Toggled then
                pcall(function() Library:UpdateBlur() end)
            end
        end
    end)
end

function Library:ReapplyGlass()
    Library.GlassEnabled = Library.GlassEnabled ~= false
    Library.GlassTransparency = Library.GlassTransparency or 0.45
    Library:SetGlass(Library.GlassEnabled, Library.GlassTransparency)
end

function Library:_GlassMix1(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix2(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix3(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix4(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix5(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix6(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix7(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix8(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix9(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix10(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix11(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix12(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix13(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix14(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix15(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix16(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix17(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix18(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix19(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix20(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix21(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix22(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix23(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix24(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix25(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix26(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix27(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix28(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix29(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix30(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix31(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix32(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix33(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix34(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix35(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix36(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix37(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix38(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix39(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix40(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix41(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix42(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix43(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix44(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix45(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix46(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix47(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix48(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix49(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix50(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix51(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix52(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix53(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix54(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix55(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix56(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix57(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix58(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix59(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix60(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix61(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix62(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix63(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix64(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix65(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix66(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix67(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix68(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix69(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix70(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix71(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix72(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix73(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix74(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix75(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix76(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix77(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix78(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix79(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix80(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix81(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix82(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix83(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix84(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix85(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix86(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix87(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix88(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix89(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix90(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix91(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix92(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix93(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix94(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix95(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix96(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix97(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix98(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix99(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix100(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix101(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix102(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix103(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix104(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix105(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix106(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix107(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix108(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix109(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix110(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix111(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix112(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix113(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix114(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix115(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix116(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix117(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix118(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix119(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix120(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix121(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix122(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix123(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix124(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix125(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix126(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix127(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix128(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix129(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix130(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix131(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix132(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix133(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix134(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix135(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix136(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix137(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix138(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix139(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix140(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix141(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix142(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix143(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix144(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix145(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix146(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix147(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix148(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix149(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix150(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix151(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix152(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix153(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix154(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix155(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix156(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix157(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix158(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix159(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix160(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix161(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix162(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix163(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix164(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix165(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix166(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix167(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix168(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix169(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix170(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix171(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix172(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix173(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix174(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix175(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix176(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix177(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix178(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix179(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix180(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix181(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix182(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix183(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix184(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix185(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix186(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix187(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix188(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix189(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix190(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix191(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix192(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix193(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix194(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix195(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix196(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix197(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix198(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix199(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix200(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix201(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix202(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix203(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix204(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix205(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix206(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix207(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix208(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix209(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix210(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix211(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix212(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix213(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix214(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix215(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix216(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix217(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix218(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix219(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix220(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix221(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix222(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix223(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix224(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix225(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix226(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix227(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix228(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix229(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix230(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix231(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix232(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix233(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix234(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix235(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix236(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix237(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix238(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix239(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix240(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix241(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix242(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix243(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix244(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix245(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix246(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix247(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix248(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix249(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix250(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix251(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix252(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix253(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix254(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix255(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix256(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix257(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix258(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix259(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix260(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix261(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix262(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix263(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix264(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix265(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix266(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix267(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix268(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix269(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix270(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix271(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix272(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix273(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix274(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix275(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix276(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix277(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix278(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix279(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix280(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix281(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix282(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix283(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix284(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix285(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix286(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix287(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix288(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix289(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix290(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix291(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix292(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix293(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix294(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix295(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix296(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix297(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix298(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix299(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix300(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix301(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix302(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix303(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix304(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix305(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix306(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix307(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix308(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix309(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix310(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix311(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix312(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix313(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix314(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix315(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix316(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix317(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix318(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix319(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix320(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix321(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix322(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix323(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix324(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix325(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix326(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix327(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix328(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix329(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix330(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix331(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix332(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix333(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix334(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix335(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix336(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix337(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix338(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix339(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix340(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix341(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix342(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix343(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix344(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix345(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix346(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix347(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix348(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix349(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix350(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix351(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix352(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix353(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix354(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix355(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix356(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix357(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix358(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix359(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix360(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix361(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix362(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix363(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix364(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix365(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix366(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix367(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix368(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix369(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix370(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix371(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix372(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix373(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix374(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix375(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix376(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix377(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix378(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix379(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix380(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix381(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix382(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix383(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix384(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix385(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix386(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix387(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix388(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix389(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix390(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix391(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix392(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix393(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix394(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix395(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix396(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix397(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix398(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix399(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix400(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix401(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix402(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix403(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix404(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix405(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix406(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix407(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix408(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix409(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix410(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix411(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix412(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix413(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix414(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix415(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix416(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix417(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix418(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix419(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix420(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix421(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix422(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix423(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix424(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix425(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix426(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix427(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix428(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix429(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix430(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix431(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix432(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix433(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix434(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix435(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix436(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix437(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix438(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix439(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix440(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix441(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix442(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix443(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix444(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix445(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix446(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix447(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix448(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix449(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix450(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix451(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix452(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix453(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix454(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix455(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix456(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix457(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix458(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix459(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix460(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix461(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix462(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix463(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix464(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix465(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix466(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix467(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix468(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix469(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix470(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix471(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix472(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix473(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix474(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix475(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix476(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix477(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix478(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix479(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix480(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix481(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix482(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix483(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix484(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix485(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix486(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix487(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix488(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix489(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix490(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix491(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix492(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix493(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix494(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix495(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix496(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix497(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix498(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix499(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix500(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix501(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix502(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix503(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix504(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix505(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix506(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix507(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix508(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix509(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix510(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix511(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix512(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix513(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix514(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix515(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix516(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix517(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix518(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix519(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix520(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix521(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix522(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix523(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix524(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix525(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix526(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix527(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix528(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix529(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix530(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix531(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix532(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix533(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix534(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix535(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix536(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix537(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix538(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix539(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix540(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix541(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix542(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix543(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix544(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix545(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix546(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix547(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix548(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix549(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix550(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix551(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix552(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix553(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix554(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix555(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix556(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix557(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix558(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix559(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix560(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix561(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix562(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix563(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix564(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix565(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix566(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix567(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix568(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix569(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix570(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix571(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix572(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix573(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix574(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix575(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix576(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix577(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix578(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix579(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix580(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix581(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix582(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix583(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix584(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix585(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix586(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix587(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix588(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix589(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix590(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix591(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix592(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix593(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix594(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix595(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix596(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix597(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix598(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix599(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix600(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix601(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix602(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix603(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix604(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix605(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix606(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix607(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix608(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix609(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix610(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix611(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix612(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix613(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix614(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix615(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix616(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix617(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix618(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix619(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix620(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix621(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix622(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix623(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix624(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix625(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix626(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix627(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix628(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix629(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix630(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix631(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix632(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix633(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix634(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix635(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix636(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix637(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix638(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix639(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix640(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix641(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix642(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix643(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix644(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix645(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix646(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix647(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix648(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix649(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix650(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix651(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix652(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix653(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix654(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix655(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix656(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix657(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix658(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix659(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix660(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix661(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix662(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix663(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix664(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix665(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix666(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix667(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix668(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix669(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix670(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix671(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix672(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix673(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix674(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix675(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix676(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix677(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix678(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix679(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix680(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix681(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix682(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix683(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix684(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix685(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix686(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix687(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix688(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix689(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix690(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix691(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix692(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix693(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix694(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix695(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix696(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix697(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix698(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix699(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix700(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix701(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix702(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix703(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix704(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix705(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix706(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix707(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix708(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix709(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix710(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix711(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix712(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix713(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix714(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix715(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix716(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix717(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix718(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix719(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix720(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix721(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix722(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix723(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix724(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix725(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix726(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix727(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix728(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix729(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix730(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix731(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix732(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix733(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix734(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix735(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix736(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix737(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix738(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix739(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix740(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix741(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix742(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix743(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix744(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix745(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix746(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix747(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix748(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix749(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix750(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix751(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix752(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix753(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix754(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix755(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix756(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix757(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix758(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix759(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix760(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix761(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix762(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix763(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix764(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix765(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix766(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix767(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix768(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix769(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix770(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix771(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix772(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix773(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix774(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix775(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix776(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix777(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix778(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix779(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix780(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix781(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix782(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix783(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix784(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix785(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix786(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix787(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix788(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix789(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix790(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix791(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix792(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix793(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix794(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix795(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix796(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix797(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix798(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix799(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix800(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix801(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix802(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix803(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix804(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix805(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix806(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix807(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix808(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix809(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix810(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix811(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix812(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix813(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix814(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix815(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix816(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix817(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix818(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix819(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix820(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix821(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix822(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix823(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix824(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix825(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix826(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix827(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix828(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix829(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix830(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix831(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix832(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix833(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix834(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix835(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix836(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix837(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix838(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix839(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix840(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix841(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix842(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix843(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix844(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix845(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix846(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix847(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix848(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix849(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix850(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix851(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix852(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix853(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix854(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix855(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix856(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix857(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix858(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix859(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix860(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix861(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix862(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix863(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix864(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix865(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix866(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix867(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix868(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix869(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix870(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix871(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix872(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix873(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix874(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix875(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix876(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix877(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix878(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix879(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix880(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix881(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix882(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix883(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix884(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix885(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix886(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix887(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix888(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix889(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix890(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix891(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix892(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix893(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix894(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix895(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix896(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix897(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix898(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix899(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix900(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix901(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix902(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix903(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix904(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix905(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix906(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix907(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix908(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix909(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix910(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix911(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix912(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix913(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix914(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix915(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix916(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix917(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix918(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix919(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix920(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix921(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix922(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix923(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix924(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix925(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix926(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix927(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix928(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix929(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix930(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix931(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix932(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix933(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix934(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix935(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix936(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix937(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix938(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix939(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix940(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix941(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix942(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix943(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix944(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix945(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix946(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix947(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix948(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix949(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix950(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix951(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix952(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix953(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix954(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix955(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix956(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix957(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix958(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix959(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix960(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix961(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix962(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix963(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix964(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix965(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix966(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix967(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix968(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix969(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix970(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix971(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix972(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix973(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix974(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix975(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix976(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix977(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix978(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix979(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix980(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix981(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix982(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix983(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix984(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix985(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix986(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix987(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix988(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix989(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix990(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix991(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix992(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix993(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix994(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix995(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix996(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix997(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix998(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix999(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1000(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1001(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1002(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1003(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1004(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1005(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1006(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1007(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1008(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1009(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1010(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1011(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1012(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1013(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1014(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1015(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1016(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1017(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1018(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1019(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1020(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1021(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1022(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1023(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1024(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1025(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1026(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1027(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1028(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1029(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1030(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1031(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1032(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1033(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1034(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1035(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1036(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1037(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1038(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1039(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1040(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1041(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1042(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1043(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1044(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1045(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1046(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1047(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1048(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1049(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1050(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1051(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1052(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1053(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1054(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1055(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1056(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1057(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1058(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1059(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1060(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1061(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1062(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1063(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1064(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1065(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1066(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1067(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1068(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1069(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1070(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1071(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1072(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1073(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1074(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1075(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1076(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1077(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1078(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1079(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1080(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1081(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1082(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1083(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1084(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1085(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1086(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1087(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1088(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1089(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1090(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1091(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1092(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1093(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1094(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1095(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1096(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1097(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1098(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1099(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1100(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1101(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1102(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1103(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1104(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1105(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1106(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1107(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1108(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1109(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1110(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1111(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1112(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1113(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1114(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1115(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1116(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1117(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1118(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1119(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1120(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1121(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1122(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1123(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1124(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1125(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1126(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1127(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1128(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1129(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1130(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1131(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1132(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1133(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1134(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1135(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1136(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1137(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1138(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1139(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1140(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1141(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1142(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1143(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1144(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1145(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1146(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1147(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1148(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1149(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1150(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1151(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1152(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1153(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1154(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1155(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1156(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1157(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1158(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1159(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1160(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1161(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1162(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1163(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1164(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1165(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1166(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1167(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1168(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1169(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1170(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1171(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1172(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1173(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1174(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1175(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1176(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1177(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1178(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1179(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

function Library:_GlassMix1180(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.2), 0, 0.75)
end

function Library:_GlassMix1181(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.23), 0, 0.75)
end

function Library:_GlassMix1182(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.26), 0, 0.75)
end

function Library:_GlassMix1183(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.29000000000000004), 0, 0.75)
end

function Library:_GlassMix1184(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.32), 0, 0.75)
end

function Library:_GlassMix1185(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.35), 0, 0.75)
end

function Library:_GlassMix1186(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.38), 0, 0.75)
end

function Library:_GlassMix1187(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.41000000000000003), 0, 0.75)
end

function Library:_GlassMix1188(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.44), 0, 0.75)
end

function Library:_GlassMix1189(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.47000000000000003), 0, 0.75)
end

function Library:_GlassMix1190(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5), 0, 0.75)
end

function Library:_GlassMix1191(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.53), 0, 0.75)
end

function Library:_GlassMix1192(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.56), 0, 0.75)
end

function Library:_GlassMix1193(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.5900000000000001), 0, 0.75)
end

function Library:_GlassMix1194(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.62), 0, 0.75)
end

function Library:_GlassMix1195(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6499999999999999), 0, 0.75)
end

function Library:_GlassMix1196(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.6799999999999999), 0, 0.75)
end

function Library:_GlassMix1197(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.71), 0, 0.75)
end

function Library:_GlassMix1198(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.74), 0, 0.75)
end

function Library:_GlassMix1199(base)
    base = tonumber(base) or Library.GlassTransparency or 0.45
    if not Library.GlassEnabled then return 0 end
    return math.clamp(base * (0.77), 0, 0.75)
end

-- ========== RCLR LOGO (behind UI, center, open only) ==========
function Library:CreateLogo(Info)
    Info = Info or {}
    pcall(function()
        if Library._LogoGui then Library._LogoGui:Destroy() end
        if Library._LogoSpinConn then Library._LogoSpinConn:Disconnect() end
    end)

    local text = tostring(Info.Text or "RCLR")
    local size = tonumber(Info.TextSize) or 72
    local speed = tonumber(Info.SpinSpeed) or 20

    local gui = Instance.new("ScreenGui")
    gui.Name = "RCLR_LogoBehind"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = -100 -- behind main UI
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Enabled = Library.Toggled == true
    pcall(function() ProtectGui(gui) end)
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui
    end

    local holder = Instance.new("Frame")
    holder.Name = "LogoHolder"
    holder.BackgroundTransparency = 1
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.Size = UDim2.fromOffset(size * 4, size * 4)
    holder.ZIndex = 1
    holder.Parent = gui

    local label = Instance.new("TextLabel")
    label.Name = "LogoText"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextSize = size
    label.TextColor3 = Library.AccentColor or Color3.fromRGB(255, 255, 255)
    label.TextTransparency = 0.55
    label.TextStrokeTransparency = 0.8
    label.ZIndex = 2
    label.Parent = holder

    local angle = 0
    local conn = RunService.RenderStepped:Connect(function(dt)
        if not gui.Parent then return end
        if Library.Toggled ~= true then
            gui.Enabled = false
            return
        end
        gui.Enabled = true
        angle = (angle + speed * dt) % 360
        holder.Rotation = angle
        label.TextColor3 = Library.AccentColor or label.TextColor3
    end)
    Library._LogoSpinConn = conn
    table.insert(Library.Signals, conn)
    Library._LogoGui = gui

    local function sync()
        gui.Enabled = Library.Toggled == true
    end
    Library._LogoSync = sync
    sync()

    return {
        SetText = function(_, t) label.Text = tostring(t) end,
        SetVisible = function(_, v) gui.Enabled = not not v end,
        SetSpinSpeed = function(_, sp) speed = tonumber(sp) or speed end,
        Destroy = function()
            pcall(function() conn:Disconnect() end)
            pcall(function() gui:Destroy() end)
            Library._LogoGui = nil
        end,
        Sync = sync,
    }
end

function Library:UpdateLogoVisibility()
    if Library._LogoSync then
        pcall(Library._LogoSync)
    elseif Library._LogoGui then
        Library._LogoGui.Enabled = Library.Toggled == true
    end
end

getgenv().Library = Library
return Library
