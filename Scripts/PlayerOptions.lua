-- WARNING: VERY HACKY CODE BELOW
-- this is somewhat of a port and a reimplementation of the PlayerOptions system from https://github.com/Simply-Love/Simply-Love-SM5/blob/itgmania-release/Scripts/SL-PlayerOptions.lua
-- there are a multitude of hacks in place to handle dynamic text updating
-- i will do my best to explain what happens below, as while this setup has some hacks, it is also very much more flexible and human readable from the original system implemented by Mad Matt


-- find a noteskin listed in the DefaultModifiers string located in Data/GamePrefs.ini
function GetDefaultNoteSkinFromGamePrefsIni()
    -- if this function is called too early: as in there is no game style set (dance, pump, etc)
    -- the game will return the names of the directories of each noteskin, rather than a map of noteskin names
    -- there aren't many differences between the two, but the latter returns a list where all names are lowercased, and the former returns names capitalized as-is in the NoteSkins directory
    -- while these differences are small, it's enough to cause problems when looking through DefaultModifiers, since the casing might not match, and we cannot guarantee to receive a list of names lowercased by the game either
    -- which means we now need to take matters in our own hands and string.lower everything
    local noteskins = NOTESKIN:GetNoteSkinNames()
    for i, noteskin in ipairs(noteskins) do
        noteskins[i] = string.lower(noteskin)
    end
    local defaults = string.lower(PREFSMAN:GetPreference'DefaultModifiers')
    for str in string.gfind(defaults, '[^,]+') do
        local mod = string.gsub(str, " ", "")
        for i, noteskin in ipairs(noteskins) do
            if mod == noteskin then
                return noteskin
            end
        end
    end
    -- no noteskins present within DefaultModifiers, fall back onto a common noteskin
    return 'scalable'
end

-- default player modifiers, currently ignores everything from DefaultModifiers with the exception of NoteSkin
local defaultmodifiers = {
    __index = {
        init = function(self)
            self.ActiveModifiers = {
                SpeedModType = "X",
                SpeedMod = 1.00,
                Mini = "0%",
                NoteSkin = GetDefaultNoteSkinFromGamePrefsIni(),
                JudgmentGraphic = "Love",
                HoldGraphic = "Love",
            }
        end
    }
}

-- default modifiers that both players share, these cannot be player specific
local globaldefaults = {
    __index = {
        init = function(self)
            self.ActiveModifiers = {
                MusicRate = 1.0,
            }
            self.ScreenAfter = {
                PlayerOptions = "ScreenGameplay",
                PlayerOptions2 = "ScreenGameplay",
            }
        end
    }
}

-- generate two tables that will hold options each player can set, and another holding non-player specific options
_SL.PlayerOptions = {
    setmetatable({}, defaultmodifiers),
    setmetatable({}, defaultmodifiers),
}
_SL.Global = setmetatable({}, globaldefaults)

_SL.PlayerOptions[1]:init()
_SL.PlayerOptions[2]:init()
_SL.Global:init()

-- get the table of active options, and the PlayerOptions object for each player
local function GetModsAndPlayerOptions(pn)
    local mods = _SL.PlayerOptions[pn + 1].ActiveModifiers
    local poptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions()
    return mods, poptions
end

-- convenience: check if the type of a variable is a function
local function isfunction(var)
    return type(var) == "function"
end

-- find a value within an integer indexed table
function findintable(needle, haystack)
	for i = 1, #haystack do
		if needle == haystack[i] then
			return i
		end
	end
	return nil
end

