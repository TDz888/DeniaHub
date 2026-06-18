-- DeniaHub.lua v3.1 — Blox Fruits Script
-- All methods follow Redz Hub patterns (discord.gg/25ms)

-- ==================== LOADER ====================
local DeniaLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/TDz888/DeniaHub/main/DeniaLib.lua"))()

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local CurrentCamera = workspace.CurrentCamera
local Stepped = RunService.Stepped

local lp = Players.LocalPlayer
local _Data = lp:WaitForChild("Data")
_Data:WaitForChild("LastSpawnPoint")
_Data:WaitForChild("SpawnPoint")
local _Level = _Data:WaitForChild("Level")
local _Beli = _Data:WaitForChild("Beli")
local _Fragments = _Data:WaitForChild("Fragments")
local _FruitCap = _Data:WaitForChild("FruitCap")

-- Redz standard: WaitForChild on workspace folders (safe lookups)
local _Map = workspace:FindFirstChild("Map")
local _Enemies = workspace:FindFirstChild("Enemies")
local _NPCs = workspace:FindFirstChild("NPCs")
local _Characters = workspace:FindFirstChild("Characters")
local _SeaBeasts = workspace:FindFirstChild("SeaBeasts")
local _Boats = workspace:FindFirstChild("Boats")
local _WorldOrigin = workspace:FindFirstChild("_WorldOrigin")
local _Locations = _WorldOrigin and _WorldOrigin:FindFirstChild("Locations")

local _Remotes = ReplicatedStorage:WaitForChild("Remotes")
local _CommF = _Remotes:WaitForChild("CommF_")
local _CommE = _Remotes:WaitForChild("CommE")
local _Modules = ReplicatedStorage:WaitForChild("Modules")
local _Net = _Modules:WaitForChild("Net")
local _PlayerGui = lp:WaitForChild("PlayerGui")
local function getQuestGui()
	local main = _PlayerGui:FindFirstChild("Main")
	if not main then return nil, nil end
	local q = main:FindFirstChild("Quest")
	if not q then return nil, nil end
	local title = q.Container and q.Container.QuestTitle and q.Container.QuestTitle.Title
	return q, title
end

-- PlaceIds
local FIRST_SEA = 2753915549
local SECOND_SEA = 4442272183
local THIRD_SEA = 7449423635

-- ==================== REDZ UTILITIES ====================
local function getChar() return lp.Character end
local function getRoot()
	local char = getChar()
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end
local function getHumanoid()
	local char = getChar()
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end
local function isAlive(character)
	return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
end
local function waitForChar()
	if lp.Character then return lp.Character end
	return lp.CharacterAdded:Wait()
end

-- Redz: FireRemote through CommF_
local function fireRemote(name, ...)
	local ok = pcall(function() _CommF:InvokeServer(name, ...) end)
	return ok
end

-- Redz: VerifyTool checks backpack and character
local function verifyTool(name)
	for _, v in ipairs(lp.Backpack:GetChildren()) do
		if v.Name == name then return true end
	end
	local char = getChar()
	if char then
		for _, v in ipairs(char:GetChildren()) do
			if v.Name == name then return true end
		end
	end
	return false
end

-- Redz: VerifyToolTip checks weapon category
local function verifyToolTip(tip)
	local char = getChar()
	if not char then return false end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return tip == "Melee" end
	return tool.ToolTip == tip
end

-- Redz: EnableBuso with haki & observation
local AttackCooldown = 0

local function EnableBuso()
	local char = getChar()
	if not char then return end
	if not char:FindFirstChild("HasBuso") then
		fireRemote("Buso")
	end
	pcall(function()
		local stun = char:FindFirstChild("Stun")
		if stun then stun.Value = 0 end
		local busy = char:FindFirstChild("Busy")
		if busy then busy.Value = false end
	end)
	if _CommE then
		_CommE:FireServer("Ken", true)
	end
end

-- Redz: Simulation radius
local function setSimRadius()
	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(lp, "SimulationRadius", math.huge)
		end
	end)
end

-- ==================== REDZ: SERVER HOP (Mahub style) ====================
local serverHopActive = false
local function serverHop()
	if serverHopActive then return end
	serverHopActive = true
	local placeId = game.PlaceId
	local visitedServers = {}
	local nextPageCursor = ""

	local function fetchServers(cursor)
		local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
		if cursor and cursor ~= "" then
			url = url .. "&cursor=" .. cursor
		end
		local success, data = pcall(function()
			return HttpService:JSONDecode(game:HttpGetAsync(url))
		end)
		if success and data then
			return data
		end
		return nil
	end

	local function tryHop()
		local data = fetchServers(nextPageCursor)
		if not data then return end
		if data.nextPageCursor and data.nextPageCursor ~= "null" then
			nextPageCursor = data.nextPageCursor
		end
		for _, server in ipairs(data.data) do
			if server.playing < server.maxPlayers then
				local alreadyVisited = false
				for _, id in ipairs(visitedServers) do
					if tostring(server.id) == tostring(id) then alreadyVisited = true; break end
				end
				if not alreadyVisited then
					table.insert(visitedServers, tostring(server.id))
					task.wait(0.1)
					TeleportService:TeleportToPlaceInstance(placeId, server.id, lp)
					return true
				end
			end
		end
		return false
	end

	task.spawn(function()
		local attempts = 0
		while attempts < 30 do
			attempts = attempts + 1
			task.wait(1)
			local success, found = pcall(tryHop)
			if success and found then break end
		end
		serverHopActive = false
	end)
end

-- ==================== REDZ: CHECK ITEM (Mahub style) ====================
local function checkItem(itemName)
	local success, inv = pcall(function()
		return _CommF:InvokeServer("getInventory")
	end)
	if not success or type(inv) ~= "table" then return nil end
	for _, item in ipairs(inv) do
		if type(item) == "table" and item.Name == itemName then return item end
	end
	return nil
end

-- ==================== REDZ: AUTO TEAM SELECT (Mahub style) ====================
local function autoSelectTeam(teamName)
	if lp:FindFirstChild("Main") then return end
	teamName = teamName or "Pirates"
	local chooseTeam = _PlayerGui:FindFirstChild("Main (minimal)")
	if chooseTeam then
		local cs = chooseTeam:FindFirstChild("ChooseTeam")
		if cs and cs.Container then
			local btn = cs.Container:FindFirstChild(teamName)
			if btn and btn.Frame and btn.Frame.TextButton then
				pcall(function()
					local connections = getconnections(btn.Frame.TextButton.Activated)
					for _, con in ipairs(connections) do
						task.spawn(function() con.Function() end)
					end
				end)
			end
		end
	end
end

-- ==================== REDZ TWEEN MODULE (u104 equivalent) ====================
local activeTweens = {}

local function newTween(obj, time, prop, value)
	-- Cancel any existing tween on this object
	if activeTweens[obj] then
		pcall(function()
			activeTweens[obj]:Pause()
			activeTweens[obj]:Destroy()
		end)
		activeTweens[obj] = nil
	end

	local tween = TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Linear), { [prop] = value })
	tween.Completed:Connect(function()
		if activeTweens[obj] == tween then activeTweens[obj] = nil end
	end)
	tween:Play()
	activeTweens[obj] = tween
	return tween
end

local function stopTween(obj)
	if activeTweens[obj] then
		pcall(function()
			activeTweens[obj]:Pause()
			activeTweens[obj]:Destroy()
		end)
		activeTweens[obj] = nil
	end
end

-- ==================== REDZ PLAYER TELEPORT (u83 equivalent) ====================
local PlayerTeleport = {
	lastCF = nil,
	lastTP = 0,
	nextNum = 1,
	BypassCooldown = 0,
	SpawnVector = Vector3.new(0, -25.2, 0),
}

-- Sea-specific portal locations (Redz style)
local PortalLocations = {
	[1] = {
		["Sky Island 1"] = Vector3.new(-4652, 873, -1754),
		["Sky Island 2"] = Vector3.new(-7895, 5547, -380),
	},
	[2] = {
		["Flamingo Mansion"] = Vector3.new(-317, 331, 597),
		["Flamingo Room"] = Vector3.new(2283, 15, 867),
		["Cursed Ship"] = Vector3.new(923, 125, 32853),
		["Zombie Island"] = Vector3.new(-6509, 83, -133),
	},
	[3] = {
		Mansion = Vector3.new(-12464, 376, -7566),
		["Hydra Island"] = Vector3.new(5651, 1015, -350),
		["Temple of Time"] = Vector3.new(28286, 14897, 103),
		["Sea Castle"] = Vector3.new(-5090, 319, -3146),
		["Great Tree"] = Vector3.new(2953, 2282, -7217),
	},
}

