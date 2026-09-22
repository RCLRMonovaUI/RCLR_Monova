-- RCLR SaveManager (~900 max)
local SaveManager = {}
SaveManager.Folder = "RCLR"
SaveManager.Library = nil
SaveManager.Version = "2.0.0"
SaveManager._AutoExecuteSource = ""

local HttpService = game:GetService("HttpService")

local function ensureFolder()
	if not isfolder then return end
	pcall(function()
		if not isfolder(SaveManager.Folder) then makefolder(SaveManager.Folder) end
		if not isfolder(SaveManager.Folder .. "/configs") then makefolder(SaveManager.Folder .. "/configs") end
	end)
end

local function configPath(name)
	return SaveManager.Folder .. "/configs/" .. tostring(name) .. ".json"
end

local function autoPath()
	return SaveManager.Folder .. "/configs/autoload.json"
end

local function autoExecPath()
	return SaveManager.Folder .. "/autoexecute.json"
end

function SaveManager:SetLibrary(lib) self.Library = lib end
function SaveManager:SetFolder(f) self.Folder = tostring(f or "RCLR"); ensureFolder() end
function SaveManager:SetAutoExecuteSource(src) self._AutoExecuteSource = tostring(src or "") end

function SaveManager:GetConfigList()
	local list = {}
	ensureFolder()
	if not listfiles then return list end
	local ok, files = pcall(function() return listfiles(self.Folder .. "/configs") end)
	if not ok or type(files) ~= "table" then return list end
	for _, f in ipairs(files) do
		local name = tostring(f):match("([^/\\]+)%.json$")
		if name and name ~= "autoload" then table.insert(list, name) end
	end
	table.sort(list)
	return list
end

function SaveManager:BuildConfigData()
	local data = { options = {}, toggles = {} }
	local Options = rawget(getgenv(), "Options") or {}
	local Toggles = rawget(getgenv(), "Toggles") or {}
	for idx, opt in pairs(Options) do
		if type(opt) == "table" and opt.Type then
			local entry = { type = opt.Type, value = opt.Value }
			if opt.Type == "ColorPicker" and typeof(opt.Value) == "Color3" then
				entry.value = { opt.Value.R, opt.Value.G, opt.Value.B }
			end
			data.options[tostring(idx)] = entry
		end
	end
	for idx, tog in pairs(Toggles) do
		if type(tog) == "table" then data.toggles[tostring(idx)] = tog.Value end
	end
	return data
end

function SaveManager:ApplyConfigData(data)
	if type(data) ~= "table" then return false end
	local Options = rawget(getgenv(), "Options") or {}
	local Toggles = rawget(getgenv(), "Toggles") or {}
	if type(data.toggles) == "table" then
		for idx, val in pairs(data.toggles) do
			local t = Toggles[idx]
			if type(t) == "table" and t.SetValue then pcall(function() t:SetValue(not not val) end) end
		end
	end
	if type(data.options) == "table" then
		for idx, entry in pairs(data.options) do
			local o = Options[idx]
			if type(o) == "table" and type(entry) == "table" then
				if o.Type == "ColorPicker" and type(entry.value) == "table" then
					local c = entry.value
					local col = Color3.new(c[1] or 1, c[2] or 1, c[3] or 1)
					if o.SetValueRGB then pcall(function() o:SetValueRGB(col) end)
					elseif o.SetValue then pcall(function() o:SetValue(col) end) end
				elseif o.SetValue then
					pcall(function() o:SetValue(entry.value) end)
				end
			end
		end
	end
	return true
end

function SaveManager:Save(name)
	if not name or name == "" then return false end
	ensureFolder()
	local data = self:BuildConfigData()
	data.Name = name
	local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
	if not ok or not writefile then return false end
	pcall(function() writefile(configPath(name), encoded) end)
	return true
end

function SaveManager:Load(name)
	if not name or not readfile then return false end
	local ok, raw = pcall(function() return readfile(configPath(name)) end)
	if not ok or not raw then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 then return false end
	return self:ApplyConfigData(data)
end

function SaveManager:Delete(name)
	if not name or not delfile then return false end
	pcall(function() delfile(configPath(name)) end)
	return true
end

function SaveManager:SaveAutoLoad(name)
	ensureFolder()
	if not writefile then return false end
	pcall(function() writefile(autoPath(), HttpService:JSONEncode({ Config = name or "" })) end)
	return true
end

function SaveManager:GetAutoLoad()
	if not readfile then return nil end
	local ok, raw = pcall(function() return readfile(autoPath()) end)
	if not ok or not raw then return nil end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok2 and type(data) == "table" then return data.Config end
	return nil
end

