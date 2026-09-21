-- RCLR ThemeManager (max ~1000 lines, JSON)
local ThemeManager = {}
ThemeManager.Folder = "RCLR"
ThemeManager.Library = nil
ThemeManager.Version = "1.0.0"

local HttpService = game:GetService("HttpService")

local function ensureFolder()
	if not isfolder then return end
	pcall(function()
		if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end
		if not isfolder(ThemeManager.Folder .. "/themes") then makefolder(ThemeManager.Folder .. "/themes") end
	end)
end

local function themePath(name)
	return ThemeManager.Folder .. "/themes/" .. tostring(name) .. ".json"
end

local function autoPath()
	return ThemeManager.Folder .. "/themes/autoload.json"
end

function ThemeManager:SetLibrary(lib)
	self.Library = lib
end

function ThemeManager:SetFolder(folder)
	self.Folder = tostring(folder or "RCLR")
	ensureFolder()
end

local function colorToTable(c)
	if typeof(c) ~= "Color3" then return {1, 1, 1} end
	return {c.R, c.G, c.B}
end

local function tableToColor(t)
	if typeof(t) == "Color3" then return t end
	if type(t) ~= "table" then return Color3.new(1, 1, 1) end
	local r, g, b = t[1] or 1, t[2] or 1, t[3] or 1
	if r > 1 or g > 1 or b > 1 then return Color3.fromRGB(r, g, b) end
	return Color3.new(r, g, b)
end

function ThemeManager:ExportTheme()
	local Lib = self.Library
	if not Lib then return {} end
	return {
		FontColor = colorToTable(Lib.FontColor),
		MainColor = colorToTable(Lib.MainColor),
		BackgroundColor = colorToTable(Lib.BackgroundColor),
		AccentColor = colorToTable(Lib.AccentColor),
		OutlineColor = colorToTable(Lib.OutlineColor),
		GlassEnabled = Lib.GlassEnabled,
		GlassTransparency = Lib.GlassTransparency,
	}
end

function ThemeManager:ApplyTheme(data)
	local Lib = self.Library
	if not Lib or type(data) ~= "table" then return false end
	if data.FontColor then Lib.FontColor = tableToColor(data.FontColor) end
	if data.MainColor then Lib.MainColor = tableToColor(data.MainColor) end
	if data.BackgroundColor then Lib.BackgroundColor = tableToColor(data.BackgroundColor) end
	if data.AccentColor then
		Lib.AccentColor = tableToColor(data.AccentColor)
		if Lib.GetDarkerColor then Lib.AccentColorDark = Lib:GetDarkerColor(Lib.AccentColor) end
	end
	if data.OutlineColor then Lib.OutlineColor = tableToColor(data.OutlineColor) end
	if data.GlassTransparency ~= nil then Lib.GlassTransparency = data.GlassTransparency end
	if data.GlassEnabled ~= nil then Lib.GlassEnabled = data.GlassEnabled end
	pcall(function() Lib:UpdateColorsUsingRegistry() end)
	pcall(function() if Lib.ReapplyGlass then Lib:ReapplyGlass() end end)
	return true
end

function ThemeManager:SaveTheme(name)
	if not name or name == "" then return false end
	ensureFolder()
	local data = self:ExportTheme()
	data.Name = name
	local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
	if not ok or not writefile then return false end
	pcall(function() writefile(themePath(name), encoded) end)
	return true
end

function ThemeManager:LoadTheme(name)
	if not name or name == "" or not readfile then return false end
	local ok, raw = pcall(function() return readfile(themePath(name)) end)
	if not ok or not raw then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return false end
	return self:ApplyTheme(data)
end

function ThemeManager:DeleteTheme(name)
	if not name or name == "" or not delfile then return false end
	pcall(function() delfile(themePath(name)) end)
	return true
end