local function getCurrentSea()
	if game.PlaceId == FIRST_SEA then return 1
	elseif game.PlaceId == SECOND_SEA then return 2
	elseif game.PlaceId == THIRD_SEA then return 3
	end
	return 1
end

local function getNearestPortal(pos)
	local sea = getCurrentSea()
	local portals = PortalLocations[sea]
	if not portals then return nil, nil end
	local huge = math.huge
	local nearestPos = nil
	local nearestName = nil
	for name, vpos in pairs(portals) do
		local mag = (pos - vpos).Magnitude
		if mag < huge then
			huge = mag
			nearestPos = vpos
			nearestName = name
		end
	end
	return nearestPos, nearestName
end

-- Redz: PlayerTeleport.new() - main teleport function (u83)
local function teleportTo(cframe, speed, bypassPortal)
	if not isAlive(getChar()) then return end
	local root = getRoot()
	if not root then return end
	if tick() - PlayerTeleport.lastTP < 1 and cframe == PlayerTeleport.lastCF then return end

	PlayerTeleport.lastCF = cframe
	PlayerTeleport.lastTP = tick()

	local hum = getHumanoid()
	if hum and hum.Sit then
		hum.Sit = false
		return
	end
	if root.Anchored then
		stopTween(root)
		return
	end

	local speed2 = 220
	local targetPos = cframe.Position
	local currentPos = root.Position
	local dist = (currentPos - targetPos).Magnitude

	if dist < 150 and not bypassPortal then
		stopTween(root)
		root.CFrame = cframe
		return
	end

	local portalPos, portalName = getNearestPortal(targetPos)
	local portalDist = portalPos and (targetPos - portalPos).Magnitude + 300 or nil

	if portalPos and tick() - PlayerTeleport.BypassCooldown >= 8 and portalDist and portalDist < dist then
		if portalName == "Great Tree" then
			teleportTo(CFrame.new(28610, 14897, 105), nil, true)
			task.wait(0.5)
			pcall(function() _CommF:InvokeServer("RaceV4Progress", "TeleportBack") end)
		else
			stopTween(root)
			task.wait(0.2)
			local teleportPos = portalPos
			if (targetPos - portalPos).Magnitude >= 50 then
				teleportPos = portalPos + (targetPos - currentPos).Unit * 40
			end
			fireRemote("requestEntrance", teleportPos)
			PlayerTeleport.BypassCooldown = tick()
		end
	elseif bypassPortal then
		newTween(root, dist / speed2, "CFrame", cframe)
	else
		if dist < 380 then
			newTween(root, dist / (speed2 * 2), "CFrame", cframe)
		else
			newTween(root, dist / speed2, "CFrame", cframe)
		end
	end
end

u83 = teleportTo

-- ==================== REDZ COMBAT SYSTEM ====================
local CombatController = nil
local RigController = nil
local combatInitialized = false

-- Redz: init CombatFramework controller
local function initCombat()
	if combatInitialized then return end
	pcall(function()
		local plrScripts = lp:WaitForChild("PlayerScripts")
		local cf = plrScripts:WaitForChild("CombatFramework")
		local cfModule = require(cf)
		local upvalues = getupvalues(cfModule)
		for i = 1, #upvalues do
			if type(upvalues[i]) == "table" then
				local tbl = upvalues[i]
				if tbl.activeController then
					CombatController = tbl.activeController
					CombatController.hitboxMagnitude = 250
				end
				if tbl.RigController then
					RigController = tbl.RigController
				end
				if tbl.controller then
					CombatController = CombatController or tbl.controller
				end
			end
			if CombatController and RigController then break end
		end
		combatInitialized = true
	end)
end

-- Redz: Hooking:SetTarget equivalent
local function hookTarget(part, model, enable)
	if not CombatController then return end
	if tick() - AttackCooldown < 0.15 then return end
	AttackCooldown = tick()
	pcall(function()
		CombatController.hitboxMagnitude = 250
		CombatController.timeToNextBlock = 0
		CombatController.timeToNextAttack = 0
		CombatController.attacking = false
		CombatController:attack()
	end)
end

-- Redz: KillAura equivalent
local function KillAura(range)
	local root = getRoot()
	if not root or not _Enemies then return false end
	local hit = false
	for _, e in ipairs(_Enemies:GetChildren()) do
		local hrp = e:FindFirstChild("HumanoidRootPart")
		local hum = e:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			if (hrp.Position - root.Position).Magnitude <= (range or 125) then
				hookTarget(hrp, e, true)
				hit = true
			end
		end
	end
	return hit
end

-- Redz: UseSkills equivalent
local function useSkills(targetPart, skills)
	if not CombatController or not targetPart then return end
	EnableBuso()
	equipTool()
	pcall(function()
		hookTarget(targetPart, targetPart.Parent, true)
		if skills then
			for _, skill in ipairs(skills) do
				pcall(function()
					_CommF:InvokeServer("Skill", skill, targetPart.Position)
				end)
			end
		end
	end)
end

-- Redz: Fast attack with cooldown
local function fastAttack(override)
	if not fastAttackEnabled and not override then return end
	if tick() - AttackCooldown < 0.12 then return end
	AttackCooldown = tick()
	pcall(function()
		if CombatController then
			CombatController.hitboxMagnitude = 250
			CombatController.timeToNextBlock = 0
			CombatController.timeToNextAttack = 0
			CombatController.attacking = false
			task.spawn(function()
				pcall(function() CombatController:attack() end)
			end)
		end
		task.spawn(function()
			pcall(function()
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
				task.wait()
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
			end)
		end)
		setSimRadius()
	end)
end

-- Redz: Animation speed hack (wrapAttackAnimationAsync)
local function initAnimationHack()
	pcall(function()
		local plrScripts = lp:WaitForChild("PlayerScripts")
		local cf = plrScripts:WaitForChild("CombatFramework")
		local RigLib = cf:FindFirstChild("RigLib")
		if RigLib then
			local rigModule = require(RigLib)
			if rigModule and rigModule.wrapAttackAnimationAsync then
				rigModule.wrapAttackAnimationAsync = function(self, animId, length, blend, callback)
					local hits = rigModule.getBladeHits and rigModule.getBladeHits(animId, length, blend) or {}
					self:Play(1.0E-5, 1.0E-5, 1.0E-5)
					if callback then callback(hits) end
				end
			end
		end
		local Particle = cf:FindFirstChild("Particle")
		if Particle then
			local pModule = require(Particle)
			if pModule then pModule.play = function() return end end
		end
		local CameraShaker = cf:FindFirstChild("CameraShaker")
		if CameraShaker then
			local csModule = require(CameraShaker)
			if csModule and csModule.CameraShakeInstance then
				csModule.CameraShakeInstance.CameraShakeState = {
					FadingIn = 3, FadingOut = 2, Sustained = 0, Inactive = 1
				}
			end
		end
	end)
end

-- ==================== REDZ EQUIP TOOL ====================
local nextToolCycle = {
	Melee = "Blox Fruit",
	["Blox Fruit"] = "Sword",
	Sword = "Gun",
	Gun = "Melee",
}
local oldToolName = "Melee"

-- Redz: EquipTool with auto-cycle
local function equipTool(toolName)
	pcall(function()
		if not toolName then
			-- Auto-select: try Melee first, then cycle
			if verifyToolTip("Melee") then
				toolName = oldToolName
			else
				local v = nextToolCycle[oldToolName]
				local attempts = 0
				while not verifyToolTip(v) and attempts < 4 do
					v = nextToolCycle[v]
					attempts = attempts + 1
				end
				toolName = v
			end
		end
		if not toolName then toolName = "Melee" end
		oldToolName = toolName

		local char = getChar()
		if not char then return end
		-- Move from character to backpack if already equipped
		local equipped = char:FindFirstChildOfClass("Tool")
		if equipped and equipped.Name ~= toolName then
			equipped.Parent = lp.Backpack
			task.wait(0.05)
		end
		-- Equip from backpack
		local bpTool = lp.Backpack:FindFirstChild(toolName)
		if bpTool then
			bpTool.Parent = char
			task.wait(0.05)
		end
	end)
end

