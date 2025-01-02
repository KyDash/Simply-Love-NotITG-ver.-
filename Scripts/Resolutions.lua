-- want a custom resolution in your list? add the window *height* in here
local resolutionheight = {480, 600, 720, 768, 1080, 1200, 1440, 1536, 2880}
local aspectratio = {'4:3', '16:9', '16:10', '21:9', '32:9'}

local function round(num, ndp) local mult = 10 ^ (ndp or 0) return math.floor(num * mult + 0.5) / mult end

local epsilon = 0.044

SLGraphicSettings = {}
local t = SLGraphicSettings
t.LineNames = function()
	local lines = 'Windowed,DisplayAspectRatio,DisplayResolution,DisplayColor,TextureResolution,TextureColor,MovieColor,SmoothLines,CelShadeModels,DelayedTextureDelete,RefreshRate,Vsync,ShowStats,ShowBanners'
	if MonthOfYear() == 4 and DayOfMonth() == 1 then
		lines = lines .. ',o2jam'
	end

	return lines
end

t.AspectRatioList = aspectratio
t.ResolutionList = {
	current = {},
	currentratio = ''
}

for i = 1, table.getn(resolutionheight) do
	t.ResolutionList.current[i] = resolutionheight[i]
end

local aspectratiodetails = {}

for i, ratio in ipairs(t.AspectRatioList) do
	local isolatedvalues = {}
	for value in string.gfind(ratio, '[^:]+') do
		table.insert(isolatedvalues, value)
	end
	local l, r = tonumber(isolatedvalues[1], 10), tonumber(isolatedvalues[2], 10)
	local ratiomult = l / r

	-- ultrawide monitors, also known as 21:9 aspect ratio displays, are not truly 21/9
	-- so force resolutions typically under this label to be recognised
	-- which sadist decided 
	if ratiomult == 21 / 9 then ratiomult = 3440 / 1440 end

	aspectratiodetails[ratiomult] = ratio

	t.ResolutionList[ratio] = {}
	for _, height in ipairs(resolutionheight) do
		local width = height * ratiomult
		local stringres = round(width, 0) .. 'x' .. round(height, 0)
		table.insert(t.ResolutionList[ratio], {width, height, stringres})
	end
end

t.AspectRatio = function()
	local curmult = round(PREFSMAN:GetPreference"DisplayAspectRatio", 6)
	local options = t.AspectRatioList
	local params = {
		Name = "Aspect Ratio",
		ReloadRowMessages = {"UpdateResolutionLines"},
		ExportOnChange = true,
	}
	local function save(self, list, pn)
		for i = 1, table.getn(aspectratio) do
			if list[i] then
				t.ResolutionList.currentratio = aspectratio[i]
				return
			end
		end
	end
	local function load(self, list, pn)
		t.ResolutionList.currentratio = '4:3'
		for mult, ratio in pairs(aspectratiodetails) do
			if round(mult, 6) == round(curmult, 6) then
				t.ResolutionList.currentratio = ratio
				break
			end
		end

		for i = 1, table.getn(options) do
			if options[i] == t.ResolutionList.currentratio then
				for i, v in ipairs(t.ResolutionList[t.ResolutionList.currentratio]) do
					t.ResolutionList.current[i] = v[3]
				end
				list[i] = true return
			end
		end
		list[1] = true
	end
	return CreateOptionRow(params, options, load, save)
end

local function updateresolutionlistdisplay()

end

t.Resolution = function()
	local curwidth = round(PREFSMAN:GetPreference"DisplayWidth", 0)
	local curheight = round(PREFSMAN:GetPreference"DisplayHeight", 0)
	local params = {Name = (FUCK_EXE and "Display Resolution" or "Display Height")}
	local function save(self, list, pn)
		for i = 1, table.getn(t.ResolutionList.current) do
			if list[i] then
				local ratio = t.ResolutionList.currentratio
				local resolution = t.ResolutionList[ratio][i]
				PREFSMAN:SetPreference("DisplayWidth", resolution[1])
				PREFSMAN:SetPreference("DisplayHeight", resolution[2])
				-- doesn't take effect until a game reload
				PREFSMAN:SetPreference("DisplayAspectRatio", resolution[1] / resolution[2])

				if FUCK_EXE then
					DISPLAY:SetWindowPositionAndSize(0 ,0 , resolution[1], resolution[2])
				end
				return
			end
		end
	end
	local function load(self, list, pn)
		for i, v in ipairs(t.ResolutionList[t.ResolutionList.currentratio]) do
			if curwidth == round(v[1], 0) and curheight == round(v[2], 0) then
				list[i] = true return
			end
		end
		list[1] = true
	end
	return CreateOptionRow(params, FUCK_EXE and t.ResolutionList.current or resolutionheight, load, save)
end

t.o2jam = function()
	local options = {'ON', 'OFF'}
	local params = {Name = "Graphic"}
	local function save(self, list, pn)
		if list[2] == true then
			GAMESTATE:ApplyGameCommand'screen,ScreenExit'
		end
	end
	local function load(self, list, pn)
		list[1] = true
	end
	return CreateOptionRow(params, options, load, save)
end