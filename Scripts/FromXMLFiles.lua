-- unsure to what this is specifically for since it's obfuscated, but moving this here to avoid weird race conditions when a screen is skipped - Ky
Command = {}
function file()
	if children then
		File=children[math.mod(table.getn(Command),table.getn(children))+1]
	end
end