-- ==================== REDZ FARM MODES ====================
local FarmMode = "Up"
local axisDebounce = 0
local nextAxis = Vector3.new(0, 15, 0)
local orbitAngle = 0

local FarmModes = {
	Star = function(root, enemyCF)
		if tick() - axisDebounce >= 0.4 then
			local dir = Vector3.new(math.random() <= 0.5 and 15 or -15, 8, math.random() <= 0.5 and 15 or -15)
			nextAxis = dir
			axisDebounce = tick()
		end
		local targetPos = enemyCF.Position + nextAxis
		if root and (root.Position - targetPos).Magnitude >= 5 then
			teleportTo(CFrame.new(targetPos))
		end
	end,
	Orbit = function(root, enemyCF)
		orbitAngle = orbitAngle + 3.5
		local dist = 15
		local targetPos = enemyCF.Position + Vector3.new(math.cos(orbitAngle) * dist, 8, math.sin(orbitAngle) * dist)
		teleportTo(CFrame.new(targetPos))
	end,
	Up = function(root, enemyCF)
		local targetPos = enemyCF.Position + Vector3.new(0, 15, 0)
		if root and (root.Position - targetPos).Magnitude >= 5 then
			teleportTo(CFrame.new(targetPos))
		end
	end,
}

-- ==================== REDZ BRING ENEMIES ====================
local function bringEnemies(model, useAttach)
	if not bringingMobs then return end
	local root = getRoot()
	if not root or not _Enemies then return end
	local enemiesList = {}
	if model then
		if type(model) == "table" then
			enemiesList = model
		else
			table.insert(enemiesList, model)
		end
	else
		enemiesList = _Enemies:GetChildren()
	end
	for _, e in ipairs(enemiesList) do
		local hrp = e:FindFirstChild("HumanoidRootPart")
		local hum = e:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local dist = (hrp.Position - root.Position).Magnitude
			if dist <= (bringRange or 200) and dist > 3 then
				pcall(function()
					hrp.CanCollide = false
					hum.WalkSpeed = 0
					hum.JumpPower = 0
					local anim = hum:FindFirstChildOfClass("Animator")
					if anim then anim:Destroy() end
					local bv = hrp:FindFirstChild("BV")
					if not bv then
						bv = Instance.new("BodyVelocity")
						bv.Name = "BV"
						bv.MaxForce = Vector3.new(100000, 100000, 100000)
						bv.Parent = hrp
					end
					local dir = (root.Position - hrp.Position).Unit * 150
					bv.Velocity = Vector3.new(dir.X, 0, dir.Z)
				end)
			end
		end
	end
end

-- ==================== REDZ QUEST SYSTEM ====================
local QuestData = {
	[1]={Name="Bandit",Lvl=1,NPC="BanditQuest1",Quest="BanditQuest1",Mob="Bandit",Pos=CFrame.new(1061,16,1428),MPos=CFrame.new(1045,27,1560)},
	[2]={Name="Monkey",Lvl=15,NPC="JungleQuest",Quest="JungleQuest",Mob="Monkey",Pos=CFrame.new(-1604,36,154),MPos=CFrame.new(-1598,36,191)},
	[3]={Name="Gorilla",Lvl=30,NPC="JungleQuest",Quest="JungleQuest",Mob="Gorilla",Pos=CFrame.new(-1604,36,154),MPos=CFrame.new(-1432,36,-31)},
	[4]={Name="Pirate",Lvl=60,NPC="BuggyQuest1",Quest="BuggyQuest1",Mob="Pirate",Pos=CFrame.new(-1141,5,3831),MPos=CFrame.new(-1195,5,3887)},
	[5]={Name="Brute",Lvl=100,NPC="BuggyQuest1",Quest="BuggyQuest1",Mob="Brute",Pos=CFrame.new(-1141,5,3831),MPos=CFrame.new(-1146,5,3976)},
	[6]={Name="Desert Bandit",Lvl=120,NPC="DesertQuest",Quest="DesertQuest",Mob="Desert Bandit",Pos=CFrame.new(927,6,4177),MPos=CFrame.new(924,5,4336)},
	[7]={Name="Desert Officer",Lvl=150,NPC="DesertQuest",Quest="DesertQuest",Mob="Desert Officer",Pos=CFrame.new(927,6,4177),MPos=CFrame.new(1536,7,4068)},
	[8]={Name="Snow Bandit",Lvl=180,NPC="SnowQuest",Quest="SnowQuest",Mob="Snow Bandit",Pos=CFrame.new(1381,87,-1294),MPos=CFrame.new(1356,87,-1383)},
	[9]={Name="Snowman",Lvl=200,NPC="SnowQuest",Quest="SnowQuest",Mob="Snowman",Pos=CFrame.new(1381,87,-1294),MPos=CFrame.new(1211,87,-1285)},
	[10]={Name="Chief Petty Officer",Lvl=225,NPC="MarineQuest",Quest="MarineQuest",Mob="Chief Petty Officer",Pos=CFrame.new(-2565,6,-665),MPos=CFrame.new(-2588,4,-1133)},
	[11]={Name="Sky Bandit",Lvl=250,NPC="SkyQuest",Quest="SkyQuest",Mob="Sky Bandit",Pos=CFrame.new(-4860,715,-2648),MPos=CFrame.new(-4700,716,-2668)},
	[12]={Name="Dark Master",Lvl=275,NPC="SkyQuest",Quest="SkyQuest",Mob="Dark Master",Pos=CFrame.new(-4860,715,-2648),MPos=CFrame.new(-5136,714,-2616)},
	[13]={Name="Prisoner",Lvl=300,NPC="PrisonerQuest",Quest="PrisonerQuest",Mob="Prisoner",Pos=CFrame.new(5300,2,470),MPos=CFrame.new(5106,2,436)},
	[14]={Name="Dangerous Prisoner",Lvl=325,NPC="DangerousQuest",Quest="DangerousQuest",Mob="Dangerous Prisoner",Pos=CFrame.new(5440,2,610),MPos=CFrame.new(5524,2,665)},
	[15]={Name="Trainee",Lvl=375,NPC="ColosseumQuest",Quest="ColosseumQuest",Mob="Trainee",Pos=CFrame.new(-1839,5,-1084),MPos=CFrame.new(-1596,5,-1185)},
	[16]={Name="Magma",Lvl=400,NPC="MagmaQuest",Quest="MagmaQuest",Mob="Magma",Pos=CFrame.new(-5417,6,8472),MPos=CFrame.new(-5297,6,8307)},
	[17]={Name="Fishman",Lvl=425,NPC="FishmanQuest",Quest="FishmanQuest",Mob="Fishman",Pos=CFrame.new(61163,11,1819),MPos=CFrame.new(61138,11,1786)},
	[18]={Name="Fishman Lord",Lvl=450,NPC="FishmanQuest",Quest="FishmanQuest",Mob="Fishman Lord",Pos=CFrame.new(61163,11,1819),MPos=CFrame.new(61200,11,1686)},
	[19]={Name="God's Guard",Lvl=475,NPC="SkyExpQuest",Quest="SkyExpQuest",Mob="God's Guard",Pos=CFrame.new(-4721,845,-1955),MPos=CFrame.new(-4718,845,-1964)},
	[20]={Name="Shanda",Lvl=500,NPC="SkyExpQuest",Quest="SkyExpQuest",Mob="Shanda",Pos=CFrame.new(-4721,845,-1955),MPos=CFrame.new(-4667,845,-1763)},
	[21]={Name="Raider",Lvl=700,NPC="Area1Quest",Quest="Area1Quest",Mob="Raider",Pos=CFrame.new(-789,16,4262),MPos=CFrame.new(-734,16,4124)},
	[22]={Name="Mercenary",Lvl=725,NPC="Area1Quest",Quest="Area1Quest",Mob="Mercenary",Pos=CFrame.new(-789,16,4262),MPos=CFrame.new(-970,16,4029)},
	[23]={Name="Swan",Lvl=775,NPC="Area2Quest",Quest="Area2Quest",Mob="Swan",Pos=CFrame.new(-619,17,6225),MPos=CFrame.new(-716,17,6402)},
	[24]={Name="Pirate",Lvl=800,NPC="MarineTreeQuest",Quest="MarineTreeQuest",Mob="Pirate",Pos=CFrame.new(2414,23,-10511),MPos=CFrame.new(2472,23,-10468)},
	[25]={Name="Royal Squad",Lvl=850,NPC="MarineTreeQuest",Quest="MarineTreeQuest",Mob="Royal Squad",Pos=CFrame.new(2414,23,-10511),MPos=CFrame.new(2624,23,-10468)},
	[26]={Name="Worker",Lvl=875,NPC="Area2Quest",Quest="Area2Quest",Mob="Worker",Pos=CFrame.new(-619,17,6225),MPos=CFrame.new(-32,17,6083)},
	[27]={Name="Sniper",Lvl=900,NPC="Area2Quest",Quest="Area2Quest",Mob="Sniper",Pos=CFrame.new(-619,17,6225),MPos=CFrame.new(-32,17,6083)},
	[28]={Name="Galley Pirate",Lvl=950,NPC="Area2Quest",Quest="Area2Quest",Mob="Galley Pirate",Pos=CFrame.new(-619,17,6225),MPos=CFrame.new(-32,17,6083)},
	[29]={Name="Magma Ninja",Lvl=1000,NPC="MagmaQuest2",Quest="MagmaQuest2",Mob="Magma Ninja",Pos=CFrame.new(-5400,50,8400),MPos=CFrame.new(-5446,50,8425)},
	[30]={Name="Lava",Lvl=1050,NPC="MagmaQuest2",Quest="MagmaQuest2",Mob="Lava",Pos=CFrame.new(-5400,50,8400),MPos=CFrame.new(-5400,50,8400)},
	[31]={Name="Reborn Skeleton",Lvl=1100,NPC="UndergroundQuest",Quest="UndergroundQuest",Mob="Reborn Skeleton",Pos=CFrame.new(-6395,7,-6760),MPos=CFrame.new(-6421,7,-6730)},
	[32]={Name="Living Zombie",Lvl=1150,NPC="UndergroundQuest",Quest="UndergroundQuest",Mob="Living Zombie",Pos=CFrame.new(-6395,7,-6760),MPos=CFrame.new(-6419,7,-6680)},
	[33]={Name="Demonic Soul",Lvl=1200,NPC="DemonicQuest",Quest="DemonicQuest",Mob="Demonic Soul",Pos=CFrame.new(-6710,13,-7170),MPos=CFrame.new(-6683,13,-7161)},
	[34]={Name="Posessed Mummy",Lvl=1250,NPC="DemonicQuest",Quest="DemonicQuest",Mob="Posessed Mummy",Pos=CFrame.new(-6710,13,-7170),MPos=CFrame.new(-6865,13,-7226)},
	[35]={Name="Peanut Soldier",Lvl=1300,NPC="SnowMountQuest",Quest="SnowMountQuest",Mob="Peanut Soldier",Pos=CFrame.new(568,88,-2112),MPos=CFrame.new(563,88,-2152)},
	[36]={Name="Ice Cream Man",Lvl=1350,NPC="SnowMountQuest",Quest="SnowMountQuest",Mob="Ice Cream Man",Pos=CFrame.new(568,88,-2112),MPos=CFrame.new(568,88,-2112)},
	[37]={Name="Cookie Savage",Lvl=1400,NPC="CakeQuest",Quest="CakeQuest",Mob="Cookie Savage",Pos=CFrame.new(-2050,33,-12180),MPos=CFrame.new(-2246,33,-12100)},
	[38]={Name="Cake Guard",Lvl=1450,NPC="CakeQuest",Quest="CakeQuest",Mob="Cake Guard",Pos=CFrame.new(-2050,33,-12180),MPos=CFrame.new(-2230,33,-12164)},
	[39]={Name="Shark",Lvl=1500,NPC="MarineQuest3",Quest="MarineQuest3",Mob="Shark",Pos=CFrame.new(-3300,6,-9500),MPos=CFrame.new(-3400,6,-9600)},
	[40]={Name="Fishman Raider",Lvl=1550,NPC="FishmanQuest3",Quest="FishmanQuest3",Mob="Fishman Raider",Pos=CFrame.new(-11200,12,-5200),MPos=CFrame.new(-11350,12,-5350)},
	[41]={Name="Sky Guard",Lvl=1600,NPC="SkyQuest3",Quest="SkyQuest3",Mob="Sky Guard",Pos=CFrame.new(-4800,900,-2200),MPos=CFrame.new(-4900,900,-2300)},
	[42]={Name="Pirate Raider",Lvl=1650,NPC="PirateQuest3",Quest="PirateQuest3",Mob="Pirate Raider",Pos=CFrame.new(14000,20,-2000),MPos=CFrame.new(14100,20,-2100)},
	[43]={Name="Snow Knight",Lvl=1700,NPC="SnowQuest3",Quest="SnowQuest3",Mob="Snow Knight",Pos=CFrame.new(1800,90,-2000),MPos=CFrame.new(1900,90,-2100)},
	[44]={Name="Ice Warrior",Lvl=1750,NPC="IceQuest3",Quest="IceQuest3",Mob="Ice Warrior",Pos=CFrame.new(-2000,20,-15000),MPos=CFrame.new(-2100,20,-15100)},
	[45]={Name="Fire Raider",Lvl=1800,NPC="FireQuest3",Quest="FireQuest3",Mob="Fire Raider",Pos=CFrame.new(-5800,20,-3000),MPos=CFrame.new(-5900,20,-3100)},
	[46]={Name="Magma Lord",Lvl=1850,NPC="MagmaQuest3",Quest="MagmaQuest3",Mob="Magma Lord",Pos=CFrame.new(-5500,50,8500),MPos=CFrame.new(-5600,50,8600)},
	[47]={Name="Desert Soldier",Lvl=1900,NPC="DesertQuest3",Quest="DesertQuest3",Mob="Desert Soldier",Pos=CFrame.new(900,10,4200),MPos=CFrame.new(1000,10,4300)},
	[48]={Name="Sand Warrior",Lvl=1950,NPC="SandQuest3",Quest="SandQuest3",Mob="Sand Warrior",Pos=CFrame.new(1200,10,4500),MPos=CFrame.new(1300,10,4600)},
}

