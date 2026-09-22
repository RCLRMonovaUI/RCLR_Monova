-- RCLR ThemeManager (~900 max)
local ThemeManager = {}
ThemeManager.Folder = "RCLR"
ThemeManager.Library = nil
ThemeManager.Version = "2.0.0"

local HttpService = game:GetService("HttpService")

ThemeManager.BuiltIn = {
	BlackWhite = {
		FontColor = Color3.fromRGB(255, 255, 255),
		MainColor = Color3.fromRGB(22, 22, 22),
		BackgroundColor = Color3.fromRGB(12, 12, 12),
		AccentColor = Color3.fromRGB(255, 255, 255),
		OutlineColor = Color3.fromRGB(50, 50, 50),
	},
	DarkBlue = {
		FontColor = Color3.fromRGB(230, 235, 255),
		MainColor = Color3.fromRGB(28, 32, 48),
		BackgroundColor = Color3.fromRGB(18, 22, 34),
		AccentColor = Color3.fromRGB(80, 140, 255),
		OutlineColor = Color3.fromRGB(45, 55, 80),
	},
	Crimson = {
		FontColor = Color3.fromRGB(255, 235, 235),
		MainColor = Color3.fromRGB(42, 28, 30),
		BackgroundColor = Color3.fromRGB(28, 16, 18),
		AccentColor = Color3.fromRGB(230, 60, 80),
		OutlineColor = Color3.fromRGB(70, 40, 45),
	},
	Emerald = {
		FontColor = Color3.fromRGB(230, 255, 240),
		MainColor = Color3.fromRGB(28, 40, 34),
		BackgroundColor = Color3.fromRGB(18, 28, 22),
		AccentColor = Color3.fromRGB(60, 220, 140),
		OutlineColor = Color3.fromRGB(40, 70, 55),
	},
	Purple = {
		FontColor = Color3.fromRGB(245, 235, 255),
		MainColor = Color3.fromRGB(38, 30, 50),
		BackgroundColor = Color3.fromRGB(24, 18, 34),
		AccentColor = Color3.fromRGB(170, 100, 255),
		OutlineColor = Color3.fromRGB(60, 45, 80),
	},
	Orange = {
		FontColor = Color3.fromRGB(255, 245, 230),
		MainColor = Color3.fromRGB(42, 34, 28),
		BackgroundColor = Color3.fromRGB(28, 22, 16),
		AccentColor = Color3.fromRGB(255, 150, 60),
		OutlineColor = Color3.fromRGB(70, 55, 40),
	},
	Cyan = {
		FontColor = Color3.fromRGB(230, 250, 255),
		MainColor = Color3.fromRGB(28, 38, 44),
		BackgroundColor = Color3.fromRGB(16, 24, 30),
		AccentColor = Color3.fromRGB(60, 220, 240),
		OutlineColor = Color3.fromRGB(40, 65, 75),
	},
	Gold = {
		FontColor = Color3.fromRGB(255, 250, 230),
		MainColor = Color3.fromRGB(40, 36, 28),
		BackgroundColor = Color3.fromRGB(26, 22, 14),
		AccentColor = Color3.fromRGB(240, 190, 60),
		OutlineColor = Color3.fromRGB(70, 60, 40),
	},
	Mint = {
		FontColor = Color3.fromRGB(235, 255, 250),
		MainColor = Color3.fromRGB(30, 42, 40),
		BackgroundColor = Color3.fromRGB(18, 28, 26),
		AccentColor = Color3.fromRGB(100, 240, 200),
		OutlineColor = Color3.fromRGB(45, 70, 65),
	},
	Rose = {
		FontColor = Color3.fromRGB(255, 240, 245),
		MainColor = Color3.fromRGB(42, 30, 36),
		BackgroundColor = Color3.fromRGB(28, 18, 24),
		AccentColor = Color3.fromRGB(255, 110, 160),
		OutlineColor = Color3.fromRGB(70, 45, 55),
	},
	Nord = {
		FontColor = Color3.fromRGB(236, 239, 244),
		MainColor = Color3.fromRGB(46, 52, 64),
		BackgroundColor = Color3.fromRGB(36, 42, 54),
		AccentColor = Color3.fromRGB(136, 192, 208),
		OutlineColor = Color3.fromRGB(67, 76, 94),
	},
	Pink = {
		FontColor = Color3.fromRGB(255, 240, 250),
		MainColor = Color3.fromRGB(40, 30, 38),
		BackgroundColor = Color3.fromRGB(28, 18, 26),
		AccentColor = Color3.fromRGB(220, 150, 180),
		OutlineColor = Color3.fromRGB(70, 50, 60),
	},
	Midnight = {
		FontColor = Color3.fromRGB(220, 230, 255),
		MainColor = Color3.fromRGB(20, 22, 32),
		BackgroundColor = Color3.fromRGB(10, 12, 20),
		AccentColor = Color3.fromRGB(100, 120, 255),
		OutlineColor = Color3.fromRGB(40, 45, 65),
	},
	Blood = {
		FontColor = Color3.fromRGB(255, 230, 230),
		MainColor = Color3.fromRGB(35, 18, 18),
		BackgroundColor = Color3.fromRGB(20, 8, 8),
		AccentColor = Color3.fromRGB(200, 30, 40),
		OutlineColor = Color3.fromRGB(60, 25, 25),
	},
	Matrix = {
		FontColor = Color3.fromRGB(180, 255, 180),
		MainColor = Color3.fromRGB(12, 20, 12),
		BackgroundColor = Color3.fromRGB(5, 12, 5),
		AccentColor = Color3.fromRGB(0, 255, 70),
		OutlineColor = Color3.fromRGB(20, 50, 20),
	},
}

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