local function range(start, stop, step)
	if start == nil then return end

	if not stop then
		stop = start
		start = 1
	end

	step = step or 1

	-- if step has been explicitly provided as a positive number
	-- but the start and stop values tell us to decrement
	-- multiply step by -1 to allow decrementing to occur
	if step > 0 and start > stop then
		step = -1 * step
	end

	local t = {}
	for i = start, stop, step do
		t[#t+1] = i
	end
	return t
end

local function stringify( tbl, form )
	if not tbl then return end

	local t = {}
	for _,value in ipairs(tbl) do
		t[#t+1] = (type(value)=="number" and form and string.format(form, value) ) or tostring(value)
	end
	return t
end

-- certain of our rows change the option text of other rows, we need to make the underlines of those rows change in size to accomodate the newly set text
local function resizeunderline(row, pn)
    -- get the row to modify the underline sprites
    local row = _SL.Options.Cache.row[row]
    -- get a list of actorframes containing underlines for the player, as there can be multiple underlines to change within a row
    local underlines = row.Underlines[pn]
    -- each underline is seperated into three sprites, which within each actorframe is sorted as such:
    -- center portion of the underline, this portion is what needs to be resized in accordance to the text associated with it
    -- left side of the underline, this needs to be shifted to the left by half the new width of the center underline
    -- right side of the underline, this needs to be shifted to the right by half the new width of the center underline
    for i = 1, #underlines do
        local text = row.Choices[pn][i]
        -- the width of the center underline needs to be the width of the text, times it's zoom
        local zoom = text:GetWidth() * text:GetZoom()
        underlines[i](1):zoomtowidth(zoom)
        local transform = (zoom + underlines[i](1):GetWidth()) / 2
        underlines[i](2):x(-transform)
        underlines[i](3):x(transform)
    end
end

-- the same applies to our cursor, but only when we are directly onto the row that is updating it's text, this behaves very similarly to the funtion above
local function resizecursor(row, pn, idx)
    if _SL.Options.Cache.Cursor then
        -- don't resize on the first pass of rows, as we force a SaveSelection to display custom text, which also toggles a resize of the cursor
        -- but given we are not on any rows that need to be resized, exit early and call resize when we actually call SaveSelections from source
        if _SL.Options.Cache.Cursor.FirstInit[pn] then
            _SL.Options.Cache.Cursor.FirstInit[pn] = false
            return
        end
        local row = _SL.Options.Cache.row[row]
        local cursor = _SL.Options.Cache.Cursor[pn]
        local text = row.Choices[pn][idx]
        local zoom = text:GetWidth() * text:GetZoom()
        cursor(1):zoomtowidth(zoom)
        local transform = (zoom + cursor(1):GetWidth()) / 2
        cursor(2):x(-transform)
        cursor(3):x(transform)
    end
end

local function updatespeedmod(pn, mods, poptions)
    if _SL.Options.Cache.row.SpeedMod.Choices then
        local type = mods.SpeedModType or "X"
        local speed = mods.SpeedMod or 1.00
        -- handle logic for speedmods here
        if type ~= "X" then
            speed = speed * 100
            poptions:XMod(1, -1, true)
            poptions[type .. 'Mod'](poptions, speed)
        else
            poptions:CMod(nil, -1, true):MMod(nil, -1, true):XMod(speed)
        end
        _SL.Options.Cache.row.SpeedMod.Choices[pn + 1][1]:settext(speed)
        resizeunderline('SpeedMod', pn + 1)
    end
end

local PlayerOptionOverrides = {
    SpeedModType = {
        Values = {"X", "C", "M"},
        ExportOnChange = true,
        LayoutType = "ShowOneInRow",
        SaveSelections = function(self, list, pn)
            local mods, poptions = GetModsAndPlayerOptions(pn)
            for i = 1, #list do
                if list[i] then
                    mods.SpeedModType = self.Values[i]
                    break
                end
            end
            updatespeedmod(pn, mods, poptions)
        end
    },
    SpeedMod = {
        -- this is a very strange way of keeping track of what index a player changed to to see if we should increment or decrement the player's speed
        Choices = {" ", LastIndex1 = "1", LastIndex2 = "1"},
        ExportOnChange = true,
        LayoutType = "ShowOneInRow",
        LoadSelections = function(self, list, pn)
            -- resetting values in LoadSelections will prevent the values from changing when loading PlayerOptions and the last time we were on this screen we had a list index that is any other value than 1
            self.Choices["LastIndex" .. pn + 1] = "1"
            list[1] = true
            list[2] = false
            list[3] = false
            return list
        end,
        SaveSelections = function(self, list, pn)
            local prev = tonumber(self.Choices["LastIndex" .. pn + 1])
            local current = -1
            for i = 1, #list do
                if list[i] then
                    current = i
                    break
                end
            end
            local difference = current - prev
            local mods, poptions = GetModsAndPlayerOptions(pn)

            if difference == 1 or difference == -2 then
                mods.SpeedMod = mods.SpeedMod + 0.05
            elseif difference == -1 or difference == 2 then
                mods.SpeedMod = math.max(mods.SpeedMod - 0.05, 0)
            end
            self.Choices["LastIndex" .. pn + 1] = tostring(current)
            updatespeedmod(pn, mods, poptions)
            resizecursor('SpeedMod', pn + 1, 1)
        end
    },
    NoteSkin = {
        ExportOnChange = true,
        LayoutType = "ShowOneInRow",
        Choices = function()
            local all = NOTESKIN:GetNoteSkinNames()
            -- these are noteskins that, outside of very specific modfiles, have no reason to be selectable by a player
            -- either it be due to the noteskin being a command noteskin, or crashing on specific notetypes
            -- those noteskins will be applied automatically when needed
            local noteskinstoremove = {
                "arrowkun", "cel2d", "cel-cmd", "cel-cmd-notweens", "cel-glow2", "cel-yuno", "coin", "controlcel", "controlmetal", "controlmetal2", "couples-backup", "couples-cmd", "couples-cmd-backup", "couplescontrol", "ddefault_pump_fuck", "ddefault-liftless", "default", "de-default", "divinentity", "dunno", "dunno2", "justholds", "metal2_dpad", "metal-cmd", "metal-cmdholds", "metal-cmd-notweens", "mindcode", "minderror", "mindgalaxykiss", "mindkickmetal", "mindnoshow", "mindpressure", "mindrockstarmetal", "mindtechmetal", "proxynotes", "scalable_backup", "scalablegray", "scalablew", "slow", "solid_black", "spikes2", "splitter", "spt"
            }
            for i, noteskin in ipairs(noteskinstoremove) do
                for i = 1, #all do
                    if noteskin == all[i] then
                        table.remove(all, i)
                        break
                    end
                end
            end
            return all
        end,
        SaveSelections = function(self, list, pn)
            local mods, poptions = GetModsAndPlayerOptions(pn)
            for i, val in ipairs(self.Choices) do
                if list[i] then mods.NoteSkin = val; break end
            end
            GAMESTATE:ApplyModifiers(mods.NoteSkin, pn + 1)
            GAMESTATE:ApplyModifiers(mods.NoteSkin, pn + 3)
            GAMESTATE:ApplyModifiers(mods.NoteSkin, pn + 5)
            GAMESTATE:ApplyModifiers(mods.NoteSkin, pn + 7)
        end
    },
    Mini = {
        Choices = function()
            local first = -100
            local last = 150
            local step = 1
            return stringify(range(first, last, step), "%g%%")
        end,
        SaveSelections = function(self, list, pn)
            local mods, poptions = GetModsAndPlayerOptions(pn)

            for i = 1, #self.Choices do
                if list[i] then
                    mods.Mini = self.Choices[i]
                end
            end
            poptions:Mini(string.gsub(mods.Mini, "%%", "") / 100)
        end
    },
    MusicRate = {
        Choices = function()
            local first = 0.05
            local last = 3
            local step = 0.01

            return stringify( range(first, last, step), "%g")
        end,
        ExportOnChange = true,
        OneChoiceForAllPlayers = true,
        LoadSelections = function(self, list, pn)
            local rate = string.format("%g", _SL.Global.ActiveModifiers.MusicRate )
            local i = findintable(rate, self.Choices) or 1
            list[i] = true
            return list
        end,
        SaveSelections = function(self, list, pn)
            local rate = _SL.Global.ActiveModifiers.MusicRate
            for i = 1, #self.Choices do
                if list[i] then
                    rate = tonumber(self.Choices[i])
                end
            end
            GAMESTATE:ApplyModifiers(rate .. "xmusic")
            MESSAGEMAN:Broadcast('MusicRateChanged')
        end
    },
    JudgmentGraphic = {
        Choices = function()
            local list = {'Love'}
            local dir = string.sub(THEME:GetPath(2,'','_blank.png'),9)
            dir = string.sub(dir,1,string.find(dir,'/')-1)
            for _,v in pairs({ GAMESTATE:GetFileStructure('Themes/'.. dir ..'/Graphics/_Judgments/') }) do
                local t, _, name = string.find(v, "(.+) %dx%d")
                if t then table.insert( list, name )
                else print('[Judgment] Error in loading ' .. v)
                end
            end
            return list
        end,
        SaveSelections = function(self, list, pn)
            local mods = _SL.PlayerOptions[pn + 1].ActiveModifiers
            for i, val in ipairs(self.Choices) do
                if list[i] then
                    mods.JudgmentGraphic = val
                    break
                end
            end
        end
    },
    HoldGraphic = {
        Choices = function()
            local list = {'Love'}
            local dir = string.sub(THEME:GetPath(2,'','_blank.png'),9)
            dir = string.sub(dir,1,string.find(dir,'/')-1)
            for _,v in pairs({ GAMESTATE:GetFileStructure('Themes/'.. dir ..'/Graphics/_Hold Judgments/') }) do
                local t, _, name = string.find(v, "(.+) %dx%d")
                if t then table.insert( list, name )
                else print('[Hold Judgment] Error in loading ' .. v)
                end
            end
            return list
        end,
        SaveSelections = function(self, list, pn)
            local mods = _SL.PlayerOptions[pn + 1].ActiveModifiers
            for i, val in ipairs(self.Choices) do
                if list[i] then
                    mods.HoldGraphic = val
                    break
                end
            end
        end
    },
    ScreenAfterPlayerOptions = {
        Values = {"Gameplay", "Select Music", "Options2"},
        OneChoiceForAllPlayers = true,
        SaveSelections = function(self, list, pn)
            if list[1] then _SL.Global.ScreenAfter.PlayerOptions = 'ScreenStage' end
            if list[2] then _SL.Global.ScreenAfter.PlayerOptions = 'ScreenSelectMusic' end
            if list[3] then _SL.Global.ScreenAfter.PlayerOptions = 'ScreenPlayerOptions2' end
        end
    },
    ScreenAfterPlayerOptions2 = {
        Values = {"Gameplay", "Select Music", "Options1"},
        OneChoiceForAllPlayers = true,
        SaveSelections = function(self, list, pn)
            if list[1] then _SL.Global.ScreenAfter.PlayerOptions = 'ScreenStage' end
            if list[2] then _SL.Global.ScreenAfter.PlayerOptions = 'ScreenSelectMusic' end
            if list[3] then _SL.Global.ScreenAfter.PlayerOptions = 'ScreenPlayerOptions' end
        end
    }
}

local defaultoptionrow = {
    __index = {
        init = function(self, name)
            -- set the displayed name of our option row
            print("Row Init:", name)
            self.Name = name

            -- look up if our PlayerOptions table has values to override our default values with
            local override = PlayerOptionOverrides[name] or {
                Choices = {'This', 'Is', 'A', 'Default', 'Choice', 'List'}
            }

            if override.Values then
                local values = override.Values
                if override.Choices then
                    local choices = override.Choices
                    self.Choices = isfunction(choices) and choices() or choices
                else
                    self.Choices = {}
                    for i, v in ipairs(isfunction(values) and values() or values) do
                        self.Choices[i] = THEME:GetMetric("CustomPlayerOptions", v)
                    end
                end
                self.Values = type(values) == "function" and values() or values
            else
                local choices = override.Choices
                self.Choices = isfunction(choices) and choices() or choices
            end

            -- valid layout types: ShowAllInRow, ShowOneInRow
            self.LayoutType = override.LayoutType or "ShowAllInRow"
            -- valid select types: SelectOne, SelectMultiple, SelectNone
            self.SelectType = override.SelectType or "SelectOne"
            self.OneChoiceForAllPlayers = override.OneChoiceForAllPlayers or false
            -- currently does not do anything
            self.ExportOnChange = override.ExportOnChange or false

            if self.SelectType == "SelectOne" then
                self.LoadSelections = override.LoadSelections or function(sub, list, pn)
                    -- print("Load True", self.Name)
                    local mods, poptions = GetModsAndPlayerOptions(pn)
                    local choice = mods[name] or (poptions[name] ~= nil and poptions[name](poptions)) or self.Choices[1]
                    local i = findintable(choice, self.Values or self.Choices) or 1
                    list[i] = true
                    return list
                end
                self.SaveSelections = override.SaveSelections or function(sub, list, pn)
                    local mods = _SL.PlayerOptions[pn + 1].ActiveModifiers
                    local vals = self.Values or self.Choices
                    for i, val in ipairs(vals) do
                        if list[i] then
                            mods[name] = val
                            break
                        end
                    end
                end
            else
                self.LoadSelections = override.LoadSelections or function(sub, list, pn)
                    local mods = _SL.PlayerOptions[pn + 1].ActiveModifiers
                    local vals = self.Values or self.Choices
                    for i, mod in ipairs(vals) do
                        list[i] = mods[mod] or false
                    end
                    return list
                end
                self.SaveSelections = override.SaveSelections or function(sub, list, pn)
                    local mods = _SL.PlayerOptions[pn + 1].ActiveModifiers
                    local vals = self.Values or self.Choices
                    for i, mod in ipairs(vals) do
                        mods[mod] = list[i]
                    end
                end
            end

            local loadselections = self.LoadSelections

            self.LoadSelections = function(sub, list, pn)
                -- link internal row name to translated name
                -- a bit backwards but we have to make due with the order things are run and exposed to us in theme
                local displayedname = THEME:GetMetric("OptionTitles", self.Name)
                if not _SL.Options.Cache.row[self.Name] then 
                    if _SL.Options.Cache.map[displayedname] then
                        print('"' .. displayedname .. '" is already mapped, ensure an entry for "' .. self.Name .. '" is present in [OptionTitles] of ' .. THEME:GetCurLanguage() .. '.ini to avoid issues with the Option Cache')
                    end
                    _SL.Options.Cache.map[displayedname] = self.Name
                    _SL.Options.Cache.row[self.Name] = {
                        list = {},
                        self = self
                    }
                end
                -- print("List", displayedname, self.Name, _SL.Options.Cache.row[self.Name])
                _SL.Options.Cache.row[self.Name].list[pn + 1] = list

                return loadselections(sub, list, pn)
            end
            
            return self
        end
    }
}


_SL.Options = {}

_SL.Options.CustomRow = function(name)
    -- ensure we're passing in a string for our row, and that it's a part of our existing option rows
    -- if not (type(name) == "string" and PlayerOptions[name]) then return false end

    -- assign default properties to our row
    local row = setmetatable({}, defaultoptionrow)

    -- now that our row has an init method available, run it.
    return row:init(name)
end

_SL.Options.Cache = {}

local cacheoptions = function(self)
    print("Row Cache")
    local playersjoined = GAMESTATE:GetNumPlayersEnabled()
    -- page
    -- linehighlight (one per player)
    -- cursor (one per player)
    -- depending on how many players are joined, rows will start at either child 6, or child 4
    -- rows
    local rowsstartat = 1 + 2 * playersjoined + 1
    local frame = SCREENMAN'Frame'

    _SL.Options.Cache.Highlight = {}
    _SL.Options.Cache.Cursor = {}

    if playersjoined > 1 then
        _SL.Options.Cache.Highlight[1] = frame(2)
        _SL.Options.Cache.Highlight[2] = frame(3)
        _SL.Options.Cache.Cursor[1] = frame(4)
        _SL.Options.Cache.Cursor[2] = frame(5)
    else
        _SL.Options.Cache.Highlight[1] = frame(2)
        _SL.Options.Cache.Highlight[2] = frame(2)
        _SL.Options.Cache.Cursor[1] = frame(3)
        _SL.Options.Cache.Cursor[2] = frame(3)
    end

    for rowcontainer = rowsstartat, #frame do
        local actor = frame(rowcontainer)
        -- once we reach an actor that is not an actorframe, we are no longer within row bounds
        if not string.find(tostring(actor), "ActorFrame") then break end
        local data = actor''
        local name = data(4):GetText()
        local internalname = _SL.Options.Cache.map[name]

        if not _SL.Options.Cache.Cursor.FirstInit then
            _SL.Options.Cache.Cursor.FirstInit = {true, true}
        end
        
        if internalname then
            local row = _SL.Options.Cache.row[internalname]
            local self = row.self
            local layout = self.LayoutType
            row.Title = data(4)
            local choices = {}
            row.Choices = {{}, {}}
            row.Underlines = {{}, {}}
            for idx = 5, #data do
                if not string.find(tostring(data(idx)), "BitmapText") then break end
                table.insert(choices, data(idx))
            end
            local choicesonscreen = #choices
            local forcedcondensed = layout == "ShowAllInRow" and #self.Choices ~= #choices
            -- rows can display choices in three different ways:
            -- the first is with the layout type "ShowOneInRow", which will always have one choice displayed per player, so two bitmaptexts for the row in question, this display can also be fell back onto if each player can pick a different option, and there are too many choices to fit on screen
            -- in this state, there is a maximum of two underlines for the row, one per player

            -- the second is a row that displays choices that are shared by both players, but has more choices than can fit on screen, in this case the choices are condensed into one displayed choice, so one bitmaptext for the row in question
            -- similar to the first case, there is also a maximum of two underlines for the row, one per player
            -- in both of these states, the first underline is that of p1 (or p2 if it is the only side joined), followed by p2 if both sides are joined 
            if layout == "ShowOneInRow" or forcedcondensed then
                row.Choices[1][1] = choices[1]
                row.Underlines[1][1] = data(5 + choicesonscreen)
                if playersjoined > 1 then
                    row.Choices[2][1] = choices[2]
                    row.Underlines[2][1] = data(5 + choicesonscreen + 1)
                else
                    row.Choices[2][1] = choices[1]
                    row.Underlines[2][1] = row.Underlines[1][1]
                end

            -- the third state is a row with the layout type of "ShowAllInRow", in which all of the options can fit on screen
            -- this state has a maximum of n * pn underlines, where n is the amount of choices for the row, and pn is the amount of players joined
            -- in this state, the first n underlines are those of p1 (or again, p2 if it is the only side joined), and the next n underlines are of p2 if both players are joined
            else
                for i = 1, #choices do
                    row.Choices[1][i] = choices[i]
                    row.Choices[2][i] = choices[i]
                    row.Underlines[1][i] = data(5 + choicesonscreen + (i - 1))
                    if playersjoined > 1 then
                        row.Underlines[2][i] = data(5 + (choicesonscreen * 2) + (i - 1))
                    else
                        row.Underlines[2][i] = row.Underlines[1][i]
                    end
                end
            end
            for pn = 0, 1 do
                if GAMESTATE:IsPlayerEnabled(pn) then
                    print("Forcing Save:", internalname, pn)
                    self.SaveSelections(row.self, row.list[pn + 1], pn)
                end
            end
        end
    end
end

_SL.Options.On = function(self)
    _SL.Options.Cache = {
        row = {},
        map = {}
    }
    self:addcommand('Cache', cacheoptions):queuecommand'Cache'
end