local IslandEntrancePositions = {
	["Sky"] = CFrame.new(-4860, 715, -2648),
	["Jungle"] = CFrame.new(-1604, 36, 154),
	["Prison"] = CFrame.new(5300, 2, 470),
	["Colosseum"] = CFrame.new(-1839, 5, -1084),
	["Magma"] = CFrame.new(-5417, 6, 8472),
	["Fishman"] = CFrame.new(61163, 11, 1819),
	["Cursed Ship"] = CFrame.new(-923, 126, 64220),
	["Mansion"] = CFrame.new(-12514, 332, 359),
	["Snow Mountain"] = CFrame.new(568, 88, -2112),
	["Cake Island"] = CFrame.new(-2050, 33, -12180),
	["Moby Dick"] = CFrame.new(-3212, 10, 10956),
	["Fountain Town"] = CFrame.new(5000, 5, 4000),
	["Marine Fortress"] = CFrame.new(-3300, 6, -9500),
	["Haunted Castle"] = CFrame.new(-6395, 7, -6760),
	["Ice Island"] = CFrame.new(-2000, 20, -15000),
	["Fire Island"] = CFrame.new(-5800, 20, -3000),
	["Sand Island"] = CFrame.new(1200, 10, 4500),
}
local function getEntranceForQuest(questData)
	local islandNames = {"Jungle","Sky","Prison","Colosseum","Magma","Fishman","Cursed Ship","Mansion","Snow Mountain","Cake Island","Moby Dick","Fountain Town","Marine Fortress","Haunted Castle","Ice Island","Fire Island","Sand Island"}
	local qpos = questData.Pos
	for _, name in ipairs(islandNames) do
		local entrance = IslandEntrancePositions[name]
		if entrance then
			local dist = (qpos.Position - entrance.Position).Magnitude
			if dist < 500 then
				return entrance, name
			end
		end
	end
	return nil, nil
end

local FruitNames = {
	"Bomb-Bomb", "Spike-Spike", "Smoke-Smoke", "Spin-Spin", "Flame-Flame",
	"Bird-Bird: Falcon", "Spring-Spring", "Kilo-Kilo", "Human-Human: Buddha",
	"Chop-Chop", "Rubber-Rubber", "Door-Door", "Gum-Gum", "Diamond-Diamond",
	"Revive-Revive", "Human-Human", "Sand-Sand", "Dark-Dark", "Ghost-Ghost",
	"Magma-Magma", "Ice-Ice", "Barrier-Barrier", "Water-Water",
	"String-String", "Bird-Bird: Phoenix", "Gravity-Gravity", "Light-Light",
	"Love-Love", "Quake-Quake", "Pain-Pain", "Rumble-Rumble", "Snow-Snow",
	"Shadow-Shadow", "Venom-Venom", "Control-Control", "Spider-Spider",
	"Soul-Soul", "Dragon-Dragon", "Dough-Dough", "Leopard-Leopard",
	"Mammoth-Mammoth", "T-Rex-T-Rex", "Yeti-Yeti", "Kitsune-Kitsune",
	"Gas-Gas", "Blizzard-Blizzard", "Spirit-Spirit",
}