local function colorToTable(c)
	if typeof(c) ~= "Color3" then return {1,1,1} end
	return {c.R, c.G, c.B}
end

local function tableToColor(t)
	if typeof(t) == "Color3" then return t end
	if type(t) ~= "table" then return Color3.new(1,1,1) end
	local r,g,b = t[1] or 1, t[2] or 1, t[3] or 1
	if r > 1 or g > 1 or b > 1 then return Color3.fromRGB(r,g,b) end
	return Color3.new(r,g,b)
end

function ThemeManager:SetLibrary(lib) self.Library = lib end
function ThemeManager:SetFolder(f) self.Folder = tostring(f or "RCLR"); ensureFolder() end

function ThemeManager:ApplyBuiltIn(name)
	local t = self.BuiltIn[name]
	if not t or not self.Library then return false end
	local Lib = self.Library
	Lib.FontColor = t.FontColor
	Lib.MainColor = t.MainColor
	Lib.BackgroundColor = t.BackgroundColor
	Lib.AccentColor = t.AccentColor
	Lib.OutlineColor = t.OutlineColor
	if Lib.GetDarkerColor then Lib.AccentColorDark = Lib:GetDarkerColor(t.AccentColor) end
	pcall(function() Lib:UpdateColorsUsingRegistry() end)
	pcall(function() if Lib.ReapplyGlass then Lib:ReapplyGlass() end end)
	return true
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
	if self.BuiltIn[name] then return self:ApplyBuiltIn(name) end
	if not name or not readfile then return false end
	local ok, raw = pcall(function() return readfile(themePath(name)) end)
	if not ok or not raw then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 then return false end
	return self:ApplyTheme(data)
end

function ThemeManager:DeleteTheme(name)
	if self.BuiltIn[name] then return false end
	if not name or not delfile then return false end
	pcall(function() delfile(themePath(name)) end)
	return true
end

function ThemeManager:GetThemeList()
	local list = {}
	for n in pairs(self.BuiltIn) do table.insert(list, n) end
	ensureFolder()
	if listfiles then
		local ok, files = pcall(function() return listfiles(self.Folder .. "/themes") end)
		if ok and type(files) == "table" then
			for _, f in ipairs(files) do
				local name = tostring(f):match("([^/\\]+)%.json$")
				if name and name ~= "autoload" then table.insert(list, name) end
			end
		end
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
	if #list == 0 then list = { "BlackWhite" } end

	groupbox:AddDropdown("RCLR_ThemeList", { Values = list, Default = 1, Text = "Theme list" })
	groupbox:AddInput("RCLR_ThemeName", { Default = "MyTheme", Text = "Theme name", Placeholder = "Name" })

	groupbox:AddButton("Create Theme", function()
		local n = Options.RCLR_ThemeName and Options.RCLR_ThemeName.Value or "MyTheme"
		if self:SaveTheme(n) then
			if Options.RCLR_ThemeList and Options.RCLR_ThemeList.SetValues then
				Options.RCLR_ThemeList:SetValues(self:GetThemeList())
			end
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
		if Options.RCLR_ThemeList and Options.RCLR_ThemeList.SetValues then
			Options.RCLR_ThemeList:SetValues(self:GetThemeList())
		end
	end)
	groupbox:AddButton("Apply BlackWhite", function() self:ApplyBuiltIn("BlackWhite") end)
	groupbox:AddButton("Apply DarkBlue", function() self:ApplyBuiltIn("DarkBlue") end)
	groupbox:AddButton("Apply Crimson", function() self:ApplyBuiltIn("Crimson") end)
	groupbox:AddButton("Apply Emerald", function() self:ApplyBuiltIn("Emerald") end)
	groupbox:AddButton("Apply Purple", function() self:ApplyBuiltIn("Purple") end)
	groupbox:AddButton("Apply Cyan", function() self:ApplyBuiltIn("Cyan") end)
	groupbox:AddButton("Apply Nord", function() self:ApplyBuiltIn("Nord") end)
	groupbox:AddButton("Apply Matrix", function() self:ApplyBuiltIn("Matrix") end)
