function onStepIn(cid, item, position, fromPosition)
	local status = CurrentCastle:addPlayer(cid)
	if (not status) then
		addEvent(doTeleportThing, 1, cid, fromPosition, true)
		return false
	end

	doTeleportThing(cid, RCastle.teleportDestination)
	return true
end