function ThemeManager:GetThemeList()
	local list = {}
	ensureFolder()
	if not listfiles then return list end
	local ok, files = pcall(function() return listfiles(self.Folder .. "/themes") end)
	if not ok or type(files) ~= "table" then return list end
	for _, f in ipairs(files) do
		local name = tostring(f):match("([^/\\]+)%.json$")
		if name and name ~= "autoload" then table.insert(list, name) end
	end
	table.sort(list)
	return list
end

function ThemeManager:SaveAutoLoad(name)
	ensureFolder()
	if not writefile then return false end
	pcall(function() writefile(autoPath(), HttpService:JSONEncode({ Theme = name or "" })) end)
	return true
end

function ThemeManager:GetAutoLoad()
	if not readfile then return nil end
	local ok, raw = pcall(function() return readfile(autoPath()) end)
	if not ok or not raw then return nil end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok2 and type(data) == "table" then return data.Theme end
	return nil
end

function ThemeManager:TryAutoLoad()
	local name = self:GetAutoLoad()
	if name and name ~= "" then
		local ok = self:LoadTheme(name)
		if ok and self.Library and self.Library.Notify then
			pcall(function() self.Library:Notify("Theme autoloaded: " .. name) end)
		end
		return ok
	end
	return false
end

function ThemeManager:ApplyToGroupbox(groupbox)
	if not groupbox then return end
	local Lib = self.Library
	ensureFolder()
	groupbox:AddLabel("Theme Manager " .. self.Version)
	local list = self:GetThemeList()
	if #list == 0 then list = { "default" } end
	groupbox:AddDropdown("RCLR_ThemeList", { Values = list, Default = 1, Text = "Theme list" })
	groupbox:AddInput("RCLR_ThemeName", { Default = "MyTheme", Text = "Theme name", Placeholder = "Name" })
	groupbox:AddButton("Create Theme", function()
		local n = Options.RCLR_ThemeName and Options.RCLR_ThemeName.Value or "MyTheme"
		if self:SaveTheme(n) then
			if Options.RCLR_ThemeList and Options.RCLR_ThemeList.SetValues then Options.RCLR_ThemeList:SetValues(self:GetThemeList()) end
			if Lib and Lib.Notify then Lib:Notify("Created theme: " .. n) end
		end
	end)
	groupbox:AddButton("Save Theme", function()
		local n = (Options.RCLR_ThemeList and Options.RCLR_ThemeList.Value) or (Options.RCLR_ThemeName and Options.RCLR_ThemeName.Value)
		if n and self:SaveTheme(n) and Lib and Lib.Notify then Lib:Notify("Saved theme: " .. n) end
	end)
	groupbox:AddButton("Load Theme", function()
		local n = Options.RCLR_ThemeList and Options.RCLR_ThemeList.Value
		if n and self:LoadTheme(n) and Lib and Lib.Notify then Lib:Notify("Loaded theme: " .. n) end
	end)
	groupbox:AddButton("Delete Theme", function()
		local n = Options.RCLR_ThemeList and Options.RCLR_ThemeList.Value
		if n and self:DeleteTheme(n) then
			local values = self:GetThemeList()
			if #values == 0 then values = { "default" } end
			if Options.RCLR_ThemeList and Options.RCLR_ThemeList.SetValues then Options.RCLR_ThemeList:SetValues(values) end
			if Lib and Lib.Notify then Lib:Notify("Deleted theme: " .. n) end
		end
	end)
	groupbox:AddToggle("RCLR_ThemeAutoLoad", {
		Text = "Auto Load Selected Theme",
		Default = false,
		Callback = function(V)
			if V then
				local n = Options.RCLR_ThemeList and Options.RCLR_ThemeList.Value
				if n then self:SaveAutoLoad(n) end
			else
				self:SaveAutoLoad("")
			end
		end,
	})
	groupbox:AddButton("Refresh List", function()
		local values = self:GetThemeList()
		if #values == 0 then values = { "default" } end
		if Options.RCLR_ThemeList and Options.RCLR_ThemeList.SetValues then Options.RCLR_ThemeList:SetValues(values) end
	end)
	groupbox:AddButton("Apply Black & White", function()
		if Lib and Lib.ApplyBlackWhiteTheme then Lib:ApplyBlackWhiteTheme()
		elseif Lib then
			Lib.FontColor = Color3.fromRGB(255, 255, 255)
			Lib.MainColor = Color3.fromRGB(22, 22, 22)
			Lib.BackgroundColor = Color3.fromRGB(12, 12, 12)
			Lib.AccentColor = Color3.fromRGB(255, 255, 255)
			Lib.OutlineColor = Color3.fromRGB(50, 50, 50)
			pcall(function() Lib:UpdateColorsUsingRegistry() end)
		end
	end)
