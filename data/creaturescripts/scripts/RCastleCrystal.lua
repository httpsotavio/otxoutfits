function onDeath(cid, corpse, deathList)
	local redCrystalName = "Red Crystal"
	local blueCrystalName = "Blue Crystal"
	local name = getCreatureName(cid)
	if (name == redCrystalName) then
		CurrentCastle:blueWin()
		doBroadcastMessage("[ROTCastle]: O cristal do time vermelho foi destru�do! O time azul � o vencedor!")
		end	
		if (name == blueCrystalName) then
			CurrentCastle:redWin()
			doBroadcastMessage("[ROTCastle]: O cristal do time azul foi destru�do! O time vermelho � o vencedor!")
	end
    return true
end