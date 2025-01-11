function onDeath(cid, corpse, deathList)
	local redCrystalName = "Red Crystal"
	local blueCrystalName = "Blue Crystal"
	local name = getCreatureName(cid)
	if (name == redCrystalName) then
		CurrentCastle:blueWin()
		doBroadcastMessage("[ROTCastle]: O cristal do time vermelho foi destruído! O time azul é o vencedor!")
		end	
		if (name == blueCrystalName) then
			CurrentCastle:redWin()
			doBroadcastMessage("[ROTCastle]: O cristal do time azul foi destruído! O time vermelho é o vencedor!")
	end
    return true
end