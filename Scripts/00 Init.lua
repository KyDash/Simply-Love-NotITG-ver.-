-- table for things the theme will use in multiple places, this file *needs* to be executed first
-- will possibly split this up in chunks later but, for the time being i'll be putting any variables created in one xml but shared with many here.
-- this will ensure that reloading the theme will avoid errors where a screen expects a value created by a previous screen, which a reload will put in an odd order, and thus the value not existing
_SL = {}
-- the logo state, this switches between `ScreenLogo underlay` and `ScreenLove underlay`
_SL.love = 0

-- state of the background colour, when set to 1, background hearts will be in general brighter
-- specifically set to 1 for `ScreenLogo` and `ScreenEndingGood` (which can be accessed when the worst grade of a set is an `S+`)
_SL.Crazy = 0

-- floored division modulo implementation
-- lua 5.0's `math.mod` (and notitg's backport of the % operator) use truncated division, which often yields to unintended results when operating on a negative dividend
-- lua 5.1 and beyond use floored division instead, which makes negative dividends consistent with positive ones
_SL.modulo = function(a, b) return a - math.floor(a / b) * b end

-- game styles, sets game rules, preferences, menu display settings that is relevent to the set style
_SL.GameStyle = {
    -- normal ITG gameplay, the most customizable of these styles as it is effectively free play
    ITG = true,
    -- for sight reading even purposes, sets up specific scoring weights, judgment windows, and disables some menu options
    ModsSRT = false,
    -- not currently implemented, but will contain settings related to FA+ events
    -- note that this is only for FA+ like events, and not for judgment tracking, which will be toggleable in normal ITG style
    FA = false,
}
_SL.CurrentGameStyle = 'ITG'

_SL.SetGameStyle = function(style)
    -- the lua state is weird, as it gets reset once before we reach any existing screen, while other singletons such as GAMESTATE and PREFSMAN exist when the first time this script is loaded, SCREENMAN does not, and only exists after the first lua state reset, so if this function is called within one of the files in this directory with an invalid style, we'll get a runtime error upon launching the game
    -- this won't cause problems for running the game as the second time the scripts are run we'll get to the proper error checking logic and report the invalid style, but lets give a clearer error for anyone trying change styles early, ie they want the game to launch in a sight-reading style
    if not SCREENMAN then
        error('SCREENMAN does not exist in the lua stack yet!\nThis should not occur unless _SL.SetGameStyle is called too early with a non existing Game Style\nDoublecheck for typos or ensure that "'.. tostring(style) ..'" is a string and a style that is defined in _SL.GameStyle', 2)
    end 
    
    -- ensure that the style being passed in is a string
    if type(style) ~= 'string' then SCREENMAN:SystemMessage('SetGameStyle: expected type "string", got "' .. type(style) .. '"') return end

    local currentstyle = _SL.CurrentGameStyle
    -- no point in doing anything if we aren't actually changing styles
    if style == currentstyle then return end

    local newstyle = _SL.GameStyle[style]
    -- check that the style we're trying to change to is valid
    if newstyle == nil then SCREENMAN:SystemMessage('SetGameStyle: "' .. style .. '" is not a valid Game Style') return end

    -- update the state of the current style to the new style
    _SL.GameStyle[currentstyle] = false
    _SL.GameStyle[style] = true
    _SL.CurrentGameStyle = style
    -- how do we deal with user set preferences that vary per player on normal gameplay, but need to be forced for specific styles
    -- update preferences in accordance to the new style 
    updatepreferencesfromstyle(style)
    print('Game Style set to "' .. style .. '"')
end

_SL.SetGameStyle'ModsSRT'