-- Redz: VerifyQuest checks quest title
local function verifyQuest(mobName)
	local qGui, qTitle = getQuestGui()
	if not qGui or not qTitle then return false end
	local visible = pcall(function() return qGui.Visible end)
	if not visible then return false end
	local text = string.gsub(qTitle.Text, "-", ""):lower()
	local search = string.gsub(mobName, "-", ""):lower()
	return string.find(text, search) ~= nil
end

-- Redz: StartQuest with debounce
local questDebounce = 0
local questInDebounce = ""

local function startQuest(npcName, questName, npcPos)
	if npcPos and isAlive(getChar()) then
		local root = getRoot()
		if root and (root.Position - npcPos.Position).Magnitude >= 5 then
			teleportTo(npcPos * CFrame.new(0, 0, 2.5))
			return "Teleporting to NPC: " .. npcName
		end
	end
	local now = tick()
	if questDebounce > now then
		return "Quest Debounce"
	end
	fireRemote("StartQuest", npcName, questName)
	farmStatus = "Getting Quest: " .. npcName
	questDebounce = now + 0.5
	return true
end

-- Redz: Find best quest for level
local function findBestQuest()
	local level = _Level.Value
	local best, bestIdx = nil, nil
	for i, q in ipairs(QuestData) do
		if level >= q.Lvl then
			best = q
			bestIdx = i
		end
	end
	return best, bestIdx
end

-- ==================== REDZ FARM SYSTEM ====================
local farmStatus = "Idle"
local toolDebounce = 0

-- Farm state machine: persistent across calls so we don't block
local FarmState = {phase="idle", tick=0, attempt=0}

local function autoFarmLoop()
	local root = getRoot()
	if not root then
		FarmState.phase = "idle"
		return
	end

	local now = tick()
	local plyrLevel = _Level.Value

	-- Sea progression check (non-blocking)
	if autoSeaProg then
		if game.PlaceId == FIRST_SEA and plyrLevel >= 700 then
			fireRemote("TravelDressrosa")
			farmStatus = "Traveling to Sea 2"
			FarmState.phase = "wait_sea_travel"
			FarmState.tick = now
			return
		elseif game.PlaceId == SECOND_SEA and plyrLevel >= 1500 then
			fireRemote("TravelZou")
			farmStatus = "Traveling to Sea 3"
			FarmState.phase = "wait_sea_travel"
			FarmState.tick = now
			return
		end
	end

	-- If waiting for sea travel, wait 5s then reset
	if FarmState.phase == "wait_sea_travel" then
		if now - FarmState.tick < 5 then return end
		FarmState.phase = "idle"
	end

	local quest, qIdx = findBestQuest()
	if not quest then
		FarmState.phase = "idle"
		return
	end

	-- Quest not active: handle travel + get quest
	if not verifyQuest(quest.Mob) then
		local npcPos = quest.Pos
		local dist = (root.Position - npcPos.Position).Magnitude

		-- Far island → entrance first
		if dist >= 5000 then
			local entrance, name = getEntranceForQuest(quest)
			if entrance then
				if FarmState.phase ~= "entrance" then
					FarmState.phase = "entrance"
					FarmState.tick = now
					FarmState.attempt = 0
				end
				if now - FarmState.tick < 3 then
					if FarmState.attempt == 0 then
						farmStatus = "Entrance: " .. (name or "Island")
						teleportTo(entrance * CFrame.new(0, 5, 0))
						FarmState.attempt = 1
					end
					return
				end
				FarmState.phase = "idle"
				return
			end
		end

		-- Travel to NPC
		if dist >= 5 then
			if FarmState.phase ~= "travel_npc" then
				FarmState.phase = "travel_npc"
				FarmState.tick = now
			end
			if now - FarmState.tick < 1 then
				farmStatus = "Travel: " .. quest.NPC
				teleportTo(npcPos * CFrame.new(0, 0, 2.5))
				return
			end
			FarmState.phase = "idle"
			return
		end

		-- At NPC, take quest
		if FarmState.phase ~= "take_quest" then
			FarmState.phase = "take_quest"
			FarmState.tick = now
			farmStatus = "Quest: " .. quest.Name
			fireRemote("StartQuest", quest.Quest, qIdx)
			return
		end
		if now - FarmState.tick < 0.5 then return end
		FarmState.phase = "idle"
		return
	end

	-- Quest is active: find and kill mobs
	local found = false
	if _Enemies then
		for _, e in ipairs(_Enemies:GetChildren()) do
			local hrp = e:FindFirstChild("HumanoidRootPart")
			local hum = e:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local eName = e.Name
				if eName:lower():find(quest.Mob:lower()) then
					found = true
					local dist = (hrp.Position - root.Position).Magnitude
					if dist <= (bringRange or 200) then
						farmStatus = "Kill: " .. eName

						root.CFrame = CFrame.new(root.Position, Vector3.new(hrp.Position.X, root.Position.Y, hrp.Position.Z))

						if bringingMobs then
							bringEnemies(e)
						end

						-- equip tool with debounce
						if now - toolDebounce >= 1 then
							if masteryFarming then
								local hpPct = hum.Health / hum.MaxHealth * 100
								if hpPct <= masteryHealth then
									equipTool("Melee")
								else
									equipTool(selectedWeapon ~= "Combat" and selectedWeapon or nil)
								end
							else
								equipTool()
							end
							toolDebounce = now
						end

						if FarmModes[FarmMode] and hrp then
							FarmModes[FarmMode](root, hrp.CFrame)
						end

						EnableBuso()
						fastAttack()
					end
				end
			end
		end
	end

	if not found then
		farmStatus = "No mobs found"
		local mPos = quest.MPos
		if mPos and (root.Position - mPos.Position).Magnitude > 15 then
			teleportTo(mPos + Vector3.new(0, 15, 0))
		end
	end

	-- Complete quest when done
	local qGui = getQuestGui()
	if qGui and qGui.Visible == false then
		fireRemote("CompleteQuest")
		sessionBounty = sessionBounty + 1
		farmStatus = "Complete"
		FarmState.phase = "complete"
		FarmState.tick = now
		return
	end

	if FarmState.phase == "complete" and now - FarmState.tick > 0.3 then
		FarmState.phase = "idle"
	end

	-- Auto stat (non-blocking)
	local pts = _Data:FindFirstChild("Points")
	if pts and pts.Value > 0 then
		pcall(function()
			local t = pts.Value
			if autoStatMelee then fireRemote("AddPoint", "Melee", t) end
			if autoStatDefense then fireRemote("AddPoint", "Defense", t) end
			if autoStatSword then fireRemote("AddPoint", "Sword", t) end
			if autoStatGun then fireRemote("AddPoint", "Gun", t) end
			if autoStatFruit then fireRemote("AddPoint", "DevilFruit", t) end
		end)
	end
end

-- ==================== REDZ NOCLIP ====================
local function doNoclip()
	if not noclipEnabled then return end
	pcall(function()
		local char = getChar()
		local root = getRoot()
		if not char or not root then return end
		if not root:FindFirstChild("BodyClip") then
			local bv = Instance.new("BodyVelocity")
			bv.Name = "BodyClip"
			bv.MaxForce = Vector3.new(100000, 100000, 100000)
			bv.Velocity = Vector3.new(0, 0, 0)
			bv.Parent = root
		end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end)
end

-- ==================== REDZ AIMBOT (__namecall hook) ====================
local aimbotHooked = false
local mousePos = Vector3.new()

local function setupAimbot()
	if aimbotHooked then return end
	pcall(function()
		local mt = getrawmetatable(game)
		if not mt then return end
		local oldNamecall = mt.__namecall
		setreadonly(mt, false)
		mt.__namecall = newcclosure(function(...)
			local method = getnamecallmethod()
			local args = {...}
			if aimbotEnabled and tostring(method) == "FireServer" then
				if tostring(args[1]) == "RemoteEvent" then
					local arg2 = tostring(args[2])
					if arg2 ~= "true" and arg2 ~= "false" then
						args[2] = mousePos
						return oldNamecall(unpack(args))
					end
				end
			end
			return oldNamecall(...)
		end)
		setreadonly(mt, true)
		aimbotHooked = true
	end)
