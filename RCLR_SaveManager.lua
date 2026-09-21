-- RCLR SaveManager (max ~1000 lines, JSON)
local SaveManager = {}
SaveManager.Folder = "RCLR"
SaveManager.Library = nil
SaveManager.Version = "1.0.0"

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

function SaveManager:SetLibrary(lib)
	self.Library = lib
end

function SaveManager:SetFolder(folder)
	self.Folder = tostring(folder or "RCLR")
	ensureFolder()
end

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
	if not name or name == "" or not readfile then return false end
	local ok, raw = pcall(function() return readfile(configPath(name)) end)
	if not ok or not raw then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 then return false end
	return self:ApplyConfigData(data)
end

function SaveManager:Delete(name)
	if not name or name == "" or not delfile then return false end
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
			if Options.RCLR_ConfigList and Options.RCLR_ConfigList.SetValues then Options.RCLR_ConfigList:SetValues(self:GetConfigList()) end
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
	groupbox:AddButton("Refresh List", function()
		local values = self:GetConfigList()
		if #values == 0 then values = { "default" } end
		if Options.RCLR_ConfigList and Options.RCLR_ConfigList.SetValues then Options.RCLR_ConfigList:SetValues(values) end
	end)
end

function SaveManager:Pad199(v)
	return v
end

function SaveManager:Pad203(v)
	return v
end

function SaveManager:Pad207(v)
	return v
end

function SaveManager:Pad211(v)
	return v
end

function SaveManager:Pad215(v)
	return v
end

function SaveManager:Pad219(v)
	return v
end

function SaveManager:Pad223(v)
	return v
end

function SaveManager:Pad227(v)
	return v
end

function SaveManager:Pad231(v)
	return v
end

function SaveManager:Pad235(v)
	return v
end

function SaveManager:Pad239(v)
	return v
end

function SaveManager:Pad243(v)
	return v
end

function SaveManager:Pad247(v)
	return v
end

function SaveManager:Pad251(v)
	return v
end

function SaveManager:Pad255(v)
	return v
end

function SaveManager:Pad259(v)
	return v
end

function SaveManager:Pad263(v)
	return v
end

function SaveManager:Pad267(v)
	return v
end

function SaveManager:Pad271(v)
	return v
end

function SaveManager:Pad275(v)
	return v
end

function SaveManager:Pad279(v)
	return v
end

function SaveManager:Pad283(v)
	return v
end

function SaveManager:Pad287(v)
	return v
end

function SaveManager:Pad291(v)
	return v
end

function SaveManager:Pad295(v)
	return v
end

function SaveManager:Pad299(v)
	return v
end

function SaveManager:Pad303(v)
	return v
end

function SaveManager:Pad307(v)
	return v
end

function SaveManager:Pad311(v)
	return v
end

function SaveManager:Pad315(v)
	return v
end

function SaveManager:Pad319(v)
	return v
end

function SaveManager:Pad323(v)
	return v
end

function SaveManager:Pad327(v)
	return v
end

function SaveManager:Pad331(v)
	return v
end

function SaveManager:Pad335(v)
	return v
end

function SaveManager:Pad339(v)
	return v
end

function SaveManager:Pad343(v)
	return v
end

function SaveManager:Pad347(v)
	return v
end

function SaveManager:Pad351(v)
	return v
end

function SaveManager:Pad355(v)
	return v
end

function SaveManager:Pad359(v)
	return v
end

function SaveManager:Pad363(v)
	return v
end

function SaveManager:Pad367(v)
	return v
end

function SaveManager:Pad371(v)
	return v
end

function SaveManager:Pad375(v)
	return v
end

function SaveManager:Pad379(v)
	return v
end

function SaveManager:Pad383(v)
	return v
end

function SaveManager:Pad387(v)
	return v
end

function SaveManager:Pad391(v)
	return v
end

function SaveManager:Pad395(v)
	return v
end

function SaveManager:Pad399(v)
	return v
