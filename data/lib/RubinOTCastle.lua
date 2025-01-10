RCastle = {
	days = {"Saturday"},
	teleportPosition = {x = 94, y = 128, z = 7}, -- templo de thais (onde surge o teleporte pra ir pro lobby do evento)
	teleportDestination = {x = 23, y = 162, z = 7}, -- lobby

	duration = 60, -- minutos, duração geral do evento, 1 hr de duração
	lobbyTime = 10, -- minutos no lobby eseprando players
	minLevel = 100,
	minPlayers = 100,
	maxPlayers = 400,
	messages = {
		start = "[ROTCastle]: Começando o castelo. Teleport no templo.",
		redWin = "[ROTCastle]: O time vermelho ganhou.",
		blueWin = "[ROTCastle]: O time azul ganhou.",
		participationReward = "[ROTCastle]: Por ter participado do castelo você ganhou esse item ai que te dei."
	},
	
	enteringPositions = {
		blueTeam = {x=65, y=171, z=7},
		redTeam = {x=57, y=171, z=7},
	},
	crystals = {
		redTeamPosition = {x = 52, y = 150, z = 7},
		redTeamCrystalMonsterName = "Red Crystal",
		
		blueTeamPosition = {x = 90, y = 165, z = 7},
		blueTeamCrystalMonsterName = "Blue Crystal",
	},

	timeToOpenGates = 10, -- minutos
	gates = {
		redTeam = {
			positions = {
				{x = 56, y = 168, z = 7},
				{x = 57, y = 168, z = 7},
				{x = 58, y = 168, z = 7},
				{x = 59, y = 168, z = 7},
			},
		},		
		
		blueTeam = {
			positions = {
				{x = 64, y = 168, z = 7},
				{x = 65, y = 168, z = 7},
				{x = 66, y = 168, z = 7},
				{x = 67, y = 168, z = 7},
			},
		},
		
		gateID = 10042, -- itemid do portao

	},

	respawnAreas = {
		blueTeam = {x = 0, y = 0, z = 0},
		redTeam = {x = 0, y = 0, z = 0},
	},

	rewards = {
		participation = { -- premiação por participação, para todos os jogadores
			[2159] = 1,
			--[id] = quantidade,
		},

		winnerTeam = {
			-- [id] = {itemid = itemid, count = quantidade pro player},
			-- esses itens serão distgribuidos aleatóriamente para os jogadores do time ganhador
			[1] = {itemid = 2160, count = 1},
			[6] = {itemid = 2160, count = 1},
			[12] = {itemid = 2160, count = 1},
			[25] = {itemid = 2160, count = 1},
		}
	}
}

setmetatable(RCastle, {
	__call = function(self)
		local data = {
			startTime = 0,
			gatesQueueStartTime = 0,

			inLobby = false,
			waitingForOpenGates = false,

			players = {},
			blueTeam = {},
			redTeam = {},

		}
		return setmetatable(data, {__index = RCastle})
	end
})

CurrentCastle = RCastle()

function calcFee(level)
	if (level >= 1200) then return 5000000 end
	if (level >= 1000) then return 4000000 end
	if (level >= 600) then return 3000000 end
	if (level >= 400) then return 2000000 end
	return 0
end

function RCastle.openGates(self)
	for k, v in pairs(self.gates.redTeam.positions) do
		doRemoveItem(getTileItemById(v, self.gates.gateID).uid)
	end	
	for k, v in pairs(self.gates.blueTeam.positions) do
		doRemoveItem(getTileItemById(v, self.gates.gateID).uid)
	end
end

function RCastle.startCounting(self)
	self.startTime = os.time()
	self.inLobby = true
	self.closed = false
	doBroadcastMessage(self.messages.start)
	local tp = doCreateItemEx(4179)
	doTileAddItemEx(self.teleportPosition, tp)
	doItemSetAttribute(tp, "aid", 17714)

	self:periodicCheck()
end

function RCastle.addPlayer(self, cid)
	if (isPlayer(cid)) then
		if (getPlayerLevel(cid) < self.minLevel) then
			return false
		end
		local playerMoney = getPlayerMoney(cid)
		local fee = calcFee(getPlayerLevel(cid))
		if (playerMoney < fee) then
			return false
		end

		doPlayerRemoveMoney(cid, fee)
		table.insert(self.players, cid)
		return true
	end
end