end

-- ==================== ESP (Redz style) ====================
local espObjects = {}

local function clearESP()
	for _, obj in ipairs(espObjects) do
		pcall(function() obj:Destroy() end)
	end
	espObjects = {}
end

local function createPlayerESP(player)
	if not playerESP then return end
	if not player.Character then return end
	local head = player.Character:FindFirstChild("Head")
	if not head then return end
	if head:FindFirstChild("EspName") then return end
	local bill = Instance.new("BillboardGui")
	bill.Name = "EspName"
	bill.Adornee = head
	bill.Size = UDim2.new(0, 200, 0, 30)
	bill.AlwaysOnTop = true
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = player.Name
	lbl.TextColor3 = player.Team == lp.Team and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(255, 80, 80)
	lbl.TextSize = 14
	lbl.Font = Enum.Font.GothamBold
	lbl.TextStrokeTransparency = 0.3
	lbl.Parent = bill
	bill.Parent = head
	table.insert(espObjects, bill)
end

local function createFruitESP()
	if not fruitESP then return end
	for _, v in ipairs(workspace:GetChildren()) do
		local matched = false
		for _, n in ipairs(FruitNames) do
			if v.Name:find(n) then matched = true; break end
		end
		if matched and v:FindFirstChild("Handle") then
			local handle = v.Handle
			if not handle:FindFirstChild("EspFruit") then
				local bill = Instance.new("BillboardGui")
				bill.Name = "EspFruit"
				bill.Adornee = handle
				bill.Size = UDim2.new(0, 120, 0, 24)
				bill.AlwaysOnTop = true
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, 0, 1, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = v.Name
				lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
				lbl.TextSize = 12
				lbl.Font = Enum.Font.GothamBold
				lbl.TextStrokeTransparency = 0.2
				lbl.Parent = bill
				bill.Parent = handle
				table.insert(espObjects, bill)
			end
		end
	end
end

local function refreshESP()
	clearESP()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then createPlayerESP(p) end
	end
	createFruitESP()
end

-- ==================== MAHUB-STYLE ESP EXTENSIONS ====================
local extendedEspObjects = {}

local function clearExtendedESP()
	for _, obj in ipairs(extendedEspObjects) do
		pcall(function() obj:Destroy() end)
	end
	extendedEspObjects = {}
end

-- Chest ESP (Mahub: _ChestTagged)
local function createChestESP()
	if not chestESP then return end
	local root = getRoot()
	if not root then return end
	local tagged = pcall(CollectionService.GetTagged, CollectionService, "_ChestTagged")
	if not tagged then return end
	for _, chest in ipairs(tagged) do
		local disabled = pcall(function() return chest:GetAttribute("IsDisabled") end)
		if not disabled and not chest:FindFirstChild("ChestEsp") then
			local bill = Instance.new("BillboardGui")
			bill.Name = "ChestEsp"
			bill.Adornee = chest
			bill.Size = UDim2.new(0, 140, 0, 30)
			bill.AlwaysOnTop = true
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			local dist = math.floor((root.Position - chest:GetPivot().Position).Magnitude / 3)
			lbl.Text = "Chest\n" .. tostring(dist) .. " M"
			lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
			lbl.TextSize = 11
			lbl.Font = Enum.Font.GothamBold
			lbl.TextStrokeTransparency = 0.3
			lbl.Parent = bill
			bill.Parent = chest
			table.insert(extendedEspObjects, bill)
		end
	end
end

-- Mob ESP (Mahub: Enemies)
local function createMobESP()
	if not mobESP or not _Enemies then return end
	for _, e in ipairs(_Enemies:GetChildren()) do
		local hrp = e:FindFirstChild("HumanoidRootPart")
		if hrp and not hrp:FindFirstChild("MobEsp") then
			local bill = Instance.new("BillboardGui")
			bill.Name = "MobEsp"
			bill.Adornee = hrp
			bill.Size = UDim2.new(0, 160, 0, 24)
			bill.AlwaysOnTop = true
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			local root = getRoot()
			local dist = root and math.floor((root.Position - hrp.Position).Magnitude) or 0
			lbl.Text = e.Name .. " - " .. tostring(dist) .. " M"
			lbl.TextColor3 = Color3.fromRGB(7, 236, 240)
			lbl.TextSize = 10
			lbl.Font = Enum.Font.GothamBold
			lbl.TextStrokeTransparency = 0.3
			lbl.Parent = bill
			bill.Parent = hrp
			table.insert(extendedEspObjects, bill)
		end
	end
end

-- NPC ESP (Mahub: NPCs)
local function createNpcESP()
	if not npcESP or not _NPCs then return end
	for _, npc in ipairs(_NPCs:GetChildren()) do
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if hrp and not hrp:FindFirstChild("NpcEsp") then
			local bill = Instance.new("BillboardGui")
			bill.Name = "NpcEsp"
			bill.Adornee = hrp
			bill.Size = UDim2.new(0, 160, 0, 24)
			bill.AlwaysOnTop = true
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			local root = getRoot()
			local dist = root and math.floor((root.Position - hrp.Position).Magnitude) or 0
			lbl.Text = npc.Name .. " - " .. tostring(dist) .. " M"
			lbl.TextColor3 = Color3.fromRGB(80, 245, 245)
			lbl.TextSize = 10
			lbl.Font = Enum.Font.GothamBold
			lbl.TextStrokeTransparency = 0.3
			lbl.Parent = bill
			bill.Parent = hrp
			table.insert(extendedEspObjects, bill)
		end
	end
end

-- Sea ESP (Mahub: SeaBeasts)
local function createSeaESP()
	if not seaESP or not _SeaBeasts then return end
	for _, sb in ipairs(_SeaBeasts:GetChildren()) do
		local hrp = sb:FindFirstChild("HumanoidRootPart")
		if hrp and not hrp:FindFirstChild("SeaEsp") then
			local bill = Instance.new("BillboardGui")
			bill.Name = "SeaEsp"
			bill.Adornee = hrp
			bill.Size = UDim2.new(0, 160, 0, 24)
			bill.AlwaysOnTop = true
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			local root = getRoot()
			local dist = root and math.floor((root.Position - hrp.Position).Magnitude) or 0
			lbl.Text = sb.Name .. " - " .. tostring(dist) .. " M"
			lbl.TextColor3 = Color3.fromRGB(255, 100, 100)
			lbl.TextSize = 10
			lbl.Font = Enum.Font.GothamBold
			lbl.TextStrokeTransparency = 0.3
			lbl.Parent = bill
			bill.Parent = hrp
			table.insert(extendedEspObjects, bill)
		end
	end
end

-- Island ESP (Mahub: Locations)
local function createIslandESP()
	if not islandESP or not _Locations then return end
	for _, loc in ipairs(_Locations:GetChildren()) do
		if loc.Name ~= "Sea" and not loc:FindFirstChild("IslandEsp") then
			local bill = Instance.new("BillboardGui")
			bill.Name = "IslandEsp"
			bill.Adornee = loc
			bill.Size = UDim2.new(0, 160, 0, 24)
			bill.AlwaysOnTop = true
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			local root = getRoot()
			local dist = root and math.floor((root.Position - loc.Position).Magnitude / 3) or 0
			lbl.Text = loc.Name .. " - " .. tostring(dist) .. " M"
			lbl.TextColor3 = Color3.fromRGB(8, 247, 255)
			lbl.TextSize = 10
			lbl.Font = Enum.Font.GothamBold
			lbl.TextStrokeTransparency = 0.3
			lbl.Parent = bill
			bill.Parent = loc
			table.insert(extendedEspObjects, bill)
		end
	end
end

-- Flower ESP (Mahub: Flower1/Flower2)
local function createFlowerESP()
	if not flowerESP then return end
	for _, v in ipairs(workspace:GetChildren()) do
		if (v.Name == "Flower1" or v.Name == "Flower2") and not v:FindFirstChild("FlowerEsp") then
			local bill = Instance.new("BillboardGui")
			bill.Name = "FlowerEsp"
			bill.Adornee = v
			bill.Size = UDim2.new(0, 120, 0, 24)
			bill.AlwaysOnTop = true
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			local root = getRoot()
			local dist = root and math.floor((root.Position - v.Position).Magnitude / 3) or 0
			local flowerName = v.Name == "Flower1" and "Blue Flower" or "Red Flower"
			lbl.Text = flowerName .. " - " .. tostring(dist) .. " M"
			lbl.TextColor3 = v.Name == "Flower1" and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)
			lbl.TextSize = 10
			lbl.Font = Enum.Font.GothamBold
			lbl.TextStrokeTransparency = 0.3
			lbl.Parent = bill
			bill.Parent = v
			table.insert(extendedEspObjects, bill)
		end
	end
