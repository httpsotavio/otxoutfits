function onDeath(cid, corpse, deathList)
	local redCrystalName = "Red Crystal"
	local blueCrystalName = "Blue Crystal"
	local name = getCreatureName(cid)
	if (name == redCrystalName) then
		CurrentCastle:blueWin()
	end	
	if (name == blueCrystalName) then
		CurrentCastle:redWin()
	end
    return true
end