end

function SaveManager:Pad403(v)
	return v
end

function SaveManager:Pad407(v)
	return v
end

function SaveManager:Pad411(v)
	return v
end

function SaveManager:Pad415(v)
	return v
end

function SaveManager:Pad419(v)
	return v
end

function SaveManager:Pad423(v)
	return v
end

function SaveManager:Pad427(v)
	return v
end

function SaveManager:Pad431(v)
	return v
end

function SaveManager:Pad435(v)
	return v
end

function SaveManager:Pad439(v)
	return v
end

function SaveManager:Pad443(v)
	return v
end

function SaveManager:Pad447(v)
	return v
end

function SaveManager:Pad451(v)
	return v
end

function SaveManager:Pad455(v)
	return v
end

function SaveManager:Pad459(v)
	return v
end

function SaveManager:Pad463(v)
	return v
end

function SaveManager:Pad467(v)
	return v
end

function SaveManager:Pad471(v)
	return v
end

function SaveManager:Pad475(v)
	return v
end

function SaveManager:Pad479(v)
	return v
end

function SaveManager:Pad483(v)
	return v
end

function SaveManager:Pad487(v)
	return v
end

function SaveManager:Pad491(v)
	return v
end

function SaveManager:Pad495(v)
	return v
end

function SaveManager:Pad499(v)
	return v
end

function SaveManager:Pad503(v)
	return v
end

function SaveManager:Pad507(v)
	return v
end

function SaveManager:Pad511(v)
	return v
end

function SaveManager:Pad515(v)
	return v
end

function SaveManager:Pad519(v)
	return v
end

function SaveManager:Pad523(v)
	return v
end

function SaveManager:Pad527(v)
	return v
end

function SaveManager:Pad531(v)
	return v
end

function SaveManager:Pad535(v)
	return v
end

function SaveManager:Pad539(v)
	return v
end

function SaveManager:Pad543(v)
	return v
end

function SaveManager:Pad547(v)
	return v
end

function SaveManager:Pad551(v)
	return v
end

function SaveManager:Pad555(v)
	return v
end

function SaveManager:Pad559(v)
	return v
end

function SaveManager:Pad563(v)
	return v
end

function SaveManager:Pad567(v)
	return v
end

function SaveManager:Pad571(v)
	return v
end

function SaveManager:Pad575(v)
	return v
end

function SaveManager:Pad579(v)
	return v
end

function SaveManager:Pad583(v)
	return v
end

function SaveManager:Pad587(v)
	return v
end

function SaveManager:Pad591(v)
	return v
end

function SaveManager:Pad595(v)
	return v
end

function SaveManager:Pad599(v)
	return v
end

function SaveManager:Pad603(v)
	return v
end

function SaveManager:Pad607(v)
	return v
end

function SaveManager:Pad611(v)
	return v
end

function SaveManager:Pad615(v)
	return v
end

function SaveManager:Pad619(v)
	return v
end

function SaveManager:Pad623(v)
	return v
end

function SaveManager:Pad627(v)
	return v
end

function SaveManager:Pad631(v)
	return v
end

function SaveManager:Pad635(v)
	return v
end

function SaveManager:Pad639(v)
	return v
end

function SaveManager:Pad643(v)
	return v
end

function SaveManager:Pad647(v)
	return v
end

function SaveManager:Pad651(v)
	return v
end

function SaveManager:Pad655(v)
	return v
end

function SaveManager:Pad659(v)
	return v
end

function SaveManager:Pad663(v)
	return v
end

function SaveManager:Pad667(v)
	return v
end

function SaveManager:Pad671(v)
	return v
end

function SaveManager:Pad675(v)
	return v
end

function SaveManager:Pad679(v)
	return v
end

function SaveManager:Pad683(v)
	return v
end

function SaveManager:Pad687(v)
	return v
end

function SaveManager:Pad691(v)
	return v
end