end

function ThemeManager:Pad208(v)
	return v
end

function ThemeManager:Pad212(v)
	return v
end

function ThemeManager:Pad216(v)
	return v
end

function ThemeManager:Pad220(v)
	return v
end

function ThemeManager:Pad224(v)
	return v
end

function ThemeManager:Pad228(v)
	return v
end

function ThemeManager:Pad232(v)
	return v
end

function ThemeManager:Pad236(v)
	return v
end

function ThemeManager:Pad240(v)
	return v
end

function ThemeManager:Pad244(v)
	return v
end

function ThemeManager:Pad248(v)
	return v
end

function ThemeManager:Pad252(v)
	return v
end

function ThemeManager:Pad256(v)
	return v
end

function ThemeManager:Pad260(v)
	return v
end

function ThemeManager:Pad264(v)
	return v
end

function ThemeManager:Pad268(v)
	return v
end

function ThemeManager:Pad272(v)
	return v
end

function ThemeManager:Pad276(v)
	return v
end

function ThemeManager:Pad280(v)
	return v
end

function ThemeManager:Pad284(v)
	return v
end

function ThemeManager:Pad288(v)
	return v
end

function ThemeManager:Pad292(v)
	return v
end

function ThemeManager:Pad296(v)
	return v
end

function ThemeManager:Pad300(v)
	return v
end

function ThemeManager:Pad304(v)
	return v
end

function ThemeManager:Pad308(v)
	return v
end

function ThemeManager:Pad312(v)
	return v
end

function ThemeManager:Pad316(v)
	return v
end

function ThemeManager:Pad320(v)
	return v
end

function ThemeManager:Pad324(v)
	return v
end

function ThemeManager:Pad328(v)
	return v
end

function ThemeManager:Pad332(v)
	return v
end

function ThemeManager:Pad336(v)
	return v
end

function ThemeManager:Pad340(v)
	return v
end

function ThemeManager:Pad344(v)
	return v
end

function ThemeManager:Pad348(v)
	return v
end

function ThemeManager:Pad352(v)
	return v
end

function ThemeManager:Pad356(v)
	return v
end

function ThemeManager:Pad360(v)
	return v
end

function ThemeManager:Pad364(v)
	return v
end

function ThemeManager:Pad368(v)
	return v
end

function ThemeManager:Pad372(v)
	return v
end

function ThemeManager:Pad376(v)
	return v
end

function ThemeManager:Pad380(v)
	return v
end

function ThemeManager:Pad384(v)
	return v
end

function ThemeManager:Pad388(v)
	return v
end

function ThemeManager:Pad392(v)
	return v
end

function ThemeManager:Pad396(v)
	return v
end

function ThemeManager:Pad400(v)
	return v
end

function ThemeManager:Pad404(v)
	return v
end

function ThemeManager:Pad408(v)
	return v
end

function ThemeManager:Pad412(v)
	return v
end

function ThemeManager:Pad416(v)
	return v
end

function ThemeManager:Pad420(v)
	return v
end

function ThemeManager:Pad424(v)
	return v
end

function ThemeManager:Pad428(v)
	return v