end

-- Extended refresh: clear old first, then create new
local function refreshExtendedESP()
	clearExtendedESP()
	createChestESP()
	createMobESP()
	createNpcESP()
	createSeaESP()
	createIslandESP()
	createFlowerESP()
end

-- ==================== VISUAL CLEANUP (Redz style) ====================
local function doVisualCleanup()
	pcall(function()
		if not _WorldOrigin then return end
		_WorldOrigin.ChildAdded:Connect(function(w)
			pcall(function()
				local name = w.Name
				if name == "CurvedRing" or name == "SlashHit" or name == "DamageCounter" or name == "SwordSlash" or name == "SlashTail" or name == "Sounds" then
					w:Destroy()
				end
			end)
		end)
	end)
end

-- ==================== REDZ SIMULATION RADIUS (RenderStepped) ====================
RunService.RenderStepped:Connect(function()
	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(lp, "SimulationRadius", math.huge * math.huge)
		end
	end)
end)

-- ==================== UI ====================
local Win = DeniaLib:CreateWindow({
	Title = "DeniaHub v3.1",
	Key = Enum.KeyCode.RightShift,
	Size = UDim2.new(0, 680, 0, 560),
})

local StatusTab = Win:AddTab("Status", "activity")
local FarmTab = Win:AddTab("AutoFarm", "zap")
local PvPTab = Win:AddTab("PvP", "crosshair")
local RaceTab = Win:AddTab("Race V4", "trophy")
local SeaTab = Win:AddTab("Sea Event", "anchor")
local TpTab = Win:AddTab("Teleport", "compass")
local CfgTab = Win:AddTab("Config", "cog")

-- TAB 1: STATUS
local stSec = StatusTab:AddSection("Player Stats")
stSec:AddStatGrid({
	columns = 3,
	items = {
		{value = "1", label = "Level"},
		{value = "0", label = "Bounty"},
		{value = "0", label = "Kills"},
		{value = "—", label = "Race"},
		{value = "—", label = "Playtime"},
		{value = "60", label = "FPS"},
	}
})

local srvSec = StatusTab:AddSection("Server")
srvSec:AddStatGrid({
	columns = 3,
	items = {
		{value = "—", label = "Ping"},
		{value = "—", label = "Sea"},
		{value = "—", label = "Server"},
	}
})

local actSec = StatusTab:AddSection("Actions")
actSec:AddButtonGroup({
	{label = "Server Hop", callback = function() serverHop() end},
	{label = "Reset", callback = function() pcall(function() local c = getChar(); if c then c:BreakJoints() end end) end},
	{label = "Rejoin", callback = function() TeleportService:Teleport(game.PlaceId, lp) end},
})

local stProgSec = StatusTab:AddSection("Progress")
local stPBar = stProgSec:AddProgress(42)
local stLbl = stProgSec:AddLabel("NPC: <b>Idle</b> · Player: <b>You</b>")

-- TAB 2: AUTO FARM
local farmSec = FarmTab:AddSection("Auto Farm")
local autoFarming = false; local masteryFarming = false
local autoRolling = false; local selectedWeapon = "Combat"

farmSec:AddToggle({label="Auto Farm Level",default=false,callback=function(v)autoFarming=v end})
farmSec:AddToggle({label="Auto Farm Mastery",default=false,callback=function(v)masteryFarming=v end})
farmSec:AddToggle({label="Auto Roll Fruit",default=false,callback=function(v)autoRolling=v end})
farmSec:AddDropdown({label="Weapon",options={"Combat","Saber","Dark Blade","Kabucha","Dragon Trident"},default="Combat",callback=function(v)selectedWeapon=v end})
local farmStatLbl = farmSec:AddLabel("Status: Idle")

local farmModeSec = FarmTab:AddSection("Farm Mode")
farmModeSec:AddDropdown({label="Mode",options={"Up","Star","Orbit"},default="Up",callback=function(v)FarmMode=v end})
local masteryHealth = 25
farmModeSec:AddSlider({label="Mastery HP%",min=5,max=100,default=25,callback=function(v)masteryHealth=v end})

local bringSec = FarmTab:AddSection("Mobs")
local bringingMobs = false; local bringRange = 200
bringSec:AddToggle({label="Bring Mobs",default=false,callback=function(v)bringingMobs=v end})
bringSec:AddSlider({label="Range",min=50,max=400,default=200,callback=function(v)bringRange=v end})

-- TAB 3: PVP
local pvpSec = PvPTab:AddSection("Target")
local selectedTarget = "Select Player"; local aimbotEnabled = false
local autoBounty = false; local killAuraEnabled = false; local fastAttackEnabled = false

local targetOpts = {"Select Player"}
local targetDropdown = pvpSec:AddDropdown({label="Target",options=targetOpts,default="Select Player",callback=function(v)selectedTarget=v end})

local btySec = PvPTab:AddSection("Auto Bounty")
btySec:AddToggle({label="Auto Bounty",default=false,callback=function(v)autoBounty=v; bountyTick=0 end})
btySec:AddDropdown({label="Level Diff",options={"Any","+50","+100","+200","+500"},default="Any",callback=function()end})

local combSec = PvPTab:AddSection("Combat")
combSec:AddToggle({label="Fast Attack",default=false,callback=function(v)fastAttackEnabled=v end})
combSec:AddToggle({label="Aimbot",default=false,callback=function(v)aimbotEnabled=v end})
combSec:AddToggle({label="Kill Aura",default=false,callback=function(v)killAuraEnabled=v end})
combSec:AddButtonGroup({{label="Start Hunting",callback=function()autoBounty=true end},{label="Stop",danger=true,callback=function()autoBounty=false end}})

-- TAB 4: RACE V4
local raceSec = RaceTab:AddSection("Race V4")
local currentRace = "Unknown"; local autoV4 = false
raceSec:AddLabel("Current Race: Unknown")
raceSec:AddButtonGroup({{label="Auto V4",callback=function()autoV4=not autoV4 end},{label="Check Race",callback=function()
	local d = pcall(function() return _CommF:InvokeServer("GetRace") end)
	if d then currentRace=tostring(d) end
end}})
local v4Sec = RaceTab:AddSection("V4 Abilities")
v4Sec:AddButtonGroup({{label="Auto Gear",callback=function()end},{label="Auto Trial",callback=function()end},{label="Auto Shrine",callback=function()end},{label="Auto Temple",callback=function()end}})

-- TAB 5: SEA EVENT
local seaEv = SeaTab:AddSection("Sea Events")
local autoSeaEvent = false; local seaPriority = "All"
seaEv:AddToggle({label="Auto Sea Event",default=false,callback=function(v)autoSeaEvent=v end})
seaEv:AddDropdown({label="Priority",options={"All","Ship Only","Sea Beast","Leviathan"},default="All",callback=function(v)seaPriority=v end})
local fishSec = SeaTab:AddSection("Auto Fish")
local autoFishing = false
fishSec:AddToggle({label="Auto Fish",default=false,callback=function(v)autoFishing=v end})

-- TAB 6: TELEPORT
local tpSec = TpTab:AddSection("Teleport")
tpSec:AddButtonGroup({
	{label="Jungle",callback=function()teleportTo(CFrame.new(-1604,36,154))end},
	{label="Desert",callback=function()teleportTo(CFrame.new(927,6,4177))end},
	{label="Snow",callback=function()teleportTo(CFrame.new(1381,87,-1294))end},
	{label="Marine",callback=function()teleportTo(CFrame.new(-2565,6,-665))end},
	{label="Sky",callback=function()teleportTo(CFrame.new(-4860,715,-2648))end},
	{label="Magma",callback=function()teleportTo(CFrame.new(-5417,6,8472))end},
	{label="Prison",callback=function()teleportTo(CFrame.new(5300,2,470))end},
	{label="Colosseum",callback=function()teleportTo(CFrame.new(-1839,5,-1084))end},
	{label="Fishman",callback=function()teleportTo(CFrame.new(61163,11,1819))end},
	{label="Skypiea",callback=function()teleportTo(CFrame.new(-4721,845,-1955))end},
})