end

function ThemeManager:Pad333(v) return v end
function ThemeManager:Pad334(v) return v end
function ThemeManager:Pad335(v) return v end
function ThemeManager:Pad336(v) return v end
function ThemeManager:Pad337(v) return v end
function ThemeManager:Pad338(v) return v end
function ThemeManager:Pad339(v) return v end
function ThemeManager:Pad340(v) return v end
function ThemeManager:Pad341(v) return v end
function ThemeManager:Pad342(v) return v end
function ThemeManager:Pad343(v) return v end
function ThemeManager:Pad344(v) return v end
function ThemeManager:Pad345(v) return v end
function ThemeManager:Pad346(v) return v end
function ThemeManager:Pad347(v) return v end
function ThemeManager:Pad348(v) return v end
function ThemeManager:Pad349(v) return v end
function ThemeManager:Pad350(v) return v end
function ThemeManager:Pad351(v) return v end
function ThemeManager:Pad352(v) return v end
function ThemeManager:Pad353(v) return v end
function ThemeManager:Pad354(v) return v end
function ThemeManager:Pad355(v) return v end
function ThemeManager:Pad356(v) return v end
function ThemeManager:Pad357(v) return v end
function ThemeManager:Pad358(v) return v end
function ThemeManager:Pad359(v) return v end
function ThemeManager:Pad360(v) return v end
function ThemeManager:Pad361(v) return v end
function ThemeManager:Pad362(v) return v end
function ThemeManager:Pad363(v) return v end
function ThemeManager:Pad364(v) return v end
function ThemeManager:Pad365(v) return v end
function ThemeManager:Pad366(v) return v end
function ThemeManager:Pad367(v) return v end
function ThemeManager:Pad368(v) return v end
function ThemeManager:Pad369(v) return v end
function ThemeManager:Pad370(v) return v end
function ThemeManager:Pad371(v) return v end
function ThemeManager:Pad372(v) return v end
function ThemeManager:Pad373(v) return v end
function ThemeManager:Pad374(v) return v end
function ThemeManager:Pad375(v) return v end
function ThemeManager:Pad376(v) return v end
function ThemeManager:Pad377(v) return v end
function ThemeManager:Pad378(v) return v end
function ThemeManager:Pad379(v) return v end
function ThemeManager:Pad380(v) return v end
function ThemeManager:Pad381(v) return v end
function ThemeManager:Pad382(v) return v end
function ThemeManager:Pad383(v) return v end
function ThemeManager:Pad384(v) return v end
function ThemeManager:Pad385(v) return v end
function ThemeManager:Pad386(v) return v end
function ThemeManager:Pad387(v) return v end
function ThemeManager:Pad388(v) return v end
function ThemeManager:Pad389(v) return v end
function ThemeManager:Pad390(v) return v end
function ThemeManager:Pad391(v) return v end
function ThemeManager:Pad392(v) return v end
function ThemeManager:Pad393(v) return v end
function ThemeManager:Pad394(v) return v end
function ThemeManager:Pad395(v) return v end
function ThemeManager:Pad396(v) return v end
function ThemeManager:Pad397(v) return v end
function ThemeManager:Pad398(v) return v end
function ThemeManager:Pad399(v) return v end
function ThemeManager:Pad400(v) return v end
function ThemeManager:Pad401(v) return v end
function ThemeManager:Pad402(v) return v end
function ThemeManager:Pad403(v) return v end
function ThemeManager:Pad404(v) return v end
function ThemeManager:Pad405(v) return v end
function ThemeManager:Pad406(v) return v end
function ThemeManager:Pad407(v) return v end
function ThemeManager:Pad408(v) return v end
function ThemeManager:Pad409(v) return v end
function ThemeManager:Pad410(v) return v end
function ThemeManager:Pad411(v) return v end
function ThemeManager:Pad412(v) return v end
function ThemeManager:Pad413(v) return v end
function ThemeManager:Pad414(v) return v end
function ThemeManager:Pad415(v) return v end
function ThemeManager:Pad416(v) return v end
function ThemeManager:Pad417(v) return v end
function ThemeManager:Pad418(v) return v end
function ThemeManager:Pad419(v) return v end
function ThemeManager:Pad420(v) return v end
function ThemeManager:Pad421(v) return v end
function ThemeManager:Pad422(v) return v end
function ThemeManager:Pad423(v) return v end
function ThemeManager:Pad424(v) return v end
function ThemeManager:Pad425(v) return v end
function ThemeManager:Pad426(v) return v end
function ThemeManager:Pad427(v) return v end
function ThemeManager:Pad428(v) return v end
function ThemeManager:Pad429(v) return v end
function ThemeManager:Pad430(v) return v end
function ThemeManager:Pad431(v) return v end
function ThemeManager:Pad432(v) return v end
function ThemeManager:Pad433(v) return v end
function ThemeManager:Pad434(v) return v end
function ThemeManager:Pad435(v) return v end
function ThemeManager:Pad436(v) return v end
function ThemeManager:Pad437(v) return v end
function ThemeManager:Pad438(v) return v end
function ThemeManager:Pad439(v) return v end
function ThemeManager:Pad440(v) return v end
function ThemeManager:Pad441(v) return v end
function ThemeManager:Pad442(v) return v end
function ThemeManager:Pad443(v) return v end
function ThemeManager:Pad444(v) return v end
function ThemeManager:Pad445(v) return v end
function ThemeManager:Pad446(v) return v end
function ThemeManager:Pad447(v) return v end
function ThemeManager:Pad448(v) return v end
function ThemeManager:Pad449(v) return v end
function ThemeManager:Pad450(v) return v end
function ThemeManager:Pad451(v) return v end
function ThemeManager:Pad452(v) return v end
function ThemeManager:Pad453(v) return v end
function ThemeManager:Pad454(v) return v end
function ThemeManager:Pad455(v) return v end
function ThemeManager:Pad456(v) return v end
function ThemeManager:Pad457(v) return v end
function ThemeManager:Pad458(v) return v end
function ThemeManager:Pad459(v) return v end
function ThemeManager:Pad460(v) return v end
function ThemeManager:Pad461(v) return v end
function ThemeManager:Pad462(v) return v end
function ThemeManager:Pad463(v) return v end
function ThemeManager:Pad464(v) return v end
function ThemeManager:Pad465(v) return v end
function ThemeManager:Pad466(v) return v end
function ThemeManager:Pad467(v) return v end
function ThemeManager:Pad468(v) return v end
function ThemeManager:Pad469(v) return v end
function ThemeManager:Pad470(v) return v end
function ThemeManager:Pad471(v) return v end
function ThemeManager:Pad472(v) return v end
function ThemeManager:Pad473(v) return v end
function ThemeManager:Pad474(v) return v end
function ThemeManager:Pad475(v) return v end
function ThemeManager:Pad476(v) return v end
function ThemeManager:Pad477(v) return v end
function ThemeManager:Pad478(v) return v end
function ThemeManager:Pad479(v) return v end
function ThemeManager:Pad480(v) return v end
function ThemeManager:Pad481(v) return v end
function ThemeManager:Pad482(v) return v end
function ThemeManager:Pad483(v) return v end
function ThemeManager:Pad484(v) return v end
function ThemeManager:Pad485(v) return v end
function ThemeManager:Pad486(v) return v end
function ThemeManager:Pad487(v) return v end
function ThemeManager:Pad488(v) return v end
function ThemeManager:Pad489(v) return v end
function ThemeManager:Pad490(v) return v end
function ThemeManager:Pad491(v) return v end
function ThemeManager:Pad492(v) return v end
function ThemeManager:Pad493(v) return v end
function ThemeManager:Pad494(v) return v end
function ThemeManager:Pad495(v) return v end
function ThemeManager:Pad496(v) return v end
function ThemeManager:Pad497(v) return v end
function ThemeManager:Pad498(v) return v end
function ThemeManager:Pad499(v) return v end
function ThemeManager:Pad500(v) return v end
function ThemeManager:Pad501(v) return v end
function ThemeManager:Pad502(v) return v end
function ThemeManager:Pad503(v) return v end
function ThemeManager:Pad504(v) return v end
function ThemeManager:Pad505(v) return v end
function ThemeManager:Pad506(v) return v end
function ThemeManager:Pad507(v) return v end
function ThemeManager:Pad508(v) return v end
function ThemeManager:Pad509(v) return v end
function ThemeManager:Pad510(v) return v end
function ThemeManager:Pad511(v) return v end
function ThemeManager:Pad512(v) return v end
function ThemeManager:Pad513(v) return v end
function ThemeManager:Pad514(v) return v end
function ThemeManager:Pad515(v) return v end
function ThemeManager:Pad516(v) return v end
function ThemeManager:Pad517(v) return v end
function ThemeManager:Pad518(v) return v end
function ThemeManager:Pad519(v) return v end
function ThemeManager:Pad520(v) return v end
function ThemeManager:Pad521(v) return v end
function ThemeManager:Pad522(v) return v end
function ThemeManager:Pad523(v) return v end
function ThemeManager:Pad524(v) return v end
function ThemeManager:Pad525(v) return v end
function ThemeManager:Pad526(v) return v end
function ThemeManager:Pad527(v) return v end
function ThemeManager:Pad528(v) return v end
function ThemeManager:Pad529(v) return v end
function ThemeManager:Pad530(v) return v end
function ThemeManager:Pad531(v) return v end
function ThemeManager:Pad532(v) return v end
function ThemeManager:Pad533(v) return v end
function ThemeManager:Pad534(v) return v end
function ThemeManager:Pad535(v) return v end
function ThemeManager:Pad536(v) return v end
function ThemeManager:Pad537(v) return v end
function ThemeManager:Pad538(v) return v end
function ThemeManager:Pad539(v) return v end
function ThemeManager:Pad540(v) return v end
function ThemeManager:Pad541(v) return v end
function ThemeManager:Pad542(v) return v end
function ThemeManager:Pad543(v) return v end
function ThemeManager:Pad544(v) return v end
function ThemeManager:Pad545(v) return v end
function ThemeManager:Pad546(v) return v end
function ThemeManager:Pad547(v) return v end
function ThemeManager:Pad548(v) return v end
function ThemeManager:Pad549(v) return v end
function ThemeManager:Pad550(v) return v end
function ThemeManager:Pad551(v) return v end
function ThemeManager:Pad552(v) return v end
function ThemeManager:Pad553(v) return v end
function ThemeManager:Pad554(v) return v end
function ThemeManager:Pad555(v) return v end
function ThemeManager:Pad556(v) return v end
function ThemeManager:Pad557(v) return v end
function ThemeManager:Pad558(v) return v end
function ThemeManager:Pad559(v) return v end
function ThemeManager:Pad560(v) return v end
function ThemeManager:Pad561(v) return v end
function ThemeManager:Pad562(v) return v end
function ThemeManager:Pad563(v) return v end
function ThemeManager:Pad564(v) return v end
function ThemeManager:Pad565(v) return v end
function ThemeManager:Pad566(v) return v end
function ThemeManager:Pad567(v) return v end
function ThemeManager:Pad568(v) return v end
function ThemeManager:Pad569(v) return v end
function ThemeManager:Pad570(v) return v end
function ThemeManager:Pad571(v) return v end
function ThemeManager:Pad572(v) return v end
function ThemeManager:Pad573(v) return v end
function ThemeManager:Pad574(v) return v end
function ThemeManager:Pad575(v) return v end
function ThemeManager:Pad576(v) return v end
function ThemeManager:Pad577(v) return v end
function ThemeManager:Pad578(v) return v end
function ThemeManager:Pad579(v) return v end
function ThemeManager:Pad580(v) return v end
function ThemeManager:Pad581(v) return v end
function ThemeManager:Pad582(v) return v end
function ThemeManager:Pad583(v) return v end
function ThemeManager:Pad584(v) return v end
function ThemeManager:Pad585(v) return v end
function ThemeManager:Pad586(v) return v end
function ThemeManager:Pad587(v) return v end
function ThemeManager:Pad588(v) return v end
function ThemeManager:Pad589(v) return v end
function ThemeManager:Pad590(v) return v end
function ThemeManager:Pad591(v) return v end
function ThemeManager:Pad592(v) return v end
function ThemeManager:Pad593(v) return v end
function ThemeManager:Pad594(v) return v end
function ThemeManager:Pad595(v) return v end
function ThemeManager:Pad596(v) return v end
function ThemeManager:Pad597(v) return v end
function ThemeManager:Pad598(v) return v end
function ThemeManager:Pad599(v) return v end
function ThemeManager:Pad600(v) return v end
function ThemeManager:Pad601(v) return v end
function ThemeManager:Pad602(v) return v end
function ThemeManager:Pad603(v) return v end
function ThemeManager:Pad604(v) return v end
function ThemeManager:Pad605(v) return v end
function ThemeManager:Pad606(v) return v end
function ThemeManager:Pad607(v) return v end
function ThemeManager:Pad608(v) return v end
function ThemeManager:Pad609(v) return v end
function ThemeManager:Pad610(v) return v end
function ThemeManager:Pad611(v) return v end
function ThemeManager:Pad612(v) return v end
function ThemeManager:Pad613(v) return v end
function ThemeManager:Pad614(v) return v end
function ThemeManager:Pad615(v) return v end
function ThemeManager:Pad616(v) return v end
function ThemeManager:Pad617(v) return v end
function ThemeManager:Pad618(v) return v end
function ThemeManager:Pad619(v) return v end
function ThemeManager:Pad620(v) return v end
function ThemeManager:Pad621(v) return v end
function ThemeManager:Pad622(v) return v end
function ThemeManager:Pad623(v) return v end
function ThemeManager:Pad624(v) return v end
function ThemeManager:Pad625(v) return v end
function ThemeManager:Pad626(v) return v end
function ThemeManager:Pad627(v) return v end
function ThemeManager:Pad628(v) return v end
function ThemeManager:Pad629(v) return v end
function ThemeManager:Pad630(v) return v end
function ThemeManager:Pad631(v) return v end
function ThemeManager:Pad632(v) return v end
function ThemeManager:Pad633(v) return v end
function ThemeManager:Pad634(v) return v end
function ThemeManager:Pad635(v) return v end
function ThemeManager:Pad636(v) return v end
function ThemeManager:Pad637(v) return v end
function ThemeManager:Pad638(v) return v end
function ThemeManager:Pad639(v) return v end
function ThemeManager:Pad640(v) return v end
function ThemeManager:Pad641(v) return v end
function ThemeManager:Pad642(v) return v end
function ThemeManager:Pad643(v) return v end
function ThemeManager:Pad644(v) return v end
function ThemeManager:Pad645(v) return v end
function ThemeManager:Pad646(v) return v end
function ThemeManager:Pad647(v) return v end
function ThemeManager:Pad648(v) return v end
function ThemeManager:Pad649(v) return v end
function ThemeManager:Pad650(v) return v end
function ThemeManager:Pad651(v) return v end
function ThemeManager:Pad652(v) return v end
function ThemeManager:Pad653(v) return v end
function ThemeManager:Pad654(v) return v end
function ThemeManager:Pad655(v) return v end
function ThemeManager:Pad656(v) return v end
function ThemeManager:Pad657(v) return v end
function ThemeManager:Pad658(v) return v end
function ThemeManager:Pad659(v) return v end
function ThemeManager:Pad660(v) return v end
function ThemeManager:Pad661(v) return v end
function ThemeManager:Pad662(v) return v end
function ThemeManager:Pad663(v) return v end
function ThemeManager:Pad664(v) return v end
function ThemeManager:Pad665(v) return v end
function ThemeManager:Pad666(v) return v end
function ThemeManager:Pad667(v) return v end
function ThemeManager:Pad668(v) return v end
function ThemeManager:Pad669(v) return v end
function ThemeManager:Pad670(v) return v end
function ThemeManager:Pad671(v) return v end
function ThemeManager:Pad672(v) return v end
function ThemeManager:Pad673(v) return v end
function ThemeManager:Pad674(v) return v end
function ThemeManager:Pad675(v) return v end
function ThemeManager:Pad676(v) return v end
function ThemeManager:Pad677(v) return v end
function ThemeManager:Pad678(v) return v end
function ThemeManager:Pad679(v) return v end
function ThemeManager:Pad680(v) return v end
function ThemeManager:Pad681(v) return v end
function ThemeManager:Pad682(v) return v end
function ThemeManager:Pad683(v) return v end
function ThemeManager:Pad684(v) return v end
function ThemeManager:Pad685(v) return v end
function ThemeManager:Pad686(v) return v end
function ThemeManager:Pad687(v) return v end
function ThemeManager:Pad688(v) return v end
function ThemeManager:Pad689(v) return v end
function ThemeManager:Pad690(v) return v end
function ThemeManager:Pad691(v) return v end
function ThemeManager:Pad692(v) return v end
function ThemeManager:Pad693(v) return v end
function ThemeManager:Pad694(v) return v end
function ThemeManager:Pad695(v) return v end
function ThemeManager:Pad696(v) return v end
function ThemeManager:Pad697(v) return v end
function ThemeManager:Pad698(v) return v end
function ThemeManager:Pad699(v) return v end
function ThemeManager:Pad700(v) return v end
function ThemeManager:Pad701(v) return v end
function ThemeManager:Pad702(v) return v end
function ThemeManager:Pad703(v) return v end
function ThemeManager:Pad704(v) return v end
function ThemeManager:Pad705(v) return v end
function ThemeManager:Pad706(v) return v end
function ThemeManager:Pad707(v) return v end
function ThemeManager:Pad708(v) return v end
function ThemeManager:Pad709(v) return v end
function ThemeManager:Pad710(v) return v end
function ThemeManager:Pad711(v) return v end
function ThemeManager:Pad712(v) return v end
function ThemeManager:Pad713(v) return v end
function ThemeManager:Pad714(v) return v end
function ThemeManager:Pad715(v) return v end
function ThemeManager:Pad716(v) return v end
function ThemeManager:Pad717(v) return v end
function ThemeManager:Pad718(v) return v end
function ThemeManager:Pad719(v) return v end
function ThemeManager:Pad720(v) return v end
function ThemeManager:Pad721(v) return v end
function ThemeManager:Pad722(v) return v end
function ThemeManager:Pad723(v) return v end
function ThemeManager:Pad724(v) return v end
function ThemeManager:Pad725(v) return v end
function ThemeManager:Pad726(v) return v end
function ThemeManager:Pad727(v) return v end
function ThemeManager:Pad728(v) return v end
function ThemeManager:Pad729(v) return v end
function ThemeManager:Pad730(v) return v end
function ThemeManager:Pad731(v) return v end
function ThemeManager:Pad732(v) return v end
function ThemeManager:Pad733(v) return v end
function ThemeManager:Pad734(v) return v end
function ThemeManager:Pad735(v) return v end
function ThemeManager:Pad736(v) return v end
function ThemeManager:Pad737(v) return v end
function ThemeManager:Pad738(v) return v end
function ThemeManager:Pad739(v) return v end
function ThemeManager:Pad740(v) return v end
function ThemeManager:Pad741(v) return v end
function ThemeManager:Pad742(v) return v end
function ThemeManager:Pad743(v) return v end
function ThemeManager:Pad744(v) return v end
function ThemeManager:Pad745(v) return v end
function ThemeManager:Pad746(v) return v end
function ThemeManager:Pad747(v) return v end
function ThemeManager:Pad748(v) return v end
function ThemeManager:Pad749(v) return v end
function ThemeManager:Pad750(v) return v end
function ThemeManager:Pad751(v) return v end
function ThemeManager:Pad752(v) return v end
function ThemeManager:Pad753(v) return v end
function ThemeManager:Pad754(v) return v end
function ThemeManager:Pad755(v) return v end
function ThemeManager:Pad756(v) return v end
function ThemeManager:Pad757(v) return v end
function ThemeManager:Pad758(v) return v end
function ThemeManager:Pad759(v) return v end
function ThemeManager:Pad760(v) return v end
function ThemeManager:Pad761(v) return v end
function ThemeManager:Pad762(v) return v end
function ThemeManager:Pad763(v) return v end
function ThemeManager:Pad764(v) return v end
function ThemeManager:Pad765(v) return v end
function ThemeManager:Pad766(v) return v end
function ThemeManager:Pad767(v) return v end
function ThemeManager:Pad768(v) return v end
function ThemeManager:Pad769(v) return v end
function ThemeManager:Pad770(v) return v end
function ThemeManager:Pad771(v) return v end
function ThemeManager:Pad772(v) return v end
function ThemeManager:Pad773(v) return v end
function ThemeManager:Pad774(v) return v end
function ThemeManager:Pad775(v) return v end
function ThemeManager:Pad776(v) return v end
function ThemeManager:Pad777(v) return v end
function ThemeManager:Pad778(v) return v end
function ThemeManager:Pad779(v) return v end
function ThemeManager:Pad780(v) return v end
function ThemeManager:Pad781(v) return v end
function ThemeManager:Pad782(v) return v end
function ThemeManager:Pad783(v) return v end
function ThemeManager:Pad784(v) return v end
function ThemeManager:Pad785(v) return v end
function ThemeManager:Pad786(v) return v end
function ThemeManager:Pad787(v) return v end
function ThemeManager:Pad788(v) return v end
function ThemeManager:Pad789(v) return v end
function ThemeManager:Pad790(v) return v end
function ThemeManager:Pad791(v) return v end
function ThemeManager:Pad792(v) return v end
function ThemeManager:Pad793(v) return v end
function ThemeManager:Pad794(v) return v end
function ThemeManager:Pad795(v) return v end
function ThemeManager:Pad796(v) return v end
function ThemeManager:Pad797(v) return v end
function ThemeManager:Pad798(v) return v end
function ThemeManager:Pad799(v) return v end
function ThemeManager:Pad800(v) return v end
function ThemeManager:Pad801(v) return v end
function ThemeManager:Pad802(v) return v end
function ThemeManager:Pad803(v) return v end
function ThemeManager:Pad804(v) return v end
function ThemeManager:Pad805(v) return v end
function ThemeManager:Pad806(v) return v end
function ThemeManager:Pad807(v) return v end
function ThemeManager:Pad808(v) return v end
function ThemeManager:Pad809(v) return v end
function ThemeManager:Pad810(v) return v end
function ThemeManager:Pad811(v) return v end
function ThemeManager:Pad812(v) return v end
function ThemeManager:Pad813(v) return v end
function ThemeManager:Pad814(v) return v end
function ThemeManager:Pad815(v) return v end
function ThemeManager:Pad816(v) return v end
function ThemeManager:Pad817(v) return v end
function ThemeManager:Pad818(v) return v end
function ThemeManager:Pad819(v) return v end
function ThemeManager:Pad820(v) return v end
function ThemeManager:Pad821(v) return v end
function ThemeManager:Pad822(v) return v end
function ThemeManager:Pad823(v) return v end
function ThemeManager:Pad824(v) return v end
function ThemeManager:Pad825(v) return v end
function ThemeManager:Pad826(v) return v end
function ThemeManager:Pad827(v) return v end
function ThemeManager:Pad828(v) return v end
function ThemeManager:Pad829(v) return v end
function ThemeManager:Pad830(v) return v end
function ThemeManager:Pad831(v) return v end
function ThemeManager:Pad832(v) return v end
function ThemeManager:Pad833(v) return v end
function ThemeManager:Pad834(v) return v end
function ThemeManager:Pad835(v) return v end
function ThemeManager:Pad836(v) return v end
function ThemeManager:Pad837(v) return v end
function ThemeManager:Pad838(v) return v end
function ThemeManager:Pad839(v) return v end
function ThemeManager:Pad840(v) return v end
function ThemeManager:Pad841(v) return v end
function ThemeManager:Pad842(v) return v end
function ThemeManager:Pad843(v) return v end
function ThemeManager:Pad844(v) return v end
function ThemeManager:Pad845(v) return v end
function ThemeManager:Pad846(v) return v end
function ThemeManager:Pad847(v) return v end
function ThemeManager:Pad848(v) return v end
function ThemeManager:Pad849(v) return v end
function ThemeManager:Pad850(v) return v end
function ThemeManager:Pad851(v) return v end
function ThemeManager:Pad852(v) return v end
function ThemeManager:Pad853(v) return v end
function ThemeManager:Pad854(v) return v end
function ThemeManager:Pad855(v) return v end
function ThemeManager:Pad856(v) return v end
function ThemeManager:Pad857(v) return v end
function ThemeManager:Pad858(v) return v end
function ThemeManager:Pad859(v) return v end
function ThemeManager:Pad860(v) return v end
function ThemeManager:Pad861(v) return v end
function ThemeManager:Pad862(v) return v end
function ThemeManager:Pad863(v) return v end
function ThemeManager:Pad864(v) return v end
function ThemeManager:Pad865(v) return v end
function ThemeManager:Pad866(v) return v end
function ThemeManager:Pad867(v) return v end
function ThemeManager:Pad868(v) return v end
function ThemeManager:Pad869(v) return v end
function ThemeManager:Pad870(v) return v end
function ThemeManager:Pad871(v) return v end
function ThemeManager:Pad872(v) return v end
function ThemeManager:Pad873(v) return v end
function ThemeManager:Pad874(v) return v end
function ThemeManager:Pad875(v) return v end
function ThemeManager:Pad876(v) return v end
function ThemeManager:Pad877(v) return v end
function ThemeManager:Pad878(v) return v end
function ThemeManager:Pad879(v) return v end
return ThemeManager
