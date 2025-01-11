function onStatsChange(cid, attacker, changeType, combat, value)
	if (changeType == STATSCHANGE_HEALTHLOSS) then
		if (CurrentCastle:hasTurretAlive(getCreatureName(cid))) then
			doCreatureAddHealth(cid, -value / 2, true)
			return false
		end
	end
	return true
end