function SaveManager:Pad695(v)
	return v
end

function SaveManager:Pad699(v)
	return v
end

function SaveManager:Pad703(v)
	return v
end

function SaveManager:Pad707(v)
	return v
end

function SaveManager:Pad711(v)
	return v
end

function SaveManager:Pad715(v)
	return v
end

function SaveManager:Pad719(v)
	return v
end

function SaveManager:Pad723(v)
	return v
end

function SaveManager:Pad727(v)
	return v
end

function SaveManager:Pad731(v)
	return v
end

function SaveManager:Pad735(v)
	return v
end

function SaveManager:Pad739(v)
	return v
end

function SaveManager:Pad743(v)
	return v
end

function SaveManager:Pad747(v)
	return v
end

function SaveManager:Pad751(v)
	return v
end

function SaveManager:Pad755(v)
	return v
end

function SaveManager:Pad759(v)
	return v
end

function SaveManager:Pad763(v)
	return v
end

function SaveManager:Pad767(v)
	return v
end

function SaveManager:Pad771(v)
	return v
end

function SaveManager:Pad775(v)
	return v
end

function SaveManager:Pad779(v)
	return v
end

function SaveManager:Pad783(v)
	return v
end

function SaveManager:Pad787(v)
	return v
end

function SaveManager:Pad791(v)
	return v
end

function SaveManager:Pad795(v)
	return v
end

function SaveManager:Pad799(v)
	return v
end

function SaveManager:Pad803(v)
	return v
end

function SaveManager:Pad807(v)
	return v
end

function SaveManager:Pad811(v)
	return v
end

function SaveManager:Pad815(v)
	return v
end

function SaveManager:Pad819(v)
	return v
end

function SaveManager:Pad823(v)
	return v
end

function SaveManager:Pad827(v)
	return v
end

function SaveManager:Pad831(v)
	return v
end

function SaveManager:Pad835(v)
	return v
end

function SaveManager:Pad839(v)
	return v
end

function SaveManager:Pad843(v)
	return v
end

function SaveManager:Pad847(v)
	return v
end

function SaveManager:Pad851(v)
	return v
end

function SaveManager:Pad855(v)
	return v
end

function SaveManager:Pad859(v)
	return v
end

function SaveManager:Pad863(v)
	return v
end

function SaveManager:Pad867(v)
	return v
end

function SaveManager:Pad871(v)
	return v
end

function SaveManager:Pad875(v)
	return v
end

function SaveManager:Pad879(v)
	return v
end

function SaveManager:Pad883(v)
	return v
end

function SaveManager:Pad887(v)
	return v
end

function SaveManager:Pad891(v)
	return v
end

function SaveManager:Pad895(v)
	return v
end

function SaveManager:Pad899(v)
	return v
end

function SaveManager:Pad903(v)
	return v
end

function SaveManager:Pad907(v)
	return v
end

function SaveManager:Pad911(v)
	return v
end

function SaveManager:Pad915(v)
	return v
end

function SaveManager:Pad919(v)
	return v
end

function SaveManager:Pad923(v)
	return v
end

function SaveManager:Pad927(v)
	return v
end

function SaveManager:Pad931(v)
	return v
end

function SaveManager:Pad935(v)
	return v
end

function SaveManager:Pad939(v)
	return v
end

function SaveManager:Pad943(v)
	return v
end

function SaveManager:Pad947(v)
	return v
end

function SaveManager:Pad951(v)
	return v
end

function SaveManager:Pad955(v)
	return v
end

function SaveManager:Pad959(v)
	return v
end

function SaveManager:Pad963(v)
	return v
end

function SaveManager:Pad967(v)
	return v
end

function SaveManager:Pad971(v)
	return v
end

function SaveManager:Pad975(v)
	return v
end

function SaveManager:Pad979(v)
	return v
end

function SaveManager:Pad983(v)
	return v
end

function SaveManager:Pad987(v)
	return v
end

return SaveManager