function RCastle.start(self)
	self.inLobby = false
	local tp = getTileItemById(self.teleportPosition, 4179).uid
	doRemoveItem(tp)
	if (#self.players > 1) then
		self:sortTeams()

		for k, v in pairs(self.blueTeam) do
			doTeleportThing(v, self.enteringPositions.blueTeam)
			doPlayerSendTextMessage(v, MESSAGE_STATUS_CONSOLE_BLUE, "Você agora é do time azul!")
			
			local outfit = getCreatureOutfit(v)
			local blueColor = 88
			outfit.lookHead = blueColor
			outfit.lookBody = blueColor
			outfit.lookLegs = blueColor
			outfit.lookFeet = blueColor
			doCreatureChangeOutfit(v, outfit)
		end

		for k, v in pairs(self.redTeam) do
			doTeleportThing(v, self.enteringPositions.redTeam)
			doPlayerSendTextMessage(v, MESSAGE_STATUS_CONSOLE_BLUE, "Você agora é do time vermelho!")
			local outfit = getCreatureOutfit(v)
			local redColor = 94
			outfit.lookHead = redColor
			outfit.lookBody = redColor
			outfit.lookLegs = redColor
			outfit.lookFeet = redColor
			doCreatureChangeOutfit(v, outfit)
		end

		local blueCrystal = doCreateMonster(self.crystals.blueTeamCrystalMonsterName, self.crystals.blueTeamPosition)		
		local redCrystal = doCreateMonster(self.crystals.redTeamCrystalMonsterName, self.crystals.redTeamPosition)		
		registerCreatureEvent(blueCrystal, "RCastleCrystal")
		registerCreatureEvent(redCrystal, "RCastleCrystal")

		self.waitingForOpenGates = true
		self.gatesQueueStartTime = os.time()

		for k, v in pairs(self.players) do
			registerCreatureEvent(v, "RCastlePlayerDeath")
		end
	end
end

function RCastle.sortTeams(self)
	local levels = {}
	for _, cid in pairs(self.players) do
		table.insert(levels, {cid = cid, level = getPlayerLevel(cid)})
	end
	table.sort(levels, function(a, b) return a.level > b.level end)

	local med1, med2 = 0, 0
	local blueCount, redCount = 0, 0
	local maxTeamSize = math.ceil(#levels / 2)
	for k, v in pairs(levels) do
		if (med1 <= med2 and blueCount < maxTeamSize or redCount >= maxTeamSize) then
			table.insert(self.blueTeam, v.cid)
			med1 = med1 + v.level
			blueCount = blueCount + 1
		else
			table.insert(self.redTeam, v.cid)
			med2 = med2 + v.level
			redCount = redCount + 1
		end
	end
end

function RCastle.periodicCheck(self)
	if (self.closed) then
		return true
	end
	if (self.inLobby) then
		local lobbyTime = self.lobbyTime
		if (os.time() > lobbyTime + self.startTime) then
			self:start()
		end
	end
	if (self.waitingForOpenGates) then
		if (os.time() > self.gatesQueueStartTime + self.timeToOpenGates) then
			self:openGates()
			self.waitingForOpenGates = false
		end
	end
	addEvent(function()
		self:periodicCheck()
	end, 1000)
end

function RCastle.sendParticipationReward(self)
	for k, v in pairs(self.players) do
		if (isPlayer(v)) then
			for itemid, count in pairs(self.rewards.participation) do
				doPlayerAddItem(v, itemid, count)
				doPlayerSendTextMessage(v, MESSAGE_STATUS_CONSOLE_BLUE, self.messages.participationReward)
				doTeleportThing(v, self.teleportPosition)
			end
		end
	end
end

function RCastle.playerDeath(self, cid)
	if (self.blueTeam[cid]) then
		doTeleportThing(cid, self.respawnAreas.blueTeam)
	end
	if (self.redTeam[cid]) then
		doTeleportThing(cid, self.respawnAreas.redTeam)
	end
end

local removeTeamPlayer = function(cid, tab)
	for i, v in ipairs(tab) do
		if v == cid then
		  table.remove(tab, i)
		  break
		end
	  end
end

function RCastle.redWin(self)
	self.closed = true
	doBroadcastMessage(self.messages.redWin)
	self:sendParticipationReward()
	local redTeam = self.redTeam
	for count, tab in pairs(self.rewards.winnerTeam) do
		for i = 0, count do
			if (#redTeam <= 0) then break end
			local sortedPlayer = redTeam[math.random(1, #redTeam)]
			if (sortedPlayer > 0) then
				removeTeamPlayer(sortedPlayer, redTeam)
				doPlayerAddItem(sortedPlayer, tab.itemid, tab.count)
				local info = getItemInfo(tab.itemid)
				doPlayerSendTextMessage(sortedPlayer, MESSAGE_STATUS_CONSOLE_BLUE, "[ROTCastle]: Você ganhou "..tab.count.." "..info.name.." por ter ganhado o castle.")
			end
		end
	end
end         

function RCastle.blueWin(self)
	self.closed = true
	doBroadcastMessage(self.messages.blueWin)
	self:sendParticipationReward()
	local blueTeam = self.blueTeam
	for count, tab in pairs(self.rewards.winnerTeam) do
		for i = 0, count do
			if (#blueTeam <= 0) then break end
			local sortedPlayer = blueTeam[math.random(1, #blueTeam)]
			if (sortedPlayer > 0) then
				removeTeamPlayer(sortedPlayer, blueTeam)
				doPlayerAddItem(sortedPlayer, tab.itemid, tab.count)
				local info = getItemInfo(tab.itemid)
				doPlayerSendTextMessage(sortedPlayer, MESSAGE_STATUS_CONSOLE_BLUE, "[ROTCastle]: Você ganhou "..tab.count.." "..info.name.." por ter ganhado o castle.")
			end
		end
	end
end