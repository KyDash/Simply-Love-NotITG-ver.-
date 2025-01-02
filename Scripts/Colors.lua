function PlayerColor( pn )
	if pn == PLAYER_1 then return DifficultyColor(3) end
	if pn == PLAYER_2 then return DifficultyColor(1) end
	return "HexToRGB(GlobalColors.White)"
end

function DefaultColor()
	if Color() > 9 then return Color() end
	return '0'..Color()
end
	
function Color(c)
	if not Profile(0) then return 1 end
	if not Profile(0).Love then Profile(0).Love = { Color = 1 } end
	if c then Profile(0).Love.Color = c end
	return Profile(0).Love and Profile(0).Love.Color or 1
end

function FeetPosition()
	y = 13 + 120 - 120*Color()
	return y
end

function IconY()
	y = 260 - 40*Color()
	return y
end

function IconCrop(self)
	self:croptop((Color()-1)/12)
	self:cropbottom(1-Color()/12)
end

local function HexToRGB(hexStr)
	if type(hexStr) ~= 'string' then return 1, 1, 1, 1 end
	local channels = {} string.gsub(hexStr, '%x%x', function(c) table.insert(channels, tonumber(c, 16)) return channels end)
	return channels[1] / 255, channels[2] / 255, channels[3] / 255, (channels[4] or 255) / 255
end

-- names taken from https://colordesigner.io/color-name-finder
-- common colours that do not change depending on initial color selection
local GlobalColors = {
	Edit = "#B4B7BA", -- Silver
	White = "#FFFFFF", -- White
	Black = "#000000", -- Black
}

-- colours that the theme will use, either for text on dark backgrounds or background featuring dark text
-- see https://github.com/Simply-Love/Simply-Love-SM5/commit/d7192907c9dd96498738a12dbd6abd8d43bf6af5
local Colors = {
	"#FF7D00", -- Dark Orange
	"#FF5D47", -- Tomato
	"#FF577E", -- Indian Red
	"#FF47B3", -- Deep Pink
	"#DD57FF", -- Dark Orchid
	"#8885ff", -- Medium Purple
	"#3D94FF", -- Dodger Blue
	"#00B8CC", -- Dark Turquoise
	"#5CE087", -- Light Green
	"#AEFA44", -- Green Yellow
	"#FFFF00", -- Yellow
	"#FFBE00", -- Gold
}

-- coloured background elements that do not feature text
-- original colours used by Simply Love
local DecorativeColors = {
	"#FF7D00", -- Dark Orange
	"#FF3C23", -- Orange Red
	"#FF003C", -- Crimson
	"#C1006F", -- Medium Violet Red
	"#8200A1", -- Dark Orchid
	"#413AD0", -- Medium Slate Blue
	"#0073FF", -- Royal Blue
	"#00ADC0", -- Dark Turquoise
	"#5CE087", -- Light Green
	"#AEFA44", -- Green Yellow
	"#FFFF00", -- Yellow
	"#FFBE00", -- Gold
}

function DifficultyColor( dc, decorative )
	if dc == DIFFICULTY_EDIT then return GlobalColors.Edit end
	local colorIndex = dc + Color() + 10
	colorIndex = math.mod(colorIndex-1,12)+1
	local colorTable = decorative and DecorativeColors or Colors
	if colorTable[colorIndex] then return colorTable[colorIndex] end
	return GlobalColors.White
end

function BubbleColorRGB ( pn, decorative )
	if GAMESTATE:IsPlayerEnabled( pn ) then
		local steps = GAMESTATE:GetCurrentSteps( pn )
		if not steps then return 1,1,1,0 end
		steps = steps:GetDifficulty()
		if steps == DIFFICULTY_EDIT	then return HexToRGB(GlobalColors.Edit) end
		return ColorRGB(steps-2, decorative)
	end
	return HexToRGB(GlobalColors.White)
end

function DifficultyColorRGB( n, decorative )
	if n < 5 then
		return ColorRGB( n - 2, decorative )
	else
		return HexToRGB(GlobalColors.Edit)
	end
end

function ColorRGB ( n, decorative )
	local colorIndex = n + Color() + 12
	colorIndex = math.mod(colorIndex-1,12)+1
	local colorTable = decorative and DecorativeColors or Colors
	if colorTable[colorIndex] then return HexToRGB(colorTable[colorIndex]) end
	return HexToRGB(GlobalColors.White)
end

-- Get a color to show text on top of difficulty frames.
function ContrastingDifficultyColor( dc )
	if dc == DIFFICULTY_BEGINNER	then return GlobalColors.Black end
	if dc == DIFFICULTY_EASY		then return GlobalColors.Black end
	if dc == DIFFICULTY_MEDIUM		then return GlobalColors.Black end
	if dc == DIFFICULTY_HARD		then return GlobalColors.Black end
	if dc == DIFFICULTY_CHALLENGE	then return GlobalColors.Black end
	if dc == DIFFICULTY_EDIT		then return GlobalColors.Black end
	return GlobalColors.White
end

function TextOnColor (n, decorative)
	if not decorative then return HexToRGB(GlobalColors.Black) end
	local colorIndex = Color() + 12
	if n then colorIndex = colorIndex + n end
	colorIndex = math.mod(colorIndex-1,12)+1
	if colorIndex >= 9 then return HexToRGB(GlobalColors.Black) end
	return HexToRGB(GlobalColors.White)
end

function BubbleColorText ( pn, decorative )
	if not decorative then return HexToRGB(GlobalColors.Black) end
	if GAMESTATE:IsPlayerEnabled( pn ) then
		local steps = GAMESTATE:GetCurrentSteps( pn )
		if not steps then return HexToRGB('#FFFFFF00') end
		steps = steps:GetDifficulty()
		if steps == DIFFICULTY_EDIT	then return HexToRGB(GlobalColors.Black) end
		local colorIndex = Color() + 10 + steps
		colorIndex = math.mod(colorIndex-1,12)+1
		-- if colorIndex >= 9 then return HexToRGB('#333D42') end
		if colorIndex >= 9 then return HexToRGB(GlobalColors.Black) end
	end
	return HexToRGB(GlobalColors.White)
end