-- TAB 7: CONFIG
local gen = CfgTab:AddSection("General")
local lowCPU = false
gen:AddToggle({label="Low CPU Mode",default=false,callback=function(v)lowCPU=v end})
local mvSec = CfgTab:AddSection("Movement")
local noclipEnabled = false
mvSec:AddToggle({label="Noclip",default=false,callback=function(v)noclipEnabled=v end})
local statSec = CfgTab:AddSection("Auto Stats")
local autoStatMelee=false;local autoStatDefense=false;local autoStatSword=false;local autoStatGun=false;local autoStatFruit=false;local autoSeaProg=false
statSec:AddToggle({label="Auto Melee",default=false,callback=function(v)autoStatMelee=v end})
statSec:AddToggle({label="Auto Defense",default=false,callback=function(v)autoStatDefense=v end})
statSec:AddToggle({label="Auto Sword",default=false,callback=function(v)autoStatSword=v end})
statSec:AddToggle({label="Auto Gun",default=false,callback=function(v)autoStatGun=v end})
statSec:AddToggle({label="Auto Fruit",default=false,callback=function(v)autoStatFruit=v end})
local espSec = CfgTab:AddSection("ESP")
local fruitESP=true;local playerESP=true;local chestESP=false;local mobESP=false;local npcESP=false;local seaESP=false;local islandESP=false;local flowerESP=false
espSec:AddToggle({label="Fruit ESP",default=true,callback=function(v)fruitESP=v;refreshESP()end})
espSec:AddToggle({label="Player ESP",default=true,callback=function(v)playerESP=v;refreshESP()end})
espSec:AddToggle({label="Chest ESP",default=false,callback=function(v)chestESP=v;refreshExtendedESP()end})
espSec:AddToggle({label="Mob ESP",default=false,callback=function(v)mobESP=v;refreshExtendedESP()end})
espSec:AddToggle({label="NPC ESP",default=false,callback=function(v)npcESP=v;refreshExtendedESP()end})
espSec:AddToggle({label="Sea ESP",default=false,callback=function(v)seaESP=v;refreshExtendedESP()end})
espSec:AddToggle({label="Island ESP",default=false,callback=function(v)islandESP=v;refreshExtendedESP()end})
espSec:AddToggle({label="Flower ESP",default=false,callback=function(v)flowerESP=v;refreshExtendedESP()end})
local progSec = CfgTab:AddSection("Sea Progression")
progSec:AddToggle({label="Auto Sea Progress",default=false,callback=function(v)autoSeaProg=v end})

-- ==================== STATE VARS ====================
local sessionBounty = 0; local sessionKills = 0; local sessionStart = tick()
local currentSea = 1
local fpsCounter = 0; local fpsTime = 0; local currentFps = 60; local fpsUpdateTick = 0
local hakiTick = 0

-- ==================== HEARTBEAT LOOP ====================
local hbTick = 0
local bountyTick = 0
RunService.Heartbeat:Connect(function(dt)
	dt = dt or 0.016
	fpsCounter = fpsCounter + 1
	fpsTime = fpsTime + dt
	if fpsTime >= 1 then
		currentFps = fpsCounter
		fpsCounter = 0
		fpsTime = 0
	end

	if fpsUpdateTick <= 0 then
		Win:UpdateDI(currentFps, farmStatus, lp.Name)
		fpsUpdateTick = 2
	else
		fpsUpdateTick = fpsUpdateTick - dt
	end

	doNoclip()

	-- Throttled: run heavy work every ~0.1s
	hbTick = hbTick + dt
	if hbTick < 0.1 then return end
	hbTick = 0

	if bringingMobs then bringEnemies() end

	-- Auto bounty (throttled: every ~0.5s)
	bountyTick = bountyTick + dt
	if autoBounty and bountyTick >= 0.5 then
		bountyTick = 0
		task.spawn(function()
			pcall(function()
				local root = getRoot()
				if not root then return end
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= lp and p.Character then
						local hrp = p.Character:FindFirstChild("HumanoidRootPart")
						if hrp and (hrp.Position - root.Position).Magnitude <= 300 then
							teleportTo(hrp.CFrame * CFrame.new(0, 0, -8))
							fastAttack(true)
						end
					end
				end
			end)
		end)
	end

	-- Kill aura (Redz style)
	if killAuraEnabled then
		KillAura(125)
	end

	-- Auto haki
	hakiTick = hakiTick + dt
	if hakiTick >= 1 then
		hakiTick = 0
		EnableBuso()
	end

	-- Aimbot target
	if aimbotEnabled and selectedTarget and selectedTarget ~= "Select Player" then
		local targetPlayer = Players:FindFirstChild(selectedTarget:match("^[^%[]+"))
		if targetPlayer and targetPlayer.Character then
			local h = targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetPlayer.Character:FindFirstChild("Head")
			if h then mousePos = h.Position end
		end
	end

	-- Update server info
	Win:UpdateServerInfo({fps = currentFps, level = _Level.Value, bounty = sessionBounty})
end)

-- ==================== AUTO FARM THREAD (separate from heartbeat) ====================
task.spawn(function()
	while true do
		local interval = lowCPU and 1.0 or 0.5
		task.wait(interval)
		if (autoFarming or masteryFarming) then
			pcall(autoFarmLoop)
			if farmStatLbl then
				pcall(function() farmStatLbl.Text = "Status: "..farmStatus end)
			end
		end
	end
end)

-- ==================== EXTENDED ESP REFRESH THREAD ====================
task.spawn(function()
	while true do
		local interval = lowCPU and 5.0 or 2.5
		task.wait(interval)
		pcall(refreshExtendedESP)
	end
end)

-- Auto select team on character respawn
lp.CharacterAdded:Connect(function()
	task.wait(0.8)
	autoSelectTeam("Pirates")
end)

-- ==================== INIT ====================
task.spawn(function()
	task.wait(0.5)
	autoSelectTeam("Pirates")
end)

task.spawn(function()
	task.wait(1)
	setupAimbot()
	initCombat()
	initAnimationHack()
end)

task.spawn(function() task.wait(2) refreshESP() end)
task.spawn(function() task.wait(2.5) refreshExtendedESP() end)
task.spawn(function() task.wait(3) doVisualCleanup() end)

Players.PlayerAdded:Connect(function() task.wait(1) refreshESP(); refreshExtendedESP() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) refreshESP() end)

-- Auto-refresh player list cho target dropdown
local function refreshTargetList()
	local names = {"Select Player"}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then table.insert(names, p.Name) end
	end
	if targetDropdown and targetDropdown._updateOptions then
		targetDropdown._updateOptions(names)
	end
end
task.spawn(function()
	while true do
		task.wait(3)
		pcall(refreshTargetList)
	end
end)
Players.PlayerAdded:Connect(function() task.wait(1.5) pcall(refreshTargetList) end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) pcall(refreshTargetList) end)

-- Auto stat loop
task.spawn(function()
	while true do
		task.wait(1)
		pcall(function()
			local pts = _Data:FindFirstChild("Points")
			if pts and pts.Value > 0 then
				local t = pts.Value
				if autoStatMelee then fireRemote("AddPoint", "Melee", t) end
				if autoStatDefense then fireRemote("AddPoint", "Defense", t) end
				if autoStatSword then fireRemote("AddPoint", "Sword", t) end
				if autoStatGun then fireRemote("AddPoint", "Gun", t) end
				if autoStatFruit then fireRemote("AddPoint", "DevilFruit", t) end
			end
		end)
	end
end)

-- Auto sea progression
task.spawn(function()
	while true do
		task.wait(5)
		if autoSeaProg then
			local lvl = _Level.Value
			if game.PlaceId == FIRST_SEA and lvl >= 700 then fireRemote("TravelDressrosa")
			elseif game.PlaceId == SECOND_SEA and lvl >= 1500 then fireRemote("TravelZou") end
		end
	end
end)

-- Auto roll fruit
task.spawn(function()
	while true do
		task.wait(60)
		if autoRolling then pcall(function() fireRemote("RollFruit") end) end
	end
end)

-- Notify
pcall(function()
	StarterGui:SetCore("SendNotification", {Title = "DeniaHub v3.1", Text = "Loaded. Press RightShift to toggle.", Duration = 4})
end)

print("DeniaHub v3.1 loaded -- Redz standard methods")