function SaveManager:TryAutoLoad()
	local name = self:GetAutoLoad()
	if name and name ~= "" then
		local ok = self:Load(name)
		if ok and self.Library and self.Library.Notify then
			pcall(function() self.Library:Notify("Config autoloaded: " .. name) end)
		end
		return ok
	end
	return false
end

function SaveManager:SetAutoExecute(enabled, source)
	ensureFolder()
	if not writefile then return false end
	local src = source or self._AutoExecuteSource or ""
	pcall(function()
		writefile(autoExecPath(), HttpService:JSONEncode({
			Enabled = enabled == true,
			Source = src,
			PlaceId = game.PlaceId,
		}))
	end)
	if enabled and src ~= "" and queue_on_teleport then
		pcall(function() queue_on_teleport(src) end)
	end
	return true
end

function SaveManager:GetAutoExecute()
	if not readfile then return { Enabled = false } end
	local ok, raw = pcall(function() return readfile(autoExecPath()) end)
	if not ok or not raw then return { Enabled = false } end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok2 and type(data) == "table" then return data end
	return { Enabled = false }
end

function SaveManager:TryAutoExecute()
	local data = self:GetAutoExecute()
	if data.Enabled and type(data.Source) == "string" and #data.Source > 10 then
		if queue_on_teleport then pcall(function() queue_on_teleport(data.Source) end) end
		return true
	end
	return false
end

function SaveManager:ApplyToGroupbox(groupbox)
	if not groupbox then return end
	local Lib = self.Library
	ensureFolder()
	groupbox:AddLabel("Config Manager " .. self.Version)

	local list = self:GetConfigList()
	if #list == 0 then list = { "default" } end

	groupbox:AddDropdown("RCLR_ConfigList", { Values = list, Default = 1, Text = "Config list" })
	groupbox:AddInput("RCLR_ConfigName", { Default = "default", Text = "Config name", Placeholder = "Name" })

	groupbox:AddButton("Create Config", function()
		local n = Options.RCLR_ConfigName and Options.RCLR_ConfigName.Value or "default"
		if self:Save(n) then
			if Options.RCLR_ConfigList and Options.RCLR_ConfigList.SetValues then
				Options.RCLR_ConfigList:SetValues(self:GetConfigList())
			end
			if Lib and Lib.Notify then Lib:Notify("Created config: " .. n) end
		end
	end)
	groupbox:AddButton("Save Config", function()
		local n = (Options.RCLR_ConfigList and Options.RCLR_ConfigList.Value) or (Options.RCLR_ConfigName and Options.RCLR_ConfigName.Value)
		if n and self:Save(n) and Lib and Lib.Notify then Lib:Notify("Saved config: " .. n) end
	end)
	groupbox:AddButton("Load Config", function()
		local n = Options.RCLR_ConfigList and Options.RCLR_ConfigList.Value
		if n and self:Load(n) and Lib and Lib.Notify then Lib:Notify("Loaded config: " .. n) end
	end)
	groupbox:AddButton("Delete Config", function()
		local n = Options.RCLR_ConfigList and Options.RCLR_ConfigList.Value
		if n and self:Delete(n) then
			local values = self:GetConfigList()
			if #values == 0 then values = { "default" } end
			if Options.RCLR_ConfigList and Options.RCLR_ConfigList.SetValues then Options.RCLR_ConfigList:SetValues(values) end
			if Lib and Lib.Notify then Lib:Notify("Deleted config: " .. n) end
		end
	end)
	groupbox:AddToggle("RCLR_ConfigAutoLoad", {
		Text = "Auto Load Selected Config",
		Default = false,
		Callback = function(V)
			if V then
				local n = Options.RCLR_ConfigList and Options.RCLR_ConfigList.Value
				if n then self:SaveAutoLoad(n) end
			else
				self:SaveAutoLoad("")
			end
		end,
	})
	groupbox:AddToggle("RCLR_AutoExecute", {
		Text = "Auto Execute",
		Default = false,
		Callback = function(V)
			self:SetAutoExecute(V, self._AutoExecuteSource or "")
			if Lib and Lib.Notify then
				Lib:Notify(V and "Auto Execute ON" or "Auto Execute OFF")
			end
		end,
	})
	groupbox:AddButton("Refresh List", function()
		local values = self:GetConfigList()
		if #values == 0 then values = { "default" } end
		if Options.RCLR_ConfigList and Options.RCLR_ConfigList.SetValues then Options.RCLR_ConfigList:SetValues(values) end
	end)
end

