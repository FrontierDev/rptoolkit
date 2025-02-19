local SpellFunctions = {}
_G.SpellFunctions = SpellFunctions

function SpellFunctions:Atonement()
	print("Atonement triggered.")
	local hitRoll = Dice.Roll("1d1", "Atonement", "WIS", false, "ALL")
end