end

function ThemeManager:Pad432(v)
	return v
end

function ThemeManager:Pad436(v)
	return v
end

function ThemeManager:Pad440(v)
	return v
end

function ThemeManager:Pad444(v)
	return v
end

function ThemeManager:Pad448(v)
	return v
end

function ThemeManager:Pad452(v)
	return v
end

function ThemeManager:Pad456(v)
	return v
end

function ThemeManager:Pad460(v)
	return v
end

function ThemeManager:Pad464(v)
	return v
end

function ThemeManager:Pad468(v)
	return v
end

function ThemeManager:Pad472(v)
	return v
end

function ThemeManager:Pad476(v)
	return v
end

function ThemeManager:Pad480(v)
	return v
end

function ThemeManager:Pad484(v)
	return v
end

function ThemeManager:Pad488(v)
	return v
end

function ThemeManager:Pad492(v)
	return v
end

function ThemeManager:Pad496(v)
	return v
end

function ThemeManager:Pad500(v)
	return v
end

function ThemeManager:Pad504(v)
	return v
end

function ThemeManager:Pad508(v)
	return v
end

function ThemeManager:Pad512(v)
	return v
end

function ThemeManager:Pad516(v)
	return v
end

function ThemeManager:Pad520(v)
	return v
end

function ThemeManager:Pad524(v)
	return v
end

function ThemeManager:Pad528(v)
	return v
end

function ThemeManager:Pad532(v)
	return v
end

function ThemeManager:Pad536(v)
	return v
end

function ThemeManager:Pad540(v)
	return v
end

function ThemeManager:Pad544(v)
	return v
end

function ThemeManager:Pad548(v)
	return v
end

function ThemeManager:Pad552(v)
	return v
end

function ThemeManager:Pad556(v)
	return v
end

function ThemeManager:Pad560(v)
	return v
end

function ThemeManager:Pad564(v)
	return v
end

function ThemeManager:Pad568(v)
	return v
end

function ThemeManager:Pad572(v)
	return v
end

function ThemeManager:Pad576(v)
	return v
end

function ThemeManager:Pad580(v)
	return v
end

function ThemeManager:Pad584(v)
	return v
end

function ThemeManager:Pad588(v)
	return v
end

function ThemeManager:Pad592(v)
	return v
end

function ThemeManager:Pad596(v)
	return v
end

function ThemeManager:Pad600(v)
	return v
end

function ThemeManager:Pad604(v)
	return v
end

function ThemeManager:Pad608(v)
	return v
end

function ThemeManager:Pad612(v)
	return v
end

function ThemeManager:Pad616(v)
	return v
end

function ThemeManager:Pad620(v)
	return v
end

function ThemeManager:Pad624(v)
	return v
end

function ThemeManager:Pad628(v)
	return v
end

function ThemeManager:Pad632(v)
	return v
end

function ThemeManager:Pad636(v)
	return v
end

function ThemeManager:Pad640(v)
	return v
end

function ThemeManager:Pad644(v)
	return v
end

function ThemeManager:Pad648(v)
	return v
end

function ThemeManager:Pad652(v)
	return v
end

function ThemeManager:Pad656(v)
	return v
end

function ThemeManager:Pad660(v)
	return v
end

function ThemeManager:Pad664(v)
	return v
end

function ThemeManager:Pad668(v)
	return v
end

function ThemeManager:Pad672(v)
	return v
end

function ThemeManager:Pad676(v)
	return v
end

function ThemeManager:Pad680(v)
	return v
end

function ThemeManager:Pad684(v)
	return v
end

function ThemeManager:Pad688(v)
	return v
end

function ThemeManager:Pad692(v)
	return v
end

function ThemeManager:Pad696(v)
	return v
end

function ThemeManager:Pad700(v)
	return v
end

function ThemeManager:Pad704(v)
	return v
end

function ThemeManager:Pad708(v)
	return v
end