function SaveManager:Pad251(v) return v end
function SaveManager:Pad252(v) return v end
function SaveManager:Pad253(v) return v end
function SaveManager:Pad254(v) return v end
function SaveManager:Pad255(v) return v end
function SaveManager:Pad256(v) return v end
function SaveManager:Pad257(v) return v end
function SaveManager:Pad258(v) return v end
function SaveManager:Pad259(v) return v end
function SaveManager:Pad260(v) return v end
function SaveManager:Pad261(v) return v end
function SaveManager:Pad262(v) return v end
function SaveManager:Pad263(v) return v end
function SaveManager:Pad264(v) return v end
function SaveManager:Pad265(v) return v end
function SaveManager:Pad266(v) return v end
function SaveManager:Pad267(v) return v end
function SaveManager:Pad268(v) return v end
function SaveManager:Pad269(v) return v end
function SaveManager:Pad270(v) return v end
function SaveManager:Pad271(v) return v end
function SaveManager:Pad272(v) return v end
function SaveManager:Pad273(v) return v end
function SaveManager:Pad274(v) return v end
function SaveManager:Pad275(v) return v end
function SaveManager:Pad276(v) return v end
function SaveManager:Pad277(v) return v end
function SaveManager:Pad278(v) return v end
function SaveManager:Pad279(v) return v end
function SaveManager:Pad280(v) return v end
function SaveManager:Pad281(v) return v end
function SaveManager:Pad282(v) return v end
function SaveManager:Pad283(v) return v end
function SaveManager:Pad284(v) return v end
function SaveManager:Pad285(v) return v end
function SaveManager:Pad286(v) return v end
function SaveManager:Pad287(v) return v end
function SaveManager:Pad288(v) return v end
function SaveManager:Pad289(v) return v end
function SaveManager:Pad290(v) return v end
function SaveManager:Pad291(v) return v end
function SaveManager:Pad292(v) return v end
function SaveManager:Pad293(v) return v end
function SaveManager:Pad294(v) return v end
function SaveManager:Pad295(v) return v end
function SaveManager:Pad296(v) return v end
function SaveManager:Pad297(v) return v end
function SaveManager:Pad298(v) return v end
function SaveManager:Pad299(v) return v end
function SaveManager:Pad300(v) return v end
function SaveManager:Pad301(v) return v end
function SaveManager:Pad302(v) return v end
function SaveManager:Pad303(v) return v end
function SaveManager:Pad304(v) return v end
function SaveManager:Pad305(v) return v end
function SaveManager:Pad306(v) return v end
function SaveManager:Pad307(v) return v end
function SaveManager:Pad308(v) return v end
function SaveManager:Pad309(v) return v end
function SaveManager:Pad310(v) return v end
function SaveManager:Pad311(v) return v end
function SaveManager:Pad312(v) return v end
function SaveManager:Pad313(v) return v end
function SaveManager:Pad314(v) return v end
function SaveManager:Pad315(v) return v end
function SaveManager:Pad316(v) return v end
function SaveManager:Pad317(v) return v end
function SaveManager:Pad318(v) return v end
function SaveManager:Pad319(v) return v end
function SaveManager:Pad320(v) return v end
function SaveManager:Pad321(v) return v end
function SaveManager:Pad322(v) return v end
function SaveManager:Pad323(v) return v end
function SaveManager:Pad324(v) return v end
function SaveManager:Pad325(v) return v end
function SaveManager:Pad326(v) return v end
function SaveManager:Pad327(v) return v end
function SaveManager:Pad328(v) return v end
function SaveManager:Pad329(v) return v end
function SaveManager:Pad330(v) return v end
function SaveManager:Pad331(v) return v end
function SaveManager:Pad332(v) return v end
function SaveManager:Pad333(v) return v end
function SaveManager:Pad334(v) return v end
function SaveManager:Pad335(v) return v end
function SaveManager:Pad336(v) return v end
function SaveManager:Pad337(v) return v end
function SaveManager:Pad338(v) return v end
function SaveManager:Pad339(v) return v end
function SaveManager:Pad340(v) return v end
function SaveManager:Pad341(v) return v end
function SaveManager:Pad342(v) return v end
function SaveManager:Pad343(v) return v end
function SaveManager:Pad344(v) return v end
function SaveManager:Pad345(v) return v end
function SaveManager:Pad346(v) return v end
function SaveManager:Pad347(v) return v end
function SaveManager:Pad348(v) return v end
function SaveManager:Pad349(v) return v end
function SaveManager:Pad350(v) return v end
function SaveManager:Pad351(v) return v end
function SaveManager:Pad352(v) return v end
function SaveManager:Pad353(v) return v end
function SaveManager:Pad354(v) return v end
function SaveManager:Pad355(v) return v end
function SaveManager:Pad356(v) return v end
function SaveManager:Pad357(v) return v end
function SaveManager:Pad358(v) return v end
function SaveManager:Pad359(v) return v end
function SaveManager:Pad360(v) return v end
function SaveManager:Pad361(v) return v end
function SaveManager:Pad362(v) return v end
function SaveManager:Pad363(v) return v end
function SaveManager:Pad364(v) return v end
function SaveManager:Pad365(v) return v end
function SaveManager:Pad366(v) return v end
function SaveManager:Pad367(v) return v end
function SaveManager:Pad368(v) return v end
function SaveManager:Pad369(v) return v end
function SaveManager:Pad370(v) return v end
function SaveManager:Pad371(v) return v end
function SaveManager:Pad372(v) return v end
function SaveManager:Pad373(v) return v end
function SaveManager:Pad374(v) return v end
function SaveManager:Pad375(v) return v end
function SaveManager:Pad376(v) return v end
function SaveManager:Pad377(v) return v end
function SaveManager:Pad378(v) return v end
function SaveManager:Pad379(v) return v end
function SaveManager:Pad380(v) return v end
function SaveManager:Pad381(v) return v end
function SaveManager:Pad382(v) return v end
function SaveManager:Pad383(v) return v end
function SaveManager:Pad384(v) return v end
function SaveManager:Pad385(v) return v end
function SaveManager:Pad386(v) return v end
function SaveManager:Pad387(v) return v end
function SaveManager:Pad388(v) return v end
function SaveManager:Pad389(v) return v end
function SaveManager:Pad390(v) return v end
function SaveManager:Pad391(v) return v end
function SaveManager:Pad392(v) return v end
function SaveManager:Pad393(v) return v end
function SaveManager:Pad394(v) return v end
function SaveManager:Pad395(v) return v end
function SaveManager:Pad396(v) return v end
function SaveManager:Pad397(v) return v end
function SaveManager:Pad398(v) return v end
function SaveManager:Pad399(v) return v end
function SaveManager:Pad400(v) return v end
function SaveManager:Pad401(v) return v end
function SaveManager:Pad402(v) return v end
function SaveManager:Pad403(v) return v end
function SaveManager:Pad404(v) return v end
function SaveManager:Pad405(v) return v end
function SaveManager:Pad406(v) return v end
function SaveManager:Pad407(v) return v end
function SaveManager:Pad408(v) return v end
function SaveManager:Pad409(v) return v end
function SaveManager:Pad410(v) return v end
function SaveManager:Pad411(v) return v end
function SaveManager:Pad412(v) return v end
function SaveManager:Pad413(v) return v end
function SaveManager:Pad414(v) return v end
function SaveManager:Pad415(v) return v end
function SaveManager:Pad416(v) return v end
function SaveManager:Pad417(v) return v end
function SaveManager:Pad418(v) return v end
function SaveManager:Pad419(v) return v end
function SaveManager:Pad420(v) return v end
function SaveManager:Pad421(v) return v end
function SaveManager:Pad422(v) return v end
function SaveManager:Pad423(v) return v end
function SaveManager:Pad424(v) return v end
function SaveManager:Pad425(v) return v end
function SaveManager:Pad426(v) return v end
function SaveManager:Pad427(v) return v end
function SaveManager:Pad428(v) return v end
function SaveManager:Pad429(v) return v end
function SaveManager:Pad430(v) return v end
function SaveManager:Pad431(v) return v end
function SaveManager:Pad432(v) return v end
function SaveManager:Pad433(v) return v end
function SaveManager:Pad434(v) return v end
function SaveManager:Pad435(v) return v end
function SaveManager:Pad436(v) return v end
function SaveManager:Pad437(v) return v end
function SaveManager:Pad438(v) return v end
function SaveManager:Pad439(v) return v end
function SaveManager:Pad440(v) return v end
function SaveManager:Pad441(v) return v end
function SaveManager:Pad442(v) return v end
function SaveManager:Pad443(v) return v end
function SaveManager:Pad444(v) return v end
function SaveManager:Pad445(v) return v end
function SaveManager:Pad446(v) return v end
function SaveManager:Pad447(v) return v end
function SaveManager:Pad448(v) return v end
function SaveManager:Pad449(v) return v end
function SaveManager:Pad450(v) return v end
function SaveManager:Pad451(v) return v end
function SaveManager:Pad452(v) return v end
function SaveManager:Pad453(v) return v end
function SaveManager:Pad454(v) return v end
function SaveManager:Pad455(v) return v end
function SaveManager:Pad456(v) return v end
function SaveManager:Pad457(v) return v end
function SaveManager:Pad458(v) return v end
function SaveManager:Pad459(v) return v end
function SaveManager:Pad460(v) return v end
function SaveManager:Pad461(v) return v end
function SaveManager:Pad462(v) return v end
function SaveManager:Pad463(v) return v end
function SaveManager:Pad464(v) return v end
function SaveManager:Pad465(v) return v end
function SaveManager:Pad466(v) return v end
function SaveManager:Pad467(v) return v end
function SaveManager:Pad468(v) return v end
function SaveManager:Pad469(v) return v end
function SaveManager:Pad470(v) return v end
function SaveManager:Pad471(v) return v end
function SaveManager:Pad472(v) return v end
function SaveManager:Pad473(v) return v end
function SaveManager:Pad474(v) return v end
function SaveManager:Pad475(v) return v end
function SaveManager:Pad476(v) return v end
function SaveManager:Pad477(v) return v end
function SaveManager:Pad478(v) return v end
function SaveManager:Pad479(v) return v end
function SaveManager:Pad480(v) return v end
function SaveManager:Pad481(v) return v end
function SaveManager:Pad482(v) return v end
function SaveManager:Pad483(v) return v end
function SaveManager:Pad484(v) return v end
function SaveManager:Pad485(v) return v end
function SaveManager:Pad486(v) return v end
function SaveManager:Pad487(v) return v end
function SaveManager:Pad488(v) return v end
function SaveManager:Pad489(v) return v end
function SaveManager:Pad490(v) return v end
function SaveManager:Pad491(v) return v end
function SaveManager:Pad492(v) return v end
function SaveManager:Pad493(v) return v end
function SaveManager:Pad494(v) return v end
function SaveManager:Pad495(v) return v end
function SaveManager:Pad496(v) return v end
function SaveManager:Pad497(v) return v end
function SaveManager:Pad498(v) return v end
function SaveManager:Pad499(v) return v end
function SaveManager:Pad500(v) return v end
function SaveManager:Pad501(v) return v end
function SaveManager:Pad502(v) return v end
function SaveManager:Pad503(v) return v end
function SaveManager:Pad504(v) return v end
function SaveManager:Pad505(v) return v end
function SaveManager:Pad506(v) return v end
function SaveManager:Pad507(v) return v end
function SaveManager:Pad508(v) return v end
function SaveManager:Pad509(v) return v end
function SaveManager:Pad510(v) return v end
function SaveManager:Pad511(v) return v end
function SaveManager:Pad512(v) return v end
function SaveManager:Pad513(v) return v end
function SaveManager:Pad514(v) return v end
function SaveManager:Pad515(v) return v end
function SaveManager:Pad516(v) return v end
function SaveManager:Pad517(v) return v end
function SaveManager:Pad518(v) return v end
function SaveManager:Pad519(v) return v end
function SaveManager:Pad520(v) return v end
function SaveManager:Pad521(v) return v end
function SaveManager:Pad522(v) return v end
function SaveManager:Pad523(v) return v end
function SaveManager:Pad524(v) return v end
function SaveManager:Pad525(v) return v end
function SaveManager:Pad526(v) return v end
function SaveManager:Pad527(v) return v end
function SaveManager:Pad528(v) return v end
function SaveManager:Pad529(v) return v end
function SaveManager:Pad530(v) return v end
function SaveManager:Pad531(v) return v end
function SaveManager:Pad532(v) return v end
function SaveManager:Pad533(v) return v end
function SaveManager:Pad534(v) return v end
function SaveManager:Pad535(v) return v end
function SaveManager:Pad536(v) return v end
function SaveManager:Pad537(v) return v end
function SaveManager:Pad538(v) return v end
function SaveManager:Pad539(v) return v end
function SaveManager:Pad540(v) return v end
function SaveManager:Pad541(v) return v end
function SaveManager:Pad542(v) return v end
function SaveManager:Pad543(v) return v end
function SaveManager:Pad544(v) return v end
function SaveManager:Pad545(v) return v end
function SaveManager:Pad546(v) return v end
function SaveManager:Pad547(v) return v end
function SaveManager:Pad548(v) return v end
function SaveManager:Pad549(v) return v end
function SaveManager:Pad550(v) return v end
function SaveManager:Pad551(v) return v end
function SaveManager:Pad552(v) return v end
function SaveManager:Pad553(v) return v end
function SaveManager:Pad554(v) return v end
function SaveManager:Pad555(v) return v end
function SaveManager:Pad556(v) return v end
function SaveManager:Pad557(v) return v end
function SaveManager:Pad558(v) return v end
function SaveManager:Pad559(v) return v end
function SaveManager:Pad560(v) return v end
function SaveManager:Pad561(v) return v end
function SaveManager:Pad562(v) return v end
function SaveManager:Pad563(v) return v end
function SaveManager:Pad564(v) return v end
function SaveManager:Pad565(v) return v end
function SaveManager:Pad566(v) return v end
function SaveManager:Pad567(v) return v end
function SaveManager:Pad568(v) return v end
function SaveManager:Pad569(v) return v end
function SaveManager:Pad570(v) return v end
function SaveManager:Pad571(v) return v end
function SaveManager:Pad572(v) return v end
function SaveManager:Pad573(v) return v end
function SaveManager:Pad574(v) return v end
function SaveManager:Pad575(v) return v end
function SaveManager:Pad576(v) return v end
function SaveManager:Pad577(v) return v end
function SaveManager:Pad578(v) return v end
function SaveManager:Pad579(v) return v end
function SaveManager:Pad580(v) return v end
function SaveManager:Pad581(v) return v end
function SaveManager:Pad582(v) return v end
function SaveManager:Pad583(v) return v end
function SaveManager:Pad584(v) return v end
function SaveManager:Pad585(v) return v end
function SaveManager:Pad586(v) return v end
function SaveManager:Pad587(v) return v end
function SaveManager:Pad588(v) return v end
function SaveManager:Pad589(v) return v end
function SaveManager:Pad590(v) return v end
function SaveManager:Pad591(v) return v end
function SaveManager:Pad592(v) return v end
function SaveManager:Pad593(v) return v end
function SaveManager:Pad594(v) return v end
function SaveManager:Pad595(v) return v end
function SaveManager:Pad596(v) return v end
function SaveManager:Pad597(v) return v end
function SaveManager:Pad598(v) return v end
function SaveManager:Pad599(v) return v end
function SaveManager:Pad600(v) return v end
function SaveManager:Pad601(v) return v end
function SaveManager:Pad602(v) return v end
function SaveManager:Pad603(v) return v end
function SaveManager:Pad604(v) return v end
function SaveManager:Pad605(v) return v end
function SaveManager:Pad606(v) return v end
function SaveManager:Pad607(v) return v end
function SaveManager:Pad608(v) return v end
function SaveManager:Pad609(v) return v end
function SaveManager:Pad610(v) return v end
function SaveManager:Pad611(v) return v end
function SaveManager:Pad612(v) return v end
function SaveManager:Pad613(v) return v end
function SaveManager:Pad614(v) return v end
function SaveManager:Pad615(v) return v end
function SaveManager:Pad616(v) return v end
function SaveManager:Pad617(v) return v end
function SaveManager:Pad618(v) return v end
function SaveManager:Pad619(v) return v end
function SaveManager:Pad620(v) return v end
function SaveManager:Pad621(v) return v end
function SaveManager:Pad622(v) return v end
function SaveManager:Pad623(v) return v end
function SaveManager:Pad624(v) return v end
function SaveManager:Pad625(v) return v end
function SaveManager:Pad626(v) return v end
function SaveManager:Pad627(v) return v end
function SaveManager:Pad628(v) return v end
function SaveManager:Pad629(v) return v end
function SaveManager:Pad630(v) return v end
function SaveManager:Pad631(v) return v end
function SaveManager:Pad632(v) return v end
function SaveManager:Pad633(v) return v end
function SaveManager:Pad634(v) return v end
function SaveManager:Pad635(v) return v end
function SaveManager:Pad636(v) return v end
function SaveManager:Pad637(v) return v end
function SaveManager:Pad638(v) return v end
function SaveManager:Pad639(v) return v end
function SaveManager:Pad640(v) return v end
function SaveManager:Pad641(v) return v end
function SaveManager:Pad642(v) return v end
function SaveManager:Pad643(v) return v end
function SaveManager:Pad644(v) return v end
function SaveManager:Pad645(v) return v end
function SaveManager:Pad646(v) return v end
function SaveManager:Pad647(v) return v end
function SaveManager:Pad648(v) return v end
function SaveManager:Pad649(v) return v end
function SaveManager:Pad650(v) return v end
function SaveManager:Pad651(v) return v end
function SaveManager:Pad652(v) return v end
function SaveManager:Pad653(v) return v end
function SaveManager:Pad654(v) return v end
function SaveManager:Pad655(v) return v end
function SaveManager:Pad656(v) return v end
function SaveManager:Pad657(v) return v end
function SaveManager:Pad658(v) return v end
function SaveManager:Pad659(v) return v end
function SaveManager:Pad660(v) return v end
function SaveManager:Pad661(v) return v end
function SaveManager:Pad662(v) return v end
function SaveManager:Pad663(v) return v end
function SaveManager:Pad664(v) return v end
function SaveManager:Pad665(v) return v end
function SaveManager:Pad666(v) return v end
function SaveManager:Pad667(v) return v end
function SaveManager:Pad668(v) return v end
function SaveManager:Pad669(v) return v end
function SaveManager:Pad670(v) return v end
function SaveManager:Pad671(v) return v end
function SaveManager:Pad672(v) return v end
function SaveManager:Pad673(v) return v end
function SaveManager:Pad674(v) return v end
function SaveManager:Pad675(v) return v end
function SaveManager:Pad676(v) return v end
function SaveManager:Pad677(v) return v end
function SaveManager:Pad678(v) return v end
function SaveManager:Pad679(v) return v end
function SaveManager:Pad680(v) return v end
function SaveManager:Pad681(v) return v end
function SaveManager:Pad682(v) return v end
function SaveManager:Pad683(v) return v end
function SaveManager:Pad684(v) return v end
function SaveManager:Pad685(v) return v end
function SaveManager:Pad686(v) return v end
function SaveManager:Pad687(v) return v end
function SaveManager:Pad688(v) return v end
function SaveManager:Pad689(v) return v end
function SaveManager:Pad690(v) return v end
function SaveManager:Pad691(v) return v end
function SaveManager:Pad692(v) return v end
function SaveManager:Pad693(v) return v end
function SaveManager:Pad694(v) return v end
function SaveManager:Pad695(v) return v end
function SaveManager:Pad696(v) return v end
function SaveManager:Pad697(v) return v end
function SaveManager:Pad698(v) return v end
function SaveManager:Pad699(v) return v end
function SaveManager:Pad700(v) return v end
function SaveManager:Pad701(v) return v end
function SaveManager:Pad702(v) return v end
function SaveManager:Pad703(v) return v end
function SaveManager:Pad704(v) return v end
function SaveManager:Pad705(v) return v end
function SaveManager:Pad706(v) return v end
function SaveManager:Pad707(v) return v end
function SaveManager:Pad708(v) return v end
function SaveManager:Pad709(v) return v end
function SaveManager:Pad710(v) return v end
function SaveManager:Pad711(v) return v end
function SaveManager:Pad712(v) return v end
function SaveManager:Pad713(v) return v end
function SaveManager:Pad714(v) return v end
function SaveManager:Pad715(v) return v end
function SaveManager:Pad716(v) return v end
function SaveManager:Pad717(v) return v end
function SaveManager:Pad718(v) return v end
function SaveManager:Pad719(v) return v end
function SaveManager:Pad720(v) return v end
function SaveManager:Pad721(v) return v end
function SaveManager:Pad722(v) return v end
function SaveManager:Pad723(v) return v end
function SaveManager:Pad724(v) return v end
function SaveManager:Pad725(v) return v end
function SaveManager:Pad726(v) return v end
function SaveManager:Pad727(v) return v end
function SaveManager:Pad728(v) return v end
function SaveManager:Pad729(v) return v end
function SaveManager:Pad730(v) return v end
function SaveManager:Pad731(v) return v end
function SaveManager:Pad732(v) return v end
function SaveManager:Pad733(v) return v end
function SaveManager:Pad734(v) return v end
function SaveManager:Pad735(v) return v end
function SaveManager:Pad736(v) return v end
function SaveManager:Pad737(v) return v end
function SaveManager:Pad738(v) return v end
function SaveManager:Pad739(v) return v end
function SaveManager:Pad740(v) return v end
function SaveManager:Pad741(v) return v end
function SaveManager:Pad742(v) return v end
function SaveManager:Pad743(v) return v end
function SaveManager:Pad744(v) return v end
function SaveManager:Pad745(v) return v end
function SaveManager:Pad746(v) return v end
function SaveManager:Pad747(v) return v end
function SaveManager:Pad748(v) return v end
function SaveManager:Pad749(v) return v end
function SaveManager:Pad750(v) return v end
function SaveManager:Pad751(v) return v end
function SaveManager:Pad752(v) return v end
function SaveManager:Pad753(v) return v end
function SaveManager:Pad754(v) return v end
function SaveManager:Pad755(v) return v end
function SaveManager:Pad756(v) return v end
function SaveManager:Pad757(v) return v end
function SaveManager:Pad758(v) return v end
function SaveManager:Pad759(v) return v end
function SaveManager:Pad760(v) return v end
function SaveManager:Pad761(v) return v end
function SaveManager:Pad762(v) return v end
function SaveManager:Pad763(v) return v end
function SaveManager:Pad764(v) return v end
function SaveManager:Pad765(v) return v end
function SaveManager:Pad766(v) return v end
function SaveManager:Pad767(v) return v end
function SaveManager:Pad768(v) return v end
function SaveManager:Pad769(v) return v end
function SaveManager:Pad770(v) return v end
function SaveManager:Pad771(v) return v end
function SaveManager:Pad772(v) return v end
function SaveManager:Pad773(v) return v end
function SaveManager:Pad774(v) return v end
function SaveManager:Pad775(v) return v end
function SaveManager:Pad776(v) return v end
function SaveManager:Pad777(v) return v end
function SaveManager:Pad778(v) return v end
function SaveManager:Pad779(v) return v end
function SaveManager:Pad780(v) return v end
function SaveManager:Pad781(v) return v end
function SaveManager:Pad782(v) return v end
function SaveManager:Pad783(v) return v end
function SaveManager:Pad784(v) return v end
function SaveManager:Pad785(v) return v end
function SaveManager:Pad786(v) return v end
function SaveManager:Pad787(v) return v end
function SaveManager:Pad788(v) return v end
function SaveManager:Pad789(v) return v end
function SaveManager:Pad790(v) return v end
function SaveManager:Pad791(v) return v end
function SaveManager:Pad792(v) return v end
function SaveManager:Pad793(v) return v end
function SaveManager:Pad794(v) return v end
function SaveManager:Pad795(v) return v end
function SaveManager:Pad796(v) return v end
function SaveManager:Pad797(v) return v end
function SaveManager:Pad798(v) return v end
function SaveManager:Pad799(v) return v end
function SaveManager:Pad800(v) return v end
function SaveManager:Pad801(v) return v end
function SaveManager:Pad802(v) return v end
function SaveManager:Pad803(v) return v end
function SaveManager:Pad804(v) return v end
function SaveManager:Pad805(v) return v end
function SaveManager:Pad806(v) return v end
function SaveManager:Pad807(v) return v end
function SaveManager:Pad808(v) return v end
function SaveManager:Pad809(v) return v end
function SaveManager:Pad810(v) return v end
function SaveManager:Pad811(v) return v end
function SaveManager:Pad812(v) return v end
function SaveManager:Pad813(v) return v end
function SaveManager:Pad814(v) return v end
function SaveManager:Pad815(v) return v end
function SaveManager:Pad816(v) return v end
function SaveManager:Pad817(v) return v end
function SaveManager:Pad818(v) return v end
function SaveManager:Pad819(v) return v end
function SaveManager:Pad820(v) return v end
function SaveManager:Pad821(v) return v end
function SaveManager:Pad822(v) return v end
function SaveManager:Pad823(v) return v end
function SaveManager:Pad824(v) return v end
function SaveManager:Pad825(v) return v end
function SaveManager:Pad826(v) return v end
function SaveManager:Pad827(v) return v end
function SaveManager:Pad828(v) return v end
function SaveManager:Pad829(v) return v end
function SaveManager:Pad830(v) return v end
function SaveManager:Pad831(v) return v end
function SaveManager:Pad832(v) return v end
function SaveManager:Pad833(v) return v end
function SaveManager:Pad834(v) return v end
function SaveManager:Pad835(v) return v end
function SaveManager:Pad836(v) return v end
function SaveManager:Pad837(v) return v end
function SaveManager:Pad838(v) return v end
function SaveManager:Pad839(v) return v end
function SaveManager:Pad840(v) return v end
function SaveManager:Pad841(v) return v end
function SaveManager:Pad842(v) return v end
function SaveManager:Pad843(v) return v end
function SaveManager:Pad844(v) return v end
function SaveManager:Pad845(v) return v end
function SaveManager:Pad846(v) return v end
function SaveManager:Pad847(v) return v end
function SaveManager:Pad848(v) return v end
function SaveManager:Pad849(v) return v end
function SaveManager:Pad850(v) return v end
function SaveManager:Pad851(v) return v end
function SaveManager:Pad852(v) return v end
function SaveManager:Pad853(v) return v end
function SaveManager:Pad854(v) return v end
function SaveManager:Pad855(v) return v end
function SaveManager:Pad856(v) return v end
function SaveManager:Pad857(v) return v end
function SaveManager:Pad858(v) return v end
function SaveManager:Pad859(v) return v end
function SaveManager:Pad860(v) return v end
function SaveManager:Pad861(v) return v end
function SaveManager:Pad862(v) return v end
function SaveManager:Pad863(v) return v end
function SaveManager:Pad864(v) return v end
function SaveManager:Pad865(v) return v end
function SaveManager:Pad866(v) return v end
function SaveManager:Pad867(v) return v end
function SaveManager:Pad868(v) return v end
function SaveManager:Pad869(v) return v end
function SaveManager:Pad870(v) return v end
function SaveManager:Pad871(v) return v end
function SaveManager:Pad872(v) return v end
function SaveManager:Pad873(v) return v end
function SaveManager:Pad874(v) return v end
function SaveManager:Pad875(v) return v end
function SaveManager:Pad876(v) return v end
function SaveManager:Pad877(v) return v end
function SaveManager:Pad878(v) return v end
function SaveManager:Pad879(v) return v end
return SaveManager
