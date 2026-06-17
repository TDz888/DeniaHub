-- DeniaHub.lua v3.0 — Blox Fruits Script
-- Engine: Banana Cat combat + Azure CombatFramework + Infinite Yield movement
-- Lua 5.1 compatible | No goto, no continue, no Font.fromId

-- ==================== LOADER ====================
local DeniaLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/TDz888/DeniaHub/main/DeniaLib.lua"))()

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer
local c = ReplicatedStorage
local e = c:FindFirstChild("Remotes")
local CommF = e and e:FindFirstChild("CommF_")
local CommE = e and e:FindFirstChild("CommE")

-- PlaceIds
local FIRST_SEA = 2753915549
local SECOND_SEA = 4442272183
local THIRD_SEA = 7449423635

-- ==================== UTILITIES ====================
local function getChar() return lp.Character or lp.CharacterAdded:Wait() end
local function getRoot()
	local char = getChar()
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end
local function getHumanoid()
	local char = getChar()
	return char:FindFirstChildOfClass("Humanoid")
end
local function isAlive(character)
	return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
end
local function invokeServer(...)
	if not CommF then return end
	local ok, result = pcall(function() return CommF:InvokeServer(...) end)
	return ok and result or nil
end
local function getEnemies() return Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Enemy") or {} end
local function getCharacters() return Workspace:FindFirstChild("Characters") or {} end