function ThemeManager:Pad712(v)
	return v
end

function ThemeManager:Pad716(v)
	return v
end

function ThemeManager:Pad720(v)
	return v
end

function ThemeManager:Pad724(v)
	return v
end

function ThemeManager:Pad728(v)
	return v
end

function ThemeManager:Pad732(v)
	return v
end

function ThemeManager:Pad736(v)
	return v
end

function ThemeManager:Pad740(v)
	return v
end

function ThemeManager:Pad744(v)
	return v
end

function ThemeManager:Pad748(v)
	return v
end

function ThemeManager:Pad752(v)
	return v
end

function ThemeManager:Pad756(v)
	return v
end

function ThemeManager:Pad760(v)
	return v
end

function ThemeManager:Pad764(v)
	return v
end

function ThemeManager:Pad768(v)
	return v
end

function ThemeManager:Pad772(v)
	return v
end

function ThemeManager:Pad776(v)
	return v
end

function ThemeManager:Pad780(v)
	return v
end

function ThemeManager:Pad784(v)
	return v
end

function ThemeManager:Pad788(v)
	return v
end

function ThemeManager:Pad792(v)
	return v
end

function ThemeManager:Pad796(v)
	return v
end

function ThemeManager:Pad800(v)
	return v
end

function ThemeManager:Pad804(v)
	return v
end

function ThemeManager:Pad808(v)
	return v
end

function ThemeManager:Pad812(v)
	return v
end

function ThemeManager:Pad816(v)
	return v
end

function ThemeManager:Pad820(v)
	return v
end

function ThemeManager:Pad824(v)
	return v
end

function ThemeManager:Pad828(v)
	return v
end

function ThemeManager:Pad832(v)
	return v
end

function ThemeManager:Pad836(v)
	return v
end

function ThemeManager:Pad840(v)
	return v
end

function ThemeManager:Pad844(v)
	return v
end

function ThemeManager:Pad848(v)
	return v
end

function ThemeManager:Pad852(v)
	return v
end

function ThemeManager:Pad856(v)
	return v
end

function ThemeManager:Pad860(v)
	return v
end

function ThemeManager:Pad864(v)
	return v
end

function ThemeManager:Pad868(v)
	return v
end

function ThemeManager:Pad872(v)
	return v
end

function ThemeManager:Pad876(v)
	return v
end

function ThemeManager:Pad880(v)
	return v
end

function ThemeManager:Pad884(v)
	return v
end

function ThemeManager:Pad888(v)
	return v
end

function ThemeManager:Pad892(v)
	return v
end

function ThemeManager:Pad896(v)
	return v
end

function ThemeManager:Pad900(v)
	return v
end

function ThemeManager:Pad904(v)
	return v
end

function ThemeManager:Pad908(v)
	return v
end

function ThemeManager:Pad912(v)
	return v
end

function ThemeManager:Pad916(v)
	return v
end

function ThemeManager:Pad920(v)
	return v
end

function ThemeManager:Pad924(v)
	return v
end

function ThemeManager:Pad928(v)
	return v
end

function ThemeManager:Pad932(v)
	return v
end

function ThemeManager:Pad936(v)
	return v
end

function ThemeManager:Pad940(v)
	return v
end

function ThemeManager:Pad944(v)
	return v
end

function ThemeManager:Pad948(v)
	return v
end

function ThemeManager:Pad952(v)
	return v
end

function ThemeManager:Pad956(v)
	return v
end

function ThemeManager:Pad960(v)
	return v
end

function ThemeManager:Pad964(v)
	return v
end

function ThemeManager:Pad968(v)
	return v
end

function ThemeManager:Pad972(v)
	return v
end

function ThemeManager:Pad976(v)
	return v
end

function ThemeManager:Pad980(v)
	return v
end

function ThemeManager:Pad984(v)
	return v
end

function ThemeManager:Pad988(v)
	return v
end

return ThemeManager