local function updatepreferencesfromstyle(style)
    -- todo remove if else chains to make expanding with new modes easier
    if style == 'ModsSRT' then
        local judgewindowadd = 0.0015
        GAMESTATE:SetSRT(1) -- hides general overlay stuff in gameplay
        -- uksrt score weights
        PREFSMAN:SetPreference('GradeWeightMarvelous',      5)
                :SetPreference('GradeWeightPerfect',        4)
                :SetPreference('GradeWeightGreat',          2)
                :SetPreference('GradeWeightGood',           0)
                :SetPreference('GradeWeightBoo',            -2)
                :SetPreference('GradeWeightMiss',           -4)
                :SetPreference('PercentScoreWeightHitMine', -8)
                :SetPreference('GradeWeightOK',             5)
                :SetPreference('GradeWeightNG',             0)

                -- bake in the judgewindowadd (0.0015) inside the judgments
                :SetPreference('JudgeWindowAdd',                0)
                :SetPreference('JudgeWindowScale',              1)
                :SetPreference('JudgeWindowSecondsMarvelous',   0.0215 + judgewindowadd)
                :SetPreference('JudgeWindowSecondsPerfect',     0.043 + judgewindowadd)
                :SetPreference('JudgeWindowSecondsGreat',       0.102 + judgewindowadd)
                :SetPreference('JudgeWindowSecondsGood',        0.135 + judgewindowadd)
                :SetPreference('JudgeWindowSecondsBoo',         0.18 + judgewindowadd)
                :SetPreference('JudgeWindowSecondsMine',        0.07 + judgewindowadd)
                :SetPreference('JudgeWindowSecondsOK',          0.32 + judgewindowadd)
                :SetPreference('JudgeWindowSecondsRoll',        0.35 + judgewindowadd)
                :SetPreference('JudgeWindowSecondsAttack',      0.13 + judgewindowadd)

                -- misc preferences
                :SetPreference('BGBrightness',                          0.7)
                :SetPreference('ComboContinuesBetweenSongs',            false)
                :SetPreference('DefaultModifiers',                      '2x, Overhead, scalable, FailOff')
                :SetPreference('MinPercentageForMachineSongHighScore',  0)
                -- depending on layout this could be set to 1, but it's better off to not assume and allow pad navigation
                :SetPreference('OnlyDedicatedMenuButtons',              false)
                :SetPreference('ShowDanger',                            false)
                :SetPreference('ShowNativeLanguage',                    true)
                :SetPreference('SmoothLines',                           true)
                :SetPreference('SoundDrivers',                          'WaveOut')
                :SetPreference('SoundResampleQuality',                  1)
                :SetPreference('AutoMapOnJoyChange',                    false)
                -- while no errors are nice, i'd like errors to be reported so things can actually be done about them so they don't occur at all
                :SetPreference('IgnoredMessageWindows',                 '')

                -- notitg specific
                :SetPreference('AlwaysShowUnknownModsWarning',      false)
                :SetPreference('DisplayEarlyRecalcJudgments',       true)
                :SetPreference('DisplayEarlyRecalcNoteFlashes',     true)
                :SetPreference('MinTNSToRecalcNote',                5)
                :SetPreference('ShowComboGlowAtPercent',            false)
                :SetPreference('ShowStageNumberOnGameplayScreen',   false)
                :SetPreference('InputDuplication',                  false)
    end

    if style == 'ITG' then
        GAMESTATE:SetSRT(0)
        PREFSMAN:SetPreference('PercentScoreWeightMarvelous',   5)
                :SetPreference('PercentScoreWeightPerfect',     4)
                :SetPreference('PercentScoreWeightGreat',       2)
                :SetPreference('PercentScoreWeightGood',        0)
                :SetPreference('PercentScoreWeightBoo',         -6)
                :SetPreference('PercentScoreWeightMiss',        -12)
                :SetPreference('PercentScoreWeightHitMine',     -6)
                :SetPreference('PercentScoreWeightOK',          5)
                :SetPreference('PercentScoreWeightNG',          0)

                :SetPreference('JudgeWindowAdd',                0)
                :SetPreference('JudgeWindowScale',              1)
                :SetPreference('JudgeWindowSecondsMarvelous',   0.0215)
                :SetPreference('JudgeWindowSecondsPerfect',     0.043)
                :SetPreference('JudgeWindowSecondsGreat',       0.102)
                :SetPreference('JudgeWindowSecondsGood',        0.135)
                :SetPreference('JudgeWindowSecondsBoo',         0.18)
                :SetPreference('JudgeWindowSecondsMine',        0.07)
                :SetPreference('JudgeWindowSecondsOK',          0.32)
                :SetPreference('JudgeWindowSecondsRoll',        0.35)
                :SetPreference('JudgeWindowSecondsAttack',      0.13)
        -- restore old player preferences, might need to use machine profile, or create themeprefs
        -- i'll leave this for later since there's more important things to touch
    end
end