-- ==================== QUEST DATABASE (Banana Cat style) ====================
local QuestData = {
	-- Sea 1
	[1]={Name="Bandit",Lvl=1,NPC="BanditQuest1",Quest="BanditQuest1",Mob="Bandit",Pos=CFrame.new(1061,16,1428),MPos=CFrame.new(1045,27,1560)},
	[2]={Name="Monkey",Lvl=15,NPC="JungleQuest",Quest="JungleQuest",Mob="Monkey",Pos=CFrame.new(-1604,36,154),MPos=CFrame.new(-1598,36,191)},
	[3]={Name="Gorilla",Lvl=30,NPC="JungleQuest",Quest="JungleQuest",Mob="Gorilla",Pos=CFrame.new(-1604,36,154),MPos=CFrame.new(-1432,36,-31)},
	[4]={Name="Pirate",Lvl=60,NPC="BuggyQuest1",Quest="BuggyQuest1",Mob="Pirate",Pos=CFrame.new(-1141,5,3831),MPos=CFrame.new(-1195,5,3887)},
	[5]={Name="Brute",Lvl=100,NPC="BuggyQuest1",Quest="BuggyQuest1",Mob="Brute",Pos=CFrame.new(-1141,5,3831),MPos=CFrame.new(-1146,5,3976)},
	[6]={Name="DesertBandit",Lvl=120,NPC="DesertQuest",Quest="DesertQuest",Mob="Desert Bandit",Pos=CFrame.new(927,6,4177),MPos=CFrame.new(924,5,4336)},
	[7]={Name="DesertOfficer",Lvl=150,NPC="DesertQuest",Quest="DesertQuest",Mob="Desert Officer",Pos=CFrame.new(927,6,4177),MPos=CFrame.new(1536,7,4068)},
	[8]={Name="SnowBandit",Lvl=180,NPC="SnowQuest",Quest="SnowQuest",Mob="Snow Bandit",Pos=CFrame.new(1381,87,-1294),MPos=CFrame.new(1356,87,-1383)},
	[9]={Name="SnowMan",Lvl=200,NPC="SnowQuest",Quest="SnowQuest",Mob="Snowman",Pos=CFrame.new(1381,87,-1294),MPos=CFrame.new(1211,87,-1285)},
	[10]={Name="ChiefPetty",Lvl=225,NPC="MarineQuest",Quest="MarineQuest",Mob="Chief Petty Officer",Pos=CFrame.new(-2565,6,-665),MPos=CFrame.new(-2588,4,-1133)},
	[11]={Name="SkyBandit",Lvl=250,NPC="SkyQuest",Quest="SkyQuest",Mob="Sky Bandit",Pos=CFrame.new(-4860,715,-2648),MPos=CFrame.new(-4700,716,-2668)},
	[12]={Name="DarkMaster",Lvl=275,NPC="SkyQuest",Quest="SkyQuest",Mob="Dark Master",Pos=CFrame.new(-4860,715,-2648),MPos=CFrame.new(-5136,714,-2616)},
	[13]={Name="Prisoner",Lvl=300,NPC="PrisonerQuest",Quest="PrisonerQuest",Mob="Prisoner",Pos=CFrame.new(5300,2,470),MPos=CFrame.new(5106,2,436)},
	[14]={Name="DangerousPrisoner",Lvl=325,NPC="DangerousQuest",Quest="DangerousQuest",Mob="Dangerous Prisoner",Pos=CFrame.new(5440,2,610),MPos=CFrame.new(5524,2,665)},
	[15]={Name="Trainee",Lvl=375,NPC="ColosseumQuest",Quest="ColosseumQuest",Mob="Trainee",Pos=CFrame.new(-1839,5,-1084),MPos=CFrame.new(-1596,5,-1185)},
	[16]={Name="Magma",Lvl=400,NPC="MagmaQuest",Quest="MagmaQuest",Mob="Magma",Pos=CFrame.new(-5417,6,8472),MPos=CFrame.new(-5297,6,8307)},
	[17]={Name="Fishman",Lvl=425,NPC="FishmanQuest",Quest="FishmanQuest",Mob="Fishman",Pos=CFrame.new(61163,11,1819),MPos=CFrame.new(61138,11,1786)},
	[18]={Name="FishmanLord",Lvl=450,NPC="FishmanQuest",Quest="FishmanQuest",Mob="Fishman Lord",Pos=CFrame.new(61163,11,1819),MPos=CFrame.new(61200,11,1686)},
	[19]={Name="GodHuman",Lvl=475,NPC="SkyExpQuest",Quest="SkyExpQuest",Mob="God's Guard",Pos=CFrame.new(-4721,845,-1955),MPos=CFrame.new(-4718,845,-1964)},
	[20]={Name="Shanda",Lvl=500,NPC="SkyExpQuest",Quest="SkyExpQuest",Mob="Shanda",Pos=CFrame.new(-4721,845,-1955),MPos=CFrame.new(-4667,845,-1763)},
	-- Sea 2
	[21]={Name="Raider",Lvl=700,NPC="Area1Quest",Quest="Area1Quest",Mob="Raider",Pos=CFrame.new(-789,16,4262),MPos=CFrame.new(-734,16,4124)},
	[22]={Name="Mercenary",Lvl=725,NPC="Area1Quest",Quest="Area1Quest",Mob="Mercenary",Pos=CFrame.new(-789,16,4262),MPos=CFrame.new(-970,16,4029)},
	[23]={Name="Swan",Lvl=775,NPC="Area2Quest",Quest="Area2Quest",Mob="Swan",Pos=CFrame.new(-619,17,6225),MPos=CFrame.new(-716,17,6402)},
	[24]={Name="PirateThousand",Lvl=800,NPC="MarineTreeQuest",Quest="MarineTreeQuest",Mob="Pirate",Pos=CFrame.new(2414,23,-10511),MPos=CFrame.new(2472,23,-10468)},
	[25]={Name="RoyalSquad",Lvl=850,NPC="MarineTreeQuest",Quest="MarineTreeQuest",Mob="Royal Squad",Pos=CFrame.new(2414,23,-10511),MPos=CFrame.new(2624,23,-10468)},
	[26]={Name="Worker",Lvl=875,NPC="Area2Quest",Quest="Area2Quest",Mob="Worker",Pos=CFrame.new(-619,17,6225),MPos=CFrame.new(-32,17,6083)},
	[27]={Name="Sniper",Lvl=900,NPC="Area2Quest",Quest="Area2Quest",Mob="Sniper",Pos=CFrame.new(-619,17,6225),MPos=CFrame.new(-32,17,6083)},
	[28]={Name="Galley",Lvl=950,NPC="Area2Quest",Quest="Area2Quest",Mob="Galley Pirate",Pos=CFrame.new(-619,17,6225),MPos=CFrame.new(-32,17,6083)},
	[29]={Name="MagmaNinja",Lvl=1000,NPC="MagmaQuest2",Quest="MagmaQuest2",Mob="Magma Ninja",Pos=CFrame.new(-5400,50,8400),MPos=CFrame.new(-5446,50,8425)},
	[30]={Name="Lava",Lvl=1050,NPC="MagmaQuest2",Quest="MagmaQuest2",Mob="Lava",Pos=CFrame.new(-5400,50,8400),MPos=CFrame.new(-5400,50,8400)},
	[31]={Name="RebornSkeleton",Lvl=1100,NPC="UndergroundQuest",Quest="UndergroundQuest",Mob="Reborn Skeleton",Pos=CFrame.new(-6395,7,-6760),MPos=CFrame.new(-6421,7,-6730)},
	[32]={Name="LivingZombie",Lvl=1150,NPC="UndergroundQuest",Quest="UndergroundQuest",Mob="Living Zombie",Pos=CFrame.new(-6395,7,-6760),MPos=CFrame.new(-6419,7,-6680)},
	[33]={Name="DemonicSoul",Lvl=1200,NPC="DemonicQuest",Quest="DemonicQuest",Mob="Demonic Soul",Pos=CFrame.new(-6710,13,-7170),MPos=CFrame.new(-6683,13,-7161)},
	[34]={Name="PosessedMummy",Lvl=1250,NPC="DemonicQuest",Quest="DemonicQuest",Mob="Posessed Mummy",Pos=CFrame.new(-6710,13,-7170),MPos=CFrame.new(-6865,13,-7226)},
	[35]={Name="PeanutSoldier",Lvl=1300,NPC="SnowMountQuest",Quest="SnowMountQuest",Mob="Peanut Soldier",Pos=CFrame.new(568,88,-2112),MPos=CFrame.new(563,88,-2152)},
	[36]={Name="IceCreamMan",Lvl=1350,NPC="SnowMountQuest",Quest="SnowMountQuest",Mob="Ice Cream Man",Pos=CFrame.new(568,88,-2112),MPos=CFrame.new(568,88,-2112)},
	[37]={Name="CookieSavage",Lvl=1400,NPC="CakeQuest",Quest="CakeQuest",Mob="Cookie Savage",Pos=CFrame.new(-2050,33,-12180),MPos=CFrame.new(-2246,33,-12100)},
	[38]={Name="CakeGuard",Lvl=1450,NPC="CakeQuest",Quest="CakeQuest",Mob="Cake Guard",Pos=CFrame.new(-2050,33,-12180),MPos=CFrame.new(-2230,33,-12164)},
	-- Sea 3
	[39]={Name="Shark",Lvl=1500,NPC="MarineQuest3",Quest="MarineQuest3",Mob="Shark",Pos=CFrame.new(-3300,6,-9500),MPos=CFrame.new(-3400,6,-9600)},
	[40]={Name="FishmanRaider",Lvl=1550,NPC="FishmanQuest3",Quest="FishmanQuest3",Mob="Fishman Raider",Pos=CFrame.new(-11200,12,-5200),MPos=CFrame.new(-11350,12,-5350)},
	[41]={Name="SkyGuard",Lvl=1600,NPC="SkyQuest3",Quest="SkyQuest3",Mob="Sky Guard",Pos=CFrame.new(-4800,900,-2200),MPos=CFrame.new(-4900,900,-2300)},
	[42]={Name="PirateRaider",Lvl=1650,NPC="PirateQuest3",Quest="PirateQuest3",Mob="Pirate Raider",Pos=CFrame.new(14000,20,-2000),MPos=CFrame.new(14100,20,-2100)},
	[43]={Name="SnowKnight",Lvl=1700,NPC="SnowQuest3",Quest="SnowQuest3",Mob="Snow Knight",Pos=CFrame.new(1800,90,-2000),MPos=CFrame.new(1900,90,-2100)},
	[44]={Name="IceWarrior",Lvl=1750,NPC="IceQuest3",Quest="IceQuest3",Mob="Ice Warrior",Pos=CFrame.new(-2000,20,-15000),MPos=CFrame.new(-2100,20,-15100)},
	[45]={Name="FireRaider",Lvl=1800,NPC="FireQuest3",Quest="FireQuest3",Mob="Fire Raider",Pos=CFrame.new(-5800,20,-3000),MPos=CFrame.new(-5900,20,-3100)},
	[46]={Name="MagmaLord",Lvl=1850,NPC="MagmaQuest3",Quest="MagmaQuest3",Mob="Magma Lord",Pos=CFrame.new(-5500,50,8500),MPos=CFrame.new(-5600,50,8600)},
	[47]={Name="DesertSoldier",Lvl=1900,NPC="DesertQuest3",Quest="DesertQuest3",Mob="Desert Soldier",Pos=CFrame.new(900,10,4200),MPos=CFrame.new(1000,10,4300)},
	[48]={Name="SandWarrior",Lvl=1950,NPC="SandQuest3",Quest="SandQuest3",Mob="Sand Warrior",Pos=CFrame.new(1200,10,4500),MPos=CFrame.new(1300,10,4600)},
}

