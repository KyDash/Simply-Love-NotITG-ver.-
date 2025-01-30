local colorcache = {}

function _SL.HexToRGB(hexStr)
	if type(hexStr) ~= 'string' then print('_SL.HexToRGB did not receive a string!') return 1, 1, 1, 1 end
	if colorcache[hexStr] then local color = colorcache[hexStr] return color.r, color.g, color.b, color.a end
	local channels = {} string.gsub(hexStr, '%x%x', function(c) table.insert(channels, tonumber(c, 16)) return channels end)
	local r, g, b, a = channels[1] / 255, channels[2] / 255, channels[3] / 255, (channels[4] or 255) / 255
	colorcache[hexStr] = {r = r, g = g, b = b, a = a}
	return r, g, b, a
end

function PlayerColor( pn )
	if pn == PLAYER_1 then return _SL.DifficultyColor(3) end
	if pn == PLAYER_2 then return _SL.DifficultyColor(1) end
	return "_SL.HexToRGB(_SL.Colors.White)"
end

-- names taken from https://colordesigner.io/color-name-finder
-- common colours that do not change depending on initial color selection
-- names may overlap when colours are close together
_SL.Colors = {
	White		=	"#FFFFFF",
	Black		=	"#000000",
	Red			=	"#ED1C24",
	Blue		=	"#00AEEF",
	Green		=	"#39B54A",
	Yellow		=	"#FFF200",
	Orange		=	"#F7941D",
	Purple		=	"#92278F",
	Outline		=	"#00000080",
	Invisible	=	"#FFFFFF00",
	Stealth		=	"#00000000",

	-- Android Design Stencil Colors
	-- https://m3.material.io/styles/color/system/overview
	HoloBlue		=	"#33B5E5",
	HoloDarkBlue	=	"#0099CC",
	HoloPurple		=	"#AA66CC",
	HoloDarkPurple	=	"#9933CC",
	HoloGreen		=	"#99CC00",
	HoloDarkGreen	=	"#669900",
	HoloOrange		=	"#FFBB33",
	HoloDarkOrange	=	"#FF8800",
	HoloRed			=	"#FF4444",
	HoloDarkRed		=	"#CC0000",

	-- consistent colours used within the theme
	UIMain	=	"#1E282F",	-- Main color of quads used around the theme
	-- UISection	=	"#293338", --
	UIDark	=	"#101519",	-- Darker, secondary color of quads used around the theme
	UIPlot	=	"#565E6380",	-- An even darker color, used for the scatterplot
	Edit	= 	"#B4B7BA",	-- Silver
	W1		= 	"#21CCE8",	-- Dark Turquoise
	W2		= 	"#E29C18",	-- Golden Rod
	W3		= 	"#66C955",	-- Light Green
	W4		= 	"#A272D5",	-- Medium Purple
	W5		= 	"#C9855E",	-- Dark Salmon
	W6		= 	"#FF3030",	-- Red
}
-- aliases
_SL.Colors.TNS_W1 = _SL.Colors.W1
_SL.Colors.TNS_W2 = _SL.Colors.W2
_SL.Colors.TNS_W3 = _SL.Colors.W3
_SL.Colors.TNS_W4 = _SL.Colors.W4
_SL.Colors.TNS_W5 = _SL.Colors.W5
_SL.Colors.TNS_W6 = _SL.Colors.W6
_SL.Colors.TNS_Miss = _SL.Colors.W6

-- colours that the theme will use, either for text on dark backgrounds or background featuring dark text
-- see https://github.com/Simply-Love/Simply-Love-SM5/commit/d7192907c9dd96498738a12dbd6abd8d43bf6af5
_SL.Colors.Theme = {
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
_SL.Colors.Decorative = {
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

function _SL.DefaultColor()
	local color = _SL.Color()
	if color > 9 then return color end
	return '0'.. color
end
	
function _SL.Color(c)
	if not Profile(0) then return 1 end
	if not Profile(0).Love then Profile(0).Love = { Color = 1 } end
	if c then Profile(0).Love.Color = c end
	return Profile(0).Love and Profile(0).Love.Color or 1
end

function _SL.DifficultyColor( dc, decorative )
	if dc == DIFFICULTY_EDIT then return _SL.Colors.Edit end
	local colorIndex = dc + _SL.Color() + 10
	colorIndex = math.mod(colorIndex-1,12)+1
	local colorTable = decorative and _SL.Colors.Decorative or _SL.Colors.Theme
	if colorTable[colorIndex] then return colorTable[colorIndex] end
	return _SL.Colors.White
end

function _SL.BubbleColorRGB ( pn, decorative )
	if GAMESTATE:IsPlayerEnabled( pn ) then
		local steps = GAMESTATE:GetCurrentSteps( pn )
		if not steps then return 1,1,1,0 end
		steps = steps:GetDifficulty()
		if steps == DIFFICULTY_EDIT	then return _SL.HexToRGB(_SL.Colors.Edit) end
		return _SL.ColorRGB(steps-2, decorative)
	end
	return _SL.HexToRGB(_SL.Colors.White)
end

function _SL.DifficultyColorRGB( n, decorative )
	if n < 5 then
		return _SL.ColorRGB( n - 2, decorative )
	else
		return _SL.HexToRGB(_SL.Colors.Edit)
	end
end

function _SL.ColorRGB( n, decorative )
	local colorIndex = n + _SL.Color() + 12
	colorIndex = math.mod(colorIndex-1,12)+1
	local colorTable = decorative and _SL.Colors.Decorative or _SL.Colors.Theme
	if colorTable[colorIndex] then return _SL.HexToRGB(colorTable[colorIndex]) end
	return _SL.HexToRGB(_SL.Colors.White)
end

-- Get a color to show text on top of difficulty frames.
function _SL.ContrastingDifficultyColor( dc )
	if dc == DIFFICULTY_BEGINNER	then return _SL.Colors.Black end
	if dc == DIFFICULTY_EASY		then return _SL.Colors.Black end
	if dc == DIFFICULTY_MEDIUM		then return _SL.Colors.Black end
	if dc == DIFFICULTY_HARD		then return _SL.Colors.Black end
	if dc == DIFFICULTY_CHALLENGE	then return _SL.Colors.Black end
	if dc == DIFFICULTY_EDIT		then return _SL.Colors.Black end
	return _SL.Colors.White
end

function _SL.TextOnColor(n, decorative)
	if not decorative then return _SL.HexToRGB(_SL.Colors.Black) end
	local colorIndex = _SL.Color() + 12
	if n then colorIndex = colorIndex + n end
	colorIndex = math.mod(colorIndex-1,12)+1
	if colorIndex >= 9 then return _SL.HexToRGB(_SL.Colors.Black) end
	return _SL.HexToRGB(_SL.Colors.White)
end

function _SL.BubbleColorText( pn, decorative )
	if not decorative then return _SL.HexToRGB(_SL.Colors.Black) end
	if GAMESTATE:IsPlayerEnabled( pn ) then
		local steps = GAMESTATE:GetCurrentSteps( pn )
		if not steps then return _SL.HexToRGB('#FFFFFF00') end
		steps = steps:GetDifficulty()
		if steps == DIFFICULTY_EDIT	then return _SL.HexToRGB(_SL.Colors.Black) end
		local colorIndex = _SL.Color() + 10 + steps
		colorIndex = math.mod(colorIndex-1,12)+1
		-- if colorIndex >= 9 then return _SL.HexToRGB('#333D42') end
		if colorIndex >= 9 then return _SL.HexToRGB(_SL.Colors.Black) end
	end
	return _SL.HexToRGB(_SL.Colors.White)
end
