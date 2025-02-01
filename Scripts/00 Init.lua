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

local istournament = true
if istournament then
    local judgewindowadd = 0.0015
    GAMESTATE:SetSRT(1) -- hides general overlay stuff in gameplay
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

            -- notitg specific
            :SetPreference('AlwaysShowUnknownModsWarning',      0)
            :SetPreference('DisplayEarlyRecalcJudgments',       true)
            :SetPreference('DisplayEarlyRecalcNoteFlashes',     true)
            :SetPreference('MinTNSToRecalcNote',                5)
            :SetPreference('ShowComboGlowAtPercent',            false)
            :SetPreference('ShowStageNumberOnGameplayScreen',   false)
            :SetPreference('InputDuplication',                  false)
end

if defaults then
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
end