-- ==================== FRUIT DATA ====================
local FruitNames = {"Fruit","Apple","Banana","Cherry","Diamond","Dough","Dragon","Flame","Gravity","Ice","Light","Love","Magma","Pain","Phoenix","Quake","Rumble","Sand","Shadow","Smoke","Snow","Spider","Spirit","Spring","Venom","Dark","Bomb","Barrier","Blizzard","Buddha","Control","Door","Falcon","Ghost","Gum","Human","Kilo","Leopard","Magnet","Revive","Rubber","Spike","String","Dragon3","Gas","Mammoth","T-Rex","Yeti","Kitsune"}

-- ==================== CREATE UI ====================
local Win = DeniaLib:CreateWindow({
	Title = "DeniaHub v3.0",
	Key = Enum.KeyCode.RightShift,
	Size = UDim2.new(0, 680, 0, 560),
})

local StatusTab = Win:AddTab("Status", "◈")
local FarmTab = Win:AddTab("AutoFarm", "F")
local PvPTab = Win:AddTab("PvP", "T")
local RaceTab = Win:AddTab("Race V4", "R")
local SeaTab = Win:AddTab("Sea Event", "E")
local TpTab = Win:AddTab("Teleport", "T")
local CfgTab = Win:AddTab("Config", "C")

-- ==================== TAB 1: STATUS ====================
local stSec = StatusTab:AddSection("Overview")
local stLevel, stBounty, stPing, stFps

stSec:AddButtonGroup({
	{label = "Server Hop", callback = function() invokeServer("ServerHop") end},
	{label = "Reset", callback = function() pcall(function() getChar():BreakJoints() end) end},
	{label = "Rejoin", callback = function() TeleportService:Teleport(game.PlaceId, lp) end},
})

-- ==================== TAB 2: AUTO FARM ====================
local farmSec = FarmTab:AddSection("Auto Farm")
local farmStatus = "Idle"
local autoFarming = false; local masteryFarming = false
local autoRolling = false; local selectedWeapon = "Combat"

farmSec:AddToggle({label="Auto Farm Level",default=false,callback=function(v)autoFarming=v end})
farmSec:AddToggle({label="Auto Farm Mastery",default=false,callback=function(v)masteryFarming=v end})
farmSec:AddToggle({label="Auto Roll Fruit",default=false,callback=function(v)autoRolling=v end})
farmSec:AddDropdown({label="Weapon",options={"Combat","Saber","Dark Blade","Kabucha","Dragon Trident"},default="Combat",callback=function(v)selectedWeapon=v end})
local farmStatLbl = farmSec:AddLabel("Status: Idle")

local bringSec = FarmTab:AddSection("Mobs")
local bringingMobs = false; local bringRange = 200
bringSec:AddToggle({label="Bring Mobs",default=false,callback=function(v)bringingMobs=v end})
bringSec:AddSlider({label="Range",min=50,max=400,default=200,callback=function(v)bringRange=v end})

-- ==================== TAB 3: PVP ====================
local pvpSec = PvPTab:AddSection("Target")
local selectedTarget = "Select Player"; local aimbotEnabled = false
local autoBounty = false; local killAura = false; local fastAttack = false

local targetOpts = {"Select Player"}
pvpSec:AddDropdown({label="Target",options=targetOpts,default="Select Player",callback=function(v)selectedTarget=v end})

local btySec = PvPTab:AddSection("Auto Bounty")
btySec:AddToggle({label="Auto Bounty",default=false,callback=function(v)autoBounty=v end})
btySec:AddDropdown({label="Level Diff",options={"Any","+50","+100","+200","+500"},default="Any",callback=function()end})

local combSec = PvPTab:AddSection("Combat")
combSec:AddToggle({label="Fast Attack",default=false,callback=function(v)fastAttack=v end})
combSec:AddToggle({label="Aimbot",default=false,callback=function(v)aimbotEnabled=v end})
combSec:AddToggle({label="Kill Aura",default=false,callback=function(v)killAura=v end})
combSec:AddButtonGroup({{label="Start Hunting",callback=function()autoBounty=true end},{label="Stop",danger=true,callback=function()autoBounty=false end}})

-- ==================== TAB 4: RACE V4 ====================
local raceSec = RaceTab:AddSection("Race V4")
local currentRace = "Unknown"
local raceStatus = raceSec:AddLabel("Current Race: Unknown")
local raceProg = raceSec:AddProgress(0)
raceSec:AddButtonGroup({{label="Auto V4",callback=function()autoV4=not autoV4 end},{label="Check Race",callback=function()
	local d = invokeServer("GetRace"); if d then currentRace=tostring(d); raceStatus.Text="Current Race: "..currentRace end
end}})
local v4Sec = RaceTab:AddSection("V4 Abilities")
v4Sec:AddButtonGroup({{label="Auto Gear",callback=function()end},{label="Auto Trial",callback=function()end},{label="Auto Shrine",callback=function()end},{label="Auto Temple",callback=function()end}})

-- ==================== TAB 5: SEA EVENT ====================
local seaEv = SeaTab:AddSection("Sea Events")
local autoSeaEvent = false; local seaPriority = "All"
seaEv:AddToggle({label="Auto Sea Event",default=false,callback=function(v)autoSeaEvent=v end})
seaEv:AddDropdown({label="Priority",options={"All","Ship Only","Sea Beast","Leviathan"},default="All",callback=function(v)seaPriority=v end})
local fishSec = SeaTab:AddSection("Auto Fish")
fishSec:AddToggle({label="Auto Fish",default=false,callback=function(v)autoFishing=v end})

-- ==================== TAB 6: TELEPORT ====================
local tpSec = TpTab:AddSection("Teleport")
tpSec:AddButtonGroup({{label="Sea 1",callback=function()currentSea=1 end},{label="Sea 2",callback=function()currentSea=2 end},{label="Sea 3",callback=function()currentSea=3 end}})
local islandOpts = {}
tpSec:AddDropdown({label="Island",options=islandOpts,default="Select Island",callback=function()end})
local islGrid = tpSec:AddButtonGroup({{label="Jungle",callback=function()toTarget(CFrame.new(-1604,36,154))end},{label="Desert",callback=function()toTarget(CFrame.new(927,6,4177))end},{label="Snow",callback=function()toTarget(CFrame.new(1381,87,-1294))end},{label="Marine",callback=function()toTarget(CFrame.new(-2565,6,-665))end},{label="Sky",callback=function()toTarget(CFrame.new(-4860,715,-2648))end},{label="Magma",callback=function()toTarget(CFrame.new(-5417,6,8472))end},{label="Prison",callback=function()toTarget(CFrame.new(5300,2,470))end},{label="Colosseum",callback=function()toTarget(CFrame.new(-1839,5,-1084))end},{label="Fishman",callback=function()toTarget(CFrame.new(61163,11,1819))end},{label="Skypiea",callback=function()toTarget(CFrame.new(-4721,845,-1955))end}})

-- ==================== TAB 7: CONFIG ====================
local gen = CfgTab:AddSection("General")
gen:AddToggle({label="Low CPU Mode",default=false,callback=function(v)lowCPU=v end})
local wlSec = CfgTab:AddSection("Whitelist")
wlSec:AddDropdown({label="Mode",options={"Off","Friends","Guild","Custom"},default="Off",callback=function(v)whitelistMode=v end})
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
local fruitESP=true;local playerESP=true;local chestESP=false
espSec:AddToggle({label="Fruit ESP",default=true,callback=function(v)fruitESP=v;refreshESP()end})
espSec:AddToggle({label="Player ESP",default=true,callback=function(v)playerESP=v;refreshESP()end})
local progSec = CfgTab:AddSection("Sea Progression")
progSec:AddToggle({label="Auto Sea Progress",default=false,callback=function(v)autoSeaProg=v end})

-- ==================== FEATURE STATE VARS ====================
local autoV4 = false; local autoFishing = false; local lowCPU = false; local whitelistMode = "Off"
local sessionBounty = 0; local sessionKills = 0; local sessionStart = tick()
local currentSea = 1; local cd = 0

-- ==================== REAL COMBAT: RE/RegisterAttack + RE/RegisterHit (Banana Cat style) ====================
local Net = c:FindFirstChild("Modules") and c.Modules:FindFirstChild("Net")
local RegisterAttack = Net and Net:FindFirstChild("RE/RegisterAttack")
local RegisterHit = Net and Net:FindFirstChild("RE/RegisterHit")

-- ==================== REAL COMBAT: Azure CombatFramework ====================
local CombatController = nil

local function initCombatFramework()
	pcall(function()
		local plrScripts = lp:FindFirstChild("PlayerScripts")
		if not plrScripts then return end
		local cf = plrScripts:FindFirstChild("CombatFramework")
		if not cf then return end
		local ok, upvalues = pcall(getupvalues, require(cf))
		if not ok or not upvalues then return end
		local container = upvalues[2]
		if container and container.activeController then
			CombatController = container.activeController
		end
	end)
end

local function getCombatController()
	return CombatController
end

-- ==================== REAL ATTACK: dual method (RegisterAttack + activeController) ====================
local function doAttack()
	pcall(function()
		if not fastAttack then return end

		-- Method 1: FireServer RE/RegisterAttack + RE/RegisterHit (Banana Cat)
		if RegisterAttack and RegisterHit then
			local root = getRoot()
			local enemies = getEnemies()
			local targets = {}
			local basePart = nil
			for _, e in ipairs(enemies:GetChildren()) do
				local hrp = e:FindFirstChild("HumanoidRootPart")
				local hum = e:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 and root then
					local dist = (hrp.Position - root.Position).Magnitude
					if dist <= (bringRange or 200) then
						local parts = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"}
						local hitPart = e:FindFirstChild(parts[math.random(#parts)]) or hrp
						table.insert(targets, {e, hitPart})
						basePart = basePart or hitPart
					end
				end
			end
			if basePart and #targets > 0 then
				RegisterAttack:FireServer(0)
				task.wait(0.02)
				RegisterHit:FireServer(basePart, targets)
			end
		end

		-- Method 2: CombatFramework activeController:attack() (Azure)
		local ctrl = getCombatController()
		if ctrl then
			ctrl.hitboxMagnitude = 200
			ctrl.timeToNextBlock = 0
			ctrl.timeToNextAttack = 0
			ctrl.attacking = false
			task.spawn(function()
				pcall(function() ctrl:attack() end)
			end)
		end

		-- Simulation radius
		pcall(function()
			if sethiddenproperty then
				sethiddenproperty(lp, "SimulationRadius", math.huge)
			end
		end)
	end)
end

-- ==================== REAL TWEEN MOVEMENT: ToTarget (Azure style) ====================
local function toTarget(cframe)
	task.spawn(function()
		pcall(function()
			local root = getRoot()
			if not root then return end
			local dist = (root.Position - cframe.Position).Magnitude
			if dist <= 300 then
				root.CFrame = cframe
				return
			end
			local char = getChar()
			local anchorPart = char:FindFirstChild("RootTween")
			if not anchorPart then
				anchorPart = Instance.new("Part")
				anchorPart.Name = "RootTween"
				anchorPart.Size = Vector3.new(1, 0.5, 1)
				anchorPart.Anchored = true
				anchorPart.Transparency = 1
				anchorPart.CanCollide = false
				anchorPart.Parent = char
			end
			anchorPart.CFrame = root.CFrame * CFrame.new(0, 20, 0)
			local speed = 350
			local duration = (cframe.Position - anchorPart.Position).Magnitude / speed
			local tween = TweenService:Create(anchorPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = cframe})
			tween:Play()
			task.spawn(function()
				while tween.PlaybackState == Enum.PlaybackState.Playing do
					task.wait(0.1)
					pcall(function()
						if root and anchorPart and (root.Position - anchorPart.Position).Magnitude >= 150 then
							anchorPart.CFrame = root.CFrame * CFrame.new(0, 20, 0)
						end
						if root and anchorPart then
							root.CFrame = anchorPart.CFrame * CFrame.new(0, -20, 0)
						end
					end)
				end
			end)
		end)
	end)
end

-- ==================== REAL BRING MOBS (Banana Cat + Azure hybrid) ====================
local function doBringMobs()
	if not bringingMobs then return end
	local root = getRoot()
	if not root then return end
	for _, e in ipairs(getEnemies():GetChildren()) do
		local hrp = e:FindFirstChild("HumanoidRootPart")
		local hum = e:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local dist = (hrp.Position - root.Position).Magnitude
			if dist <= (bringRange or 200) then
				pcall(function()
					hrp.CanCollide = false
					hrp.CFrame = root.CFrame * CFrame.new(math.random(-8, 8), 0, math.random(-8, 8))
					hum.WalkSpeed = 0
					hum.JumpPower = 0
					if hum:FindFirstChildOfClass("Animator") then
						hum.Animator:Destroy()
					end
					-- BodyVelocity to pull (Azure style)
					if not hrp:FindFirstChild("BV") then
						local bv = Instance.new("BodyVelocity")
						bv.Name = "BV"
						bv.MaxForce = Vector3.new(100000, 100000, 100000)
						bv.Velocity = Vector3.new(0, 0, 0)
						bv.Parent = hrp
					end
				end)
			end
		end
	end
end

-- ==================== REAL __NAMECALL AIMBOT (Banana Cat style) ====================
local aimbotHooked = false
local MousePos = Vector3.new(0, 0, 0)

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
						args[2] = MousePos
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

-- ==================== REAL AUTO FARM (Banana Cat quest logic) ====================
local function checkHasQuest(mobName)
	pcall(function()
		local questGui = lp.PlayerGui:FindFirstChild("Main") and lp.PlayerGui.Main:FindFirstChild("Quest")
		if not questGui then return false end
		if not questGui.Visible then return false end
		local container = questGui:FindFirstChild("Container")
		if not container then return false end
		local title = container:FindFirstChild("QuestTitle")
		if not title then return false end
		return title.Title.Text:find(mobName) and true or false
	end)
	return false
end

local function findBestQuest()
	local level = lp.Data and lp.Data:FindFirstChild("Level") and lp.Data.Level.Value or 1
	local best, bestIdx = nil, nil
	for i, q in ipairs(QuestData) do
		if level >= q.Lvl then best = q; bestIdx = i end
	end
	return best, bestIdx
end

local function autoFarmLoop()
	local rootCheck = getRoot()
	if not rootCheck then return end

	local levelData = lp.Data and lp.Data:FindFirstChild("Level")
	local plyrLevel = levelData and levelData.Value or 1

	-- Auto sea progression
	if autoSeaProg then
		if game.PlaceId == FIRST_SEA and plyrLevel >= 700 then
			invokeServer("TravelDressrosa")
			task.wait(5)
		elseif game.PlaceId == SECOND_SEA and plyrLevel >= 1500 then
			invokeServer("TravelZou")
			task.wait(5)
		end
	end

	local quest, qIdx = findBestQuest()
	if not quest then return end

	-- Check if we have the quest active (Banana Cat CheckHasQuest style)
	local hasQuest = false
	pcall(function()
		local qGui = lp.PlayerGui.Main.Quest
		if qGui and qGui.Visible then
			local qTitle = qGui.Container.QuestTitle.Title
			if qTitle.Text:find(quest.Mob) then
				hasQuest = true
			end
		end
	end)

	if not hasQuest then
		farmStatus = "Travel to quest"
		toTarget(quest.Pos)
		task.wait(1)
		if getRoot() and (getRoot().Position - quest.Pos.Position).Magnitude <= 10 then
			invokeServer("StartQuest", quest.Quest, qIdx)
			farmStatus = "Quest: "..quest.Name
			task.wait(0.5)
		end
	end

	-- Kill mobs
	local enemies = getEnemies()
	for _, e in ipairs(enemies:GetChildren()) do
		local hrp = e:FindFirstChild("HumanoidRootPart")
		local hum = e:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local eName = e.Name
			if eName:find(quest.Mob) or eName == quest.Mob then
				local root = getRoot()
				if not root then return end
				local dist = (hrp.Position - root.Position).Magnitude
				if dist <= (bringRange or 200) then
					farmStatus = "Killing "..quest.Mob
					-- Teleport in front of mob (Banana Cat style)
					hrp.CFrame = root.CFrame * CFrame.new(0, 0, -5)
					task.wait(0.05)
					doAttack()
					task.wait(0.1)
					doAttack()
				end
			end
		end
	end

	-- Check completion
	pcall(function()
		local qGui = lp.PlayerGui.Main.Quest
		if qGui and qGui.Visible == false then
			invokeServer("CompleteQuest")
			sessionBounty = sessionBounty + 1
			farmStatus = "Completed!"
			task.wait(0.3)
		end
	end)

	-- Auto stat
	pcall(function()
		local points = lp.Data and lp.Data:FindFirstChild("Points")
		if points and points.Value > 0 then
			invokeServer("AddPoint", "Melee", points.Value)
		end
	end)
end

-- ==================== REAL NOCLIP + BODYCLIP (Banana Cat style) ====================
local function doNoclip()
	if not noclipEnabled then return end
	pcall(function()
		local char = getChar()
		local root = getRoot()
		if not char or not root then return end
		-- BodyClip (BodyVelocity anti-push)
		if not root:FindFirstChild("BodyClip") then
			local bv = Instance.new("BodyVelocity")
			bv.Name = "BodyClip"
			bv.MaxForce = Vector3.new(100000, 100000, 100000)
			bv.Velocity = Vector3.new(0, 0, 0)
			bv.Parent = root
		end
		-- CanCollide false on all parts
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

-- ==================== REAL ESP ====================
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
	bill.StudsOffset = Vector3.new(0, 1, 0)
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
	for _, v in ipairs(Workspace:GetChildren()) do
		local isFruit = false
		for _, n in ipairs(FruitNames) do
			if v.Name:find(n) then isFruit = true; break end
		end
		if isFruit and v:FindFirstChild("Handle") then
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
				lbl.Text = "🌟 "..v.Name
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

-- ==================== REAL VISUAL CLEANUP (Azure style) ====================
local function doVisualCleanup()
	pcall(function()
		local wOrigin = Workspace:FindFirstChild("_WorldOrigin")
		if not wOrigin then return end
		wOrigin.ChildAdded:Connect(function(w)
			pcall(function()
				if w.Name == "CurvedRing" or w.Name == "SlashHit" or w.Name == "DamageCounter" or w.Name == "SwordSlash" or w.Name == "SlashTail" or w.Name == "Sounds" then
					w:Destroy()
				end
			end)
		end)
	end)
end

-- ==================== REAL AUTO HAKI (Azure style) ====================
local function doAutoHaki()
	pcall(function()
		if not lp.Character:FindFirstChild("HasBuso") then
			invokeServer("Buso")
		end
		if CommE then
			CommE:FireServer("Ken", true)
		end
		local char = getChar()
		if char then
			local stun = char:FindFirstChild("Stun")
			if stun then stun.Value = 0 end
			local busy = char:FindFirstChild("Busy")
			if busy then busy.Value = false end
			local hum = getHumanoid()
			if hum then hum.Sit = false end
		end
	end)
end

-- ==================== SIMULATION RADIUS (Azure style - every frame) ====================
RunService.RenderStepped:Connect(function()
	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(lp, "SimulationRadius", math.huge * math.huge)
		end
	end)
end)

-- ==================== HEARTBEAT LOOP ====================
local fpsCounter = 0; local fpsTime = 0; local currentFps = 60; local fpsUpdateTick = 0
local farmTick = 0; local hakiTick = 0

RunService.Heartbeat:Connect(function(dt)
	dt = dt or 0.016
	fpsCounter = fpsCounter + 1
	fpsTime = fpsTime + dt
	if fpsTime >= 1 then
		currentFps = fpsCounter
		fpsCounter = 0
		fpsTime = 0
	end

	-- Dynamic Island
	if fpsUpdateTick <= 0 then
		Win:UpdateDI(currentFps, farmStatus)
		fpsUpdateTick = 2
	else
		fpsUpdateTick = fpsUpdateTick - dt
	end

	-- Noclip
	doNoclip()

	-- Bring mobs
	doBringMobs()

	-- Auto bounty
	if autoBounty then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp and p.Character then
				local hrp = p.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local root = getRoot()
					if root and (hrp.Position - root.Position).Magnitude <= 300 then
						toTarget(hrp.CFrame * CFrame.new(0, 0, -8))
						task.wait(0.1)
						doAttack()
					end
				end
			end
		end
	end

	-- Auto farm tick
	farmTick = farmTick + dt
	if farmTick >= 0.5 and (autoFarming or masteryFarming) then
		farmTick = 0
		autoFarmLoop()
		if farmStatLbl then farmStatLbl.Text = "Status: "..farmStatus end
	end

	-- Auto haki tick
	hakiTick = hakiTick + dt
	if hakiTick >= 1 then
		hakiTick = 0
		doAutoHaki()
	end

	-- Aimbot: update MousePos to selected target
	if aimbotEnabled and selectedTarget and selectedTarget ~= "Select Player" then
		local targetPlayer = Players:FindFirstChild(selectedTarget:match("^[^%[]+"))
		if targetPlayer and targetPlayer.Character then
			local h = targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetPlayer.Character:FindFirstChild("Head")
			if h then
				MousePos = h.Position
			end
		end
	end

	-- Update server info
	local lvl = lp.Data and lp.Data:FindFirstChild("Level") and lp.Data.Level.Value or 1
	Win:UpdateServerInfo({fps = currentFps, level = lvl, bounty = sessionBounty})
end)

-- ==================== INIT ====================
task.spawn(function() task.wait(1)
	setupAimbot()
	initCombatFramework()
	-- Animation speed hack (Azure wrapAttackAnimationAsync) — one-time override
	pcall(function()
		local RigLib = c:FindFirstChild("CombatFramework") and require(c.CombatFramework.RigLib)
		if RigLib and RigLib.wrapAttackAnimationAsync then
			RigLib.wrapAttackAnimationAsync = function(self, animId, length, blend, callback)
				local hits = RigLib.getBladeHits and RigLib.getBladeHits(animId, length, blend) or {}
				if hits then
					self:Play(1.0E-5, 1.0E-5, 1.0E-5)
					if callback then callback(hits) end
				else
					if callback then callback({}) end
				end
			end
		end
		-- Disable particles
		local Particle = c:FindFirstChild("CombatFramework") and require(c.CombatFramework.Particle)
		if Particle then Particle.play = function() return end end
		-- Disable camera shake
		local Shaker = c:FindFirstChild("CombatFramework") and require(c.CombatFramework.CameraShaker)
		if Shaker and Shaker.CameraShakeInstance then
			Shaker.CameraShakeInstance.CameraShakeState = {FadingIn=3,FadingOut=2,Sustained=0,Inactive=1}
		end
	end)
end)

-- ESP init + visual cleanup
task.spawn(function() task.wait(2) refreshESP() end)
task.spawn(function() task.wait(3) doVisualCleanup() end)

-- ESP on player join/leave
Players.PlayerAdded:Connect(function() task.wait(1) refreshESP() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) refreshESP() end)

-- Auto stat loop
task.spawn(function()
	while true do
		task.wait(1)
		pcall(function()
			local pts = lp.Data and lp.Data:FindFirstChild("Points")
			if pts and pts.Value > 0 then
				local t = pts.Value
				if autoStatMelee then invokeServer("AddPoint", "Melee", t) end
				if autoStatDefense then invokeServer("AddPoint", "Defense", t) end
				if autoStatSword then invokeServer("AddPoint", "Sword", t) end
				if autoStatGun then invokeServer("AddPoint", "Gun", t) end
				if autoStatFruit then invokeServer("AddPoint", "DevilFruit", t) end
			end
		end)
	end
end)

-- Auto sea progression loop
task.spawn(function()
	while true do
		task.wait(5)
		if autoSeaProg then
			local lvl = lp.Data and lp.Data:FindFirstChild("Level") and lp.Data.Level.Value or 1
			if game.PlaceId == FIRST_SEA and lvl >= 700 then invokeServer("TravelDressrosa")
			elseif game.PlaceId == SECOND_SEA and lvl >= 1500 then invokeServer("TravelZou") end
		end
	end
end)

-- Auto roll fruit loop
task.spawn(function()
	while true do
		task.wait(60)
		if autoRolling then pcall(function() invokeServer("RollFruit") end) end
	end
end)

-- Notify
pcall(function()
	StarterGui:SetCore("SendNotification", {Title = "DeniaHub v3.0", Text = "Loaded. Press RightShift to toggle.", Duration = 4})
end)

print("DeniaHub v3.0 loaded!")
