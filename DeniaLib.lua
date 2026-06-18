-- DeniaLib.lua v3.0 — Baby Pink UI Library for Roblox
-- All components are custom-built, no default Roblox styling
-- Lua 5.1 compatible | No goto, no continue, no Font.fromId

local DeniaLib = {}
local Services = setmetatable({}, {__index = function(s, k)
	local ok, sv = pcall(function() return game:GetService(k) end)
	if ok then s[k] = sv; return sv end
end})

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local CoreGui = Services.CoreGui

-- Icons (Lucide-style, subset from icon.txt)
local Icons = {
	activity = "rbxassetid://94212016861936",
	zap = "rbxassetid://130551565616516",
	crosshair = "rbxassetid://134242818164054",
	trophy = "rbxassetid://131545003268773",
	anchor = "rbxassetid://92181172123618",
	compass = "rbxassetid://115123411028382",
	cog = "rbxassetid://116544501716299",
	check = "rbxassetid://93898873302694",
	minus = "rbxassetid://118026365011536",
	x = "rbxassetid://76821953846248",
	["chevron-down"] = "rbxassetid://134243273101015",
	["chevron-up"] = "rbxassetid://122444883127455",
	info = "rbxassetid://124560466474914",
	bolt = "rbxassetid://102881251417484",
	sword = "rbxassetid://124448418211665",
	map_pin = "rbxassetid://84279202219901",
	settings = "rbxassetid://80758916183665",
	shield = "rbxassetid://110987169760162",
	star = "rbxassetid://136141469398409",
	flame = "rbxassetid://98218034436456",
	skull = "rbxassetid://137726256442333",
	eye = "rbxassetid://100033680381365",
	heart = "rbxassetid://116559368303288",
	users = "rbxassetid://115398113982385",
	target = "rbxassetid://87563802520297",
	flag = "rbxassetid://78183383236196",
	ship = "rbxassetid://83995100553930",
	fish = "rbxassetid://124360663785796",
	droplet = "rbxassetid://100597455015098",
	sun = "rbxassetid://110150589884127",
	moon = "rbxassetid://83380517901735",
}

-- Theme — Glass Pink (Glassmorphism)
local Theme = {
	Base = Color3.fromRGB(6, 5, 10),
	Surface = Color3.fromRGB(10, 8, 16),
	Surface2 = Color3.fromRGB(16, 12, 24),
	Surface3 = Color3.fromRGB(22, 16, 32),
	Surface4 = Color3.fromRGB(30, 22, 44),
	Accent = Color3.fromRGB(255, 150, 190),
	Accent2 = Color3.fromRGB(240, 80, 140),
	Accent3 = Color3.fromRGB(220, 40, 110),
	Accent4 = Color3.fromRGB(180, 20, 90),
	Text = Color3.fromRGB(220, 208, 218),
	Text2 = Color3.fromRGB(150, 132, 148),
	Text3 = Color3.fromRGB(100, 85, 95),
	Bright = Color3.fromRGB(245, 235, 240),
	Danger = Color3.fromRGB(255, 90, 75),
	Warning = Color3.fromRGB(240, 190, 80),
	Info = Color3.fromRGB(80, 170, 240),
	Border = Color3.fromRGB(255, 150, 190),
	Glass = Color3.fromRGB(255, 180, 210),
}
local BorderTrans = 0.55
local BorderTrans2 = 0.7
local GlassTrans = 0.65  -- glass background transparency

-- Utility functions
local function new(class, props)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	return obj
end

local function mkRound(frame, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = frame
end

local function mkGradient(frame, color1, color2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2 or color1)})
	if rotation then g.Rotation = rotation end
	g.Parent = frame
	return g
end

local function mkShadow(frame, transparency, offset, size)
	local s = Instance.new("UIStroke")
	s.Color = Theme.Border
	s.Transparency = transparency or BorderTrans
	s.Thickness = 0.5
	s.Parent = frame
	return s
end

-- Glassmorphism effect: translucent background + border stroke + shine gradient
local function mkGlass(frame, bgTransparency, borderColor, borderTransparency)
	bgTransparency = bgTransparency or GlassTrans
	frame.BackgroundTransparency = bgTransparency
	local stroke = Instance.new("UIStroke")
	stroke.Color = borderColor or Theme.Border
	stroke.Transparency = borderTransparency or BorderTrans2
	stroke.Thickness = 1
	stroke.Parent = frame
	-- Subtle shine gradient overlay
	local shine = Instance.new("UIGradient")
	shine.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255):lerp(frame.BackgroundColor3, 0.97)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255):lerp(frame.BackgroundColor3, 0.99)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255):lerp(frame.BackgroundColor3, 0.97)),
	})
	shine.Transparency = NumberSequence.new(0.85)
	shine.Rotation = 45
	shine.Parent = frame
	return stroke
end

local UIList = function(parent, dir, pad, gap)
	local l = Instance.new("UIListLayout")
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.HorizontalAlignment = Enum.HorizontalAlignment.Left
	l.VerticalAlignment = Enum.VerticalAlignment.Top
	l.Padding = UDim.new(0, gap or 6)
	l.Parent = parent
	return l
end

local UIPad = function(parent, pad)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, pad)
	p.PaddingRight = UDim.new(0, pad)
	p.PaddingTop = UDim.new(0, pad)
	p.PaddingBottom = UDim.new(0, pad)
	p.Parent = parent
	return p
end

-- Dynamic Island — RED theme, shows FPS • NPC/Mob • Player
local DynIsland = nil
local function CreateDynamicIsland(parentGui)
	if DynIsland then return end

	local PINK = Color3.fromRGB(255, 150, 190)
	local PINK2 = Color3.fromRGB(240, 80, 140)
	local PINK3 = Color3.fromRGB(200, 130, 160)

	DynIsland = new("Frame", {
		Name = "DynIsland",
		Size = UDim2.new(0, 0, 0, 44),
		Position = UDim2.new(0.5, 0, 0, 12),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 130, 170),
		BorderSizePixel = 0,
		Visible = false,
		Parent = parentGui,
		ZIndex = 9999,
	})
	mkRound(DynIsland, 22)
	mkGlass(DynIsland, 0.75, Color3.fromRGB(255, 150, 190), 0.5)

	-- Pink pulse dot (glass style)
	local pulse = new("Frame", {
		Size = UDim2.new(0, 8, 0, 8),
		Position = UDim2.new(0, 12, 0.5, -4),
		BackgroundColor3 = PINK,
		BorderSizePixel = 0,
		Parent = DynIsland,
	})
	mkRound(pulse, 4)
	mkGlass(pulse, 0.3, PINK, 0.3)

	-- FPS value (PINK)
	local fpsLabel = new("TextLabel", {
		Size = UDim2.new(0, 36, 1, 0),
		Position = UDim2.new(0, 26, 0, 0),
		BackgroundTransparency = 1,
		Text = "60",
		TextColor3 = PINK,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = DynIsland,
	})
	local fpsSuffix = new("TextLabel", {
		Size = UDim2.new(0, 26, 1, 0),
		Position = UDim2.new(0, 62, 0, 0),
		BackgroundTransparency = 1,
		Text = "FPS",
		TextColor3 = PINK2,
		TextSize = 10,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = DynIsland,
	})

	-- Separator 1 (glass)
	local sep1 = new("Frame", {
		Size = UDim2.new(0, 1, 0, 22),
		Position = UDim2.new(0, 92, 0.5, -11),
		BackgroundColor3 = PINK,
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		Parent = DynIsland,
	})

	-- NPC / Mob name (PINK)
	local npcLabel = new("TextLabel", {
		Size = UDim2.new(0, 120, 1, 0),
		Position = UDim2.new(0, 100, 0, 0),
		BackgroundTransparency = 1,
		Text = "Idle",
		TextColor3 = PINK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = DynIsland,
	})

	-- Separator 2 (glass)
	local sep2 = new("Frame", {
		Size = UDim2.new(0, 1, 0, 22),
		Position = UDim2.new(0, 224, 0.5, -11),
		BackgroundColor3 = PINK,
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		Parent = DynIsland,
	})

	-- Player name (PINK)
	local playerLabel = new("TextLabel", {
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(0, 232, 0, 0),
		BackgroundTransparency = 1,
		Text = "...",
		TextColor3 = PINK2,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = DynIsland,
	})

	-- Arrow indicator (pink)
	local arrow = new("TextLabel", {
		Size = UDim2.new(0, 18, 1, 0),
		Position = UDim2.new(1, -22, 0, 0),
		BackgroundTransparency = 1,
		Text = "◂",
		TextColor3 = PINK3,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		Parent = DynIsland,
	})

	-- Pulse animation — tự động dừng khi DynIsland bị destroy
	local diAlive = true
	DynIsland.Destroying:Connect(function() diAlive = false; DynIsland = nil end)
	task.spawn(function()
		while diAlive do
			TweenService:Create(pulse, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 0.4
			}):Play()
			task.wait(0.8)
			TweenService:Create(pulse, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 0
			}):Play()
			task.wait(0.8)
		end
	end)

	local targetSize = UDim2.new(0, 360, 0, 42)
	DynIsland._expand = function()
		TweenService:Create(DynIsland, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = targetSize}):Play()
	end
	DynIsland._collapse = function()
		TweenService:Create(DynIsland, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 42)}):Play()
	end

	DynIsland._updateFps = function(val)
		fpsLabel.Text = tostring(val)
	end
	DynIsland._updateFarm = function(text)
		npcLabel.Text = text or "Idle"
	end
	DynIsland._updatePlayer = function(name)
		playerLabel.Text = name or "..."
	end

	DynIsland.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			DynIsland._maximizeRequested = true
		end
	end)

	DynIsland._maximizeRequested = false
	return DynIsland
end

-- Window class
function DeniaLib:CreateWindow(config)
	config = config or {}
	local title = config.Title or "DeniaHub"
	local toggleKey = config.Key or Enum.KeyCode.RightShift
	local windowSize = config.Size or UDim2.new(0, 680, 0, 560)

	-- Ensure GUI
	local gui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "DeniaHubGui"
		gui.ResetOnSpawn = false
		gui.Parent = CoreGui
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DeniaHub"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = gui
	screenGui.DisplayOrder = 999

	-- Shroud (glass overlay)
	local shroud = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 150, 190),
		BackgroundTransparency = 0.85,
		Visible = false,
		Parent = screenGui,
	})
	mkRound(shroud, 20)

	-- Main Window (glass)
	local main = new("Frame", {
		Name = "MainWindow",
		Size = windowSize,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 140, 180),
		BorderSizePixel = 0,
		Parent = screenGui,
		ClipsDescendants = true,
	})
	mkRound(main, 20)
	mkGlass(main, 0.82, Color3.fromRGB(255, 150, 190), 0.4)

	-- Window inner glow
	local innerGlow = new("Frame", {
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2),
		BackgroundColor3 = Color3.fromRGB(255, 180, 210),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = main,
	})
	mkRound(innerGlow, 18)

	-- Topbar (glass)
	local topbar = new("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = Color3.fromRGB(255, 160, 200),
		BorderSizePixel = 0,
		Parent = main,
	})
	mkRound(topbar, 20)
	mkGlass(topbar, 0.78, Color3.fromRGB(255, 150, 190), 0.5)

	local topBorder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = topbar,
	})

	-- Brand
	local brand = new("Frame", {
		Size = UDim2.new(0, 120, 1, 0),
		BackgroundTransparency = 1,
		Parent = topbar,
	})
	local logo = new("Frame", {
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(0, 14, 0.5, -16),
		BackgroundColor3 = Color3.fromRGB(255, 160, 200),
		BorderSizePixel = 0,
		Parent = brand,
	})
	mkRound(logo, 10)
	mkGlass(logo, 0.3, Theme.Accent, 0.2)
	mkGradient(logo, Theme.Accent3, Theme.Accent, 135)
	local logoText = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "DH",
		TextColor3 = Theme.Base,
		TextSize = 13,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		Parent = logo,
	})
	local titleLabel = new("TextLabel", {
		Size = UDim2.new(0, 80, 1, 0),
		Position = UDim2.new(0, 50, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Bright,
		TextSize = 17,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = brand,
	})

	-- Server Info
	local sInfo = new("Frame", {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0, 120, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = topbar,
	})
	local infoLayout = UIList(sInfo, Enum.FillDirection.Horizontal, 0, 4)
	infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIPad(sInfo, 8)

	local function makeInfoItem(label, getValue)
		local frame = new("Frame", {
			Size = UDim2.new(0, 1, 0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Color3.fromRGB(255, 150, 190),
			BorderSizePixel = 0,
		})
		mkRound(frame, 8)
		mkGlass(frame, 0.7, Theme.Border, 0.6)

		local dot = new("Frame", {
			Size = UDim2.new(0, 6, 0, 6),
			Position = UDim2.new(0, 8, 0.5, -3),
			BackgroundColor3 = Theme.Accent2,
			BorderSizePixel = 0,
		})
		mkRound(dot, 3)
		dot.Parent = frame

		local val = new("TextLabel", {
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(0, 17, 0, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = getValue and getValue() or "—",
			TextColor3 = Theme.Bright,
			TextSize = 10.5,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		val.Parent = frame

		local lbl = new("TextLabel", {
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(0, val.Size.X.Offset + 17, 0, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = Theme.Text3,
			TextSize = 10,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		frame.Parent = sInfo

		-- reposition label based on val's actual text width
		local function refresh()
			val.Text = getValue and getValue() or "—"
			lbl.Position = UDim2.new(0, val.TextBounds.X + 17, 0, 0)
		end
		-- correct initial label position after layout
		task.spawn(function() task.wait() refresh() end)
		return frame, refresh
	end

	-- Info items — store refresh callbacks so UpdateServerInfo can update the UI
	local infoRefs = {}
	do
		local _, r = makeInfoItem("ms", function() return tostring(infoRefs.ping or 0) end)
		infoRefs._pingRefresh = r
	end
	do
		local _, r = makeInfoItem("FPS", function() return tostring(infoRefs.fps or 60) end)
		infoRefs._fpsRefresh = r
	end
	do
		local _, r = makeInfoItem("Lv.", function() return tostring(infoRefs.level or 1) end)
		infoRefs._lvlRefresh = r
	end
	do
		local _, r = makeInfoItem("Bounty", function() return tostring(infoRefs.bounty or "0") end)
		infoRefs._btyRefresh = r
	end

	-- Topbar actions
	local actions = new("Frame", {
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.new(1, -70, 0, 0),
		BackgroundTransparency = 1,
		Parent = topbar,
	})
	local actLayout = UIList(actions, Enum.FillDirection.Horizontal, 0, 6)
	actLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local minimizeBtn = new("TextButton", {
		Size = UDim2.new(0, 32, 0, 32),
		BackgroundColor3 = Color3.fromRGB(255, 160, 200),
		BorderSizePixel = 0,
		Text = "−",
		TextColor3 = Theme.Text2,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = actions,
	})
	mkRound(minimizeBtn, 10)
	mkGlass(minimizeBtn, 0.6, Theme.Border, 0.6)
	minimizeBtn.MouseEnter:Connect(function()
		TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.4, TextColor3 = Theme.Bright}):Play()
	end)
	minimizeBtn.MouseLeave:Connect(function()
		TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6, TextColor3 = Theme.Text2}):Play()
	end)

	local closeBtn = new("TextButton", {
		Size = UDim2.new(0, 32, 0, 32),
		BackgroundColor3 = Color3.fromRGB(255, 100, 120),
		BorderSizePixel = 0,
		Text = "✕",
		TextColor3 = Theme.Text2,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = actions,
	})
	mkRound(closeBtn, 10)
	mkGlass(closeBtn, 0.6, Color3.fromRGB(255, 80, 100), 0.5)
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3, TextColor3 = Color3.fromRGB(255, 200, 200)}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6, TextColor3 = Theme.Text2}):Play()
	end)

	-- Tab bar (glass)
	local tabBar = new("Frame", {
		Name = "TabBar",
		Size = UDim2.new(1, 0, 0, 42),
		Position = UDim2.new(0, 0, 0, 52),
		BackgroundColor3 = Color3.fromRGB(255, 150, 190),
		BorderSizePixel = 0,
		Parent = main,
	})
	mkRound(tabBar, 20)
	mkGlass(tabBar, 0.8, Color3.fromRGB(255, 150, 190), 0.6)
	local tabBorder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = tabBar,
	})
	local tabContainer = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.X,
		Parent = tabBar,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
	})
	local tabLayout = UIList(tabContainer, Enum.FillDirection.Horizontal, 0, 2)
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIPad(tabContainer, 8)

	-- Body (glass)
	local body = new("ScrollingFrame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -94),
		Position = UDim2.new(0, 0, 0, 94),
		BackgroundColor3 = Color3.fromRGB(255, 140, 180),
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = main,
	})
	mkRound(body, 20)
	local bodyPadding = UIPad(body, 14)
	local bodyLayout = UIList(body, Enum.FillDirection.Vertical, 0, 10)
	bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- Window dragging — store connections để cleanup
	local dragging, dragStart, startPos
	local dragCons = {}
	dragCons[1] = topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	dragCons[2] = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	dragCons[3] = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	-- Dynamic Island
	local di = CreateDynamicIsland(screenGui)
	if di then
		di._expand()
	end

	-- Minimize/Maximize
	local minimized = false
	local function minify()
		if minimized then return end
		minimized = true
		main.Visible = false
		if di then
			di.Visible = true
			di._expand()
			di._maximizeRequested = false
		end
	end
	local function maxify()
		if not minimized then return end
		minimized = false
		main.Visible = true
		if di then
			di._collapse()
			task.delay(0.3, function() di.Visible = false end)
		end
	end

	minimizeBtn.MouseButton1Click:Connect(minify)
	closeBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	if di then
		di.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				maxify()
			end
		end)
	end

	-- Toggle key
	local toggleCon = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then
			if minimized then maxify() else minify() end
		end
	end)

	-- Tab system
	local tabs = {}
	local activeTab = nil
	local tabObjects = {}

	local function switchTab(tabIdx)
		if activeTab == tabIdx then return end
		activeTab = tabIdx
		for idx, tabObj in pairs(tabObjects) do
			local isActive = idx == tabIdx
			TweenService:Create(tabObj.Button, TweenInfo.new(0.2), {
				TextColor3 = isActive and Theme.Bright or Theme.Text3,
			}):Play()
			if tabObj.Icon then
				TweenService:Create(tabObj.Icon, TweenInfo.new(0.2), {
					ImageColor3 = isActive and Theme.Accent or Theme.Text3,
				}):Play()
			end
			tabObj.Page.Visible = isActive
		end
		body.CanvasPosition = Vector2.new(0, 0)
	end

	local WindowObj = {}

	function WindowObj:AddTab(name, iconName)
		local idx = #tabs + 1
		local tabBtn = new("TextButton", {
			Size = UDim2.new(0, 1, 0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Parent = tabContainer,
		})
		UIPad(tabBtn, 10)

		local iconId = Icons[iconName]
		local tabIcon = new("ImageLabel", {
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0, 0, 0.5, -8),
			BackgroundTransparency = 1,
			Image = iconId or "",
			ImageColor3 = Theme.Text3,
			Parent = tabBtn,
		})
		local tabLbl = new("TextLabel", {
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(0, iconId and 22 or 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Theme.Text3,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = tabBtn,
		})

		-- Tab underline (active indicator)
		local underline = new("Frame", {
			Size = UDim2.new(1, -20, 0, 2.5),
			Position = UDim2.new(0, 10, 1, 0),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Visible = false,
			Parent = tabBtn,
		})
		mkRound(underline, 2)

		-- Page
		local page = new("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent4,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = #tabs == 0,
			Parent = body,
		})
		local pagePadding = UIPad(page, 0)
		local pageLayout = UIList(page, Enum.FillDirection.Vertical, 0, 10)
		pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local tabInfo = {Button = tabBtn, Page = page, Underline = underline, Icon = iconName and tabIcon or nil}
		tabObjects[idx] = tabInfo
		tabs[idx] = tabInfo

		if #tabs == 1 then
			activeTab = 1
			tabBtn.TextColor3 = Theme.Bright
			if tabIcon then tabIcon.ImageColor3 = Theme.Accent end
			underline.Visible = true
			page.Visible = true
		end

		tabBtn.MouseButton1Click:Connect(function()
			switchTab(idx)
			for _, t in pairs(tabObjects) do
				t.Underline.Visible = false
			end
			if tabIcon then
				TweenService:Create(tabIcon, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {ImageColor3 = Theme.Accent}):Play()
			end
			TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, -20, 0, 2.5)}):Play()
			underline.Visible = true
		end)
		tabBtn.MouseEnter:Connect(function()
			if activeTab ~= idx then
				TweenService:Create(tabBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Text2}):Play()
				if tabIcon then
					TweenService:Create(tabIcon, TweenInfo.new(0.15), {ImageColor3 = Theme.Text2}):Play()
				end
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if activeTab ~= idx then
				TweenService:Create(tabBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Text3}):Play()
				if tabIcon then
					TweenService:Create(tabIcon, TweenInfo.new(0.15), {ImageColor3 = Theme.Text3}):Play()
				end
			end
		end)

		-- Section/Page methods
		local PageObj = {}

		function PageObj:AddSection(sectionTitle)
			local card = new("Frame", {
				Size = UDim2.new(1, -0, 0, 1),
				BackgroundColor3 = Color3.fromRGB(255, 140, 180),
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = page,
			})
			mkRound(card, 16)
			mkGlass(card, 0.75, Theme.Border, 0.5)

			-- Card Header (glass)
			local header = new("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Color3.fromRGB(255, 160, 200),
				BorderSizePixel = 0,
				Parent = card,
			})
			mkRound(header, 16)
			mkGlass(header, 0.7, Theme.Border, 0.6)
			local hdrBorder = new("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Theme.Border,
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Parent = header,
			})

			-- Collapse button (glass)
			local collapsed = false
			local collBtn = new("TextButton", {
				Size = UDim2.new(0, 26, 0, 26),
				Position = UDim2.new(1, -34, 0.5, -13),
				BackgroundColor3 = Color3.fromRGB(255, 150, 190),
				BorderSizePixel = 0,
				Text = "−",
				TextColor3 = Theme.Text2,
				TextSize = 16,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Parent = header,
			})
			mkRound(collBtn, 9)
			mkGlass(collBtn, 0.55, Theme.Border, 0.5)
			collBtn.MouseEnter:Connect(function()
				TweenService:Create(collBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.35, TextColor3 = Theme.Bright}):Play()
			end)
			collBtn.MouseLeave:Connect(function()
				TweenService:Create(collBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.55, TextColor3 = Theme.Text2}):Play()
			end)

			local sectionIcon = new("Frame", {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(0, 12, 0.5, -12),
				BackgroundColor3 = Color3.fromRGB(255, 150, 190),
				BorderSizePixel = 0,
			})
			mkRound(sectionIcon, 8)
			mkGlass(sectionIcon, 0.3, Theme.Accent2, 0.2)
			local sectionIconLbl = new("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "◈",
				TextColor3 = Theme.Accent,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				Parent = sectionIcon,
			})
			sectionIcon.Parent = header

			local hdrTitle = new("TextLabel", {
				Size = UDim2.new(1, -72, 1, 0),
				Position = UDim2.new(0, 42, 0, 0),
				BackgroundTransparency = 1,
				Text = sectionTitle or "Section",
				TextColor3 = Theme.Bright,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = header,
			})

			-- Card Body (glass)
			local bodyContainer = new("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0, 40),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = card,
			})
			local bodyPad = UIPad(bodyContainer, 14)
			bodyPad.PaddingTop = UDim.new(0, 12)
			bodyPad.PaddingBottom = UDim.new(0, 14)
			local bodyList = UIList(bodyContainer)

			collBtn.MouseButton1Click:Connect(function()
				collapsed = not collapsed
				bodyContainer.Visible = not collapsed
				collBtn.Text = collapsed and "+" or "−"
			end)
			header.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local pos = input.Position
					local btnPos = collBtn.AbsolutePosition
					local btnSize = collBtn.AbsoluteSize
					if pos.X >= btnPos.X and pos.X <= btnPos.X + btnSize.X and pos.Y >= btnPos.Y and pos.Y <= btnPos.Y + btnSize.Y then return end
					collapsed = not collapsed
					bodyContainer.Visible = not collapsed
					collBtn.Text = collapsed and "+" or "−"
				end
			end)

			-- Element factory
			local SectionObj = {}
			local elementId = 0

			local function addSpacer()
				local sp = new("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = Theme.Border,
					BackgroundTransparency = 0.9,
					BorderSizePixel = 0,
					Parent = bodyContainer,
				})
				return sp
			end

			function SectionObj:AddToggle(cfg)
				cfg = cfg or {}
				local label = cfg.Name or cfg.label or "Toggle"
				local default = cfg.default or false
				local callback = cfg.callback or cfg.Changed or function() end
				elementId = elementId + 1

				local row = new("Frame", {
					Size = UDim2.new(1, 0, 0, 36),
					BackgroundTransparency = 1,
					Parent = bodyContainer,
				})

				local lbl = new("TextLabel", {
					Size = UDim2.new(1, -56, 1, 0),
					BackgroundTransparency = 1,
					Text = label,
					TextColor3 = Theme.Bright,
					TextSize = 12.5,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})

				local state = default
				local track = new("Frame", {
					Size = UDim2.new(0, 46, 0, 26),
					Position = UDim2.new(1, -52, 0.5, -13),
					BackgroundColor3 = Color3.fromRGB(255, 140, 180),
					BorderSizePixel = 0,
					Parent = row,
				})
				mkRound(track, 14)
				mkGlass(track, state and 0.15 or 0.55, state and Theme.Accent2 or Theme.Border, state and 0.1 or 0.5)

				local knob = new("Frame", {
					Size = UDim2.new(0, 20, 0, 20),
					Position = UDim2.new(0, state and 23 or 3, 0.5, -10),
					BackgroundColor3 = Color3.fromRGB(255, 180, 210),
					BorderSizePixel = 0,
					Parent = track,
				})
				mkRound(knob, 10)
				mkGlass(knob, 0.2, Theme.Bright, 0.2)

				local function updateVisual(s)
					local targetTrans = s and 0.15 or 0.55
					local targetPos = s and 23 or 3
					TweenService:Create(track, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundTransparency = targetTrans}):Play()
					TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, targetPos, 0.5, -10)}):Play()
				end

				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						state = not state
						updateVisual(state)
						pcall(callback, state)
					end
				end)

				row._set = function(val)
					state = val
					updateVisual(state)
				end
				row._get = function() return state end

				return row
			end

			function SectionObj:AddCheckbox(cfg)
				cfg = cfg or {}
				local label = cfg.Name or cfg.label or "Check"
				local default = cfg.default or false
				local callback = cfg.callback or cfg.Changed or function() end
				elementId = elementId + 1

				local row = new("Frame", {
					Size = UDim2.new(1, 0, 0, 32),
					BackgroundTransparency = 1,
					Parent = bodyContainer,
				})

				local state = default
				local box = new("Frame", {
					Size = UDim2.new(0, 20, 0, 20),
					Position = UDim2.new(0, 0, 0.5, -10),
					BackgroundColor3 = Color3.fromRGB(255, 140, 180),
					BorderSizePixel = 0,
					Parent = row,
				})
				mkRound(box, 6)
				mkGlass(box, state and 0.2 or 0.6, state and Theme.Accent2 or Theme.Border, state and 0.1 or 0.4)

				local tick = new("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "✓",
					TextColor3 = Theme.Bright,
					TextSize = 13,
					Font = Enum.Font.GothamBold,
					Visible = state,
					Parent = box,
				})

				local lbl = new("TextLabel", {
					Size = UDim2.new(1, -28, 1, 0),
					Position = UDim2.new(0, 28, 0, 0),
					BackgroundTransparency = 1,
					Text = label,
					TextColor3 = Theme.Bright,
					TextSize = 11,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})

				local function updateVisual(s)
					if s then
						TweenService:Create(box, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
					else
						TweenService:Create(box, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
					end
					tick.Visible = s
				end

				row.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						state = not state
						updateVisual(state)
						pcall(callback, state)
					end
				end)

				row._set = function(val) state = val; updateVisual(state) end
				row._get = function() return state end
				return row
			end

			function SectionObj:AddButton(cfg)
				cfg = cfg or {}
				local label = cfg.Name or cfg.label or "Button"
				local danger = cfg.danger or false
				local callback = cfg.callback or cfg.Clicked or function() end
				elementId = elementId + 1

				local btn = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 36),
					BackgroundColor3 = danger and Color3.fromRGB(255, 80, 100) or Color3.fromRGB(255, 150, 190),
					BorderSizePixel = 0,
					Text = label,
					TextColor3 = danger and Color3.fromRGB(255, 200, 200) or Theme.Bright,
					TextSize = 12,
					Font = Enum.Font.GothamBold,
					AutoButtonColor = false,
					Parent = bodyContainer,
				})
				mkRound(btn, 12)
				mkGlass(btn, danger and 0.25 or 0.35, danger and Color3.fromRGB(255, 80, 100) or Theme.Accent2, danger and 0.2 or 0.3)

				local transNormal = btn.BackgroundTransparency
				local txtNormal = btn.TextColor3
				btn.MouseButton1Click:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundTransparency = 0.1}):Play()
					task.delay(0.08, function()
						TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = transNormal}):Play()
					end)
					pcall(callback)
				end)
				btn.MouseEnter:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = danger and 0.15 or 0.2, TextColor3 = Theme.Bright}):Play()
				end)
				btn.MouseLeave:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = transNormal, TextColor3 = txtNormal}):Play()
				end)

				return btn
			end

			function SectionObj:AddDropdown(cfg)
				cfg = cfg or {}
				local label = cfg.Name or cfg.label or "Dropdown"
				local options = cfg.options or cfg.Options or {}
				local default = cfg.default or (options[1] or "")
				local callback = cfg.callback or cfg.Changed or function() end
				elementId = elementId + 1

				local row = new("Frame", {
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 1,
					Parent = bodyContainer,
				})

				local sLbl = new("TextLabel", {
					Size = UDim2.new(0, 56, 1, 0),
					BackgroundTransparency = 1,
					Text = label,
					TextColor3 = Theme.Bright,
					TextSize = 11,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})

				local selected = default
				local zIdx = 500 + elementId

				-- ── Trigger Box (glass pill) ──
				local dropFrame = new("Frame", {
					Size = UDim2.new(1, -64, 0, 38),
					Position = UDim2.new(0, 60, 0, 0),
					BackgroundColor3 = Color3.fromRGB(255, 150, 190),
					BorderSizePixel = 0,
					Parent = row,
				})
				mkRound(dropFrame, 14)
				mkGlass(dropFrame, 0.55, Theme.Border, 0.35)

				local trigger = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					Parent = dropFrame,
				})
				local trigText = new("TextLabel", {
					Size = UDim2.new(1, -36, 1, 0),
					Position = UDim2.new(0, 14, 0, 0),
					BackgroundTransparency = 1,
					Text = selected,
					TextColor3 = Theme.Bright,
					TextSize = 12,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = trigger,
				})
				-- Arrow icon (animated chevron)
				local arrowLbl = new("TextLabel", {
					Size = UDim2.new(0, 16, 0, 16),
					Position = UDim2.new(1, -30, 0.5, -8),
					BackgroundTransparency = 1,
					Text = "▾",
					TextColor3 = Theme.Accent,
					TextSize = 14,
					Font = Enum.Font.GothamBold,
					Parent = trigger,
				})

				-- ── Floating List Panel (unique glass style) ──
				-- Wrapped in a separate frame so we can add a glow/shadow behind it
				local listWrapper = new("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 0, 42),
					BackgroundColor3 = Color3.fromRGB(255, 130, 175),
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = zIdx,
					Parent = dropFrame,
				})
				mkRound(listWrapper, 14)
				mkGlass(listWrapper, 0.2, Theme.Accent2, 0.15)
				-- Extra glow border
				local glowStroke = Instance.new("UIStroke")
				glowStroke.Color = Color3.fromRGB(255, 150, 200)
				glowStroke.Transparency = 0.65
				glowStroke.Thickness = 1.5
				glowStroke.Parent = listWrapper

				-- Inner list with its own glass
				local listFrame = new("ScrollingFrame", {
					Size = UDim2.new(1, -6, 0, 1),
					Position = UDim2.new(0, 3, 0, 3),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = Theme.Accent2,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ZIndex = zIdx,
					Parent = listWrapper,
				})
				local listPad = UIPad(listFrame, 2)
				local listLayout = UIList(listFrame)

				local listOpen = false

				local function populateList()
					for _, child in ipairs(listFrame:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					for i, opt in ipairs(options) do
						local isActive = opt == selected
						local optBtn = new("TextButton", {
							Size = UDim2.new(1, 0, 0, 34),
							BackgroundColor3 = Color3.fromRGB(255, 150, 200),
							BackgroundTransparency = isActive and 0.3 or 1,
							BorderSizePixel = 0,
							Text = "",
							AutoButtonColor = false,
							ZIndex = zIdx,
							Parent = listFrame,
						})
						mkRound(optBtn, 10)
						if isActive then
							mkGlass(optBtn, 0.3, Theme.Accent2, 0.2)
						end

						-- Active indicator dot (pink pill)
						local activeBar = new("Frame", {
							Size = UDim2.new(0, 3, 0, 16),
							Position = UDim2.new(0, 0, 0.5, -8),
							BackgroundColor3 = Theme.Accent2,
							BorderSizePixel = 0,
							Visible = isActive,
							ZIndex = zIdx,
							Parent = optBtn,
						})
						mkRound(activeBar, 2)

						local optLbl = new("TextLabel", {
							Size = UDim2.new(1, -20, 1, 0),
							Position = UDim2.new(0, 14, 0, 0),
							BackgroundTransparency = 1,
							Text = opt,
							TextColor3 = isActive and Theme.Bright or Theme.Text2,
							TextSize = 12,
							Font = Enum.Font.Gotham,
							TextXAlignment = Enum.TextXAlignment.Left,
							ZIndex = zIdx,
							Parent = optBtn,
						})
						-- Hover effect: glass highlight
						optBtn.MouseEnter:Connect(function()
							if not isActive then
								optBtn.BackgroundTransparency = 0.5
								mkGlass(optBtn, 0.5, Theme.Border, 0.3)
							end
							TweenService:Create(optLbl, TweenInfo.new(0.1), {TextColor3 = Theme.Bright}):Play()
						end)
						optBtn.MouseLeave:Connect(function()
							if not isActive then
								optBtn.BackgroundTransparency = 1
								-- remove glass stroke
								local stk = optBtn:FindFirstChildOfClass("UIStroke")
								if stk then stk:Destroy() end
							else
								TweenService:Create(optLbl, TweenInfo.new(0.1), {TextColor3 = Theme.Bright}):Play()
							end
						end)
						optBtn.MouseButton1Click:Connect(function()
							selected = opt
							trigText.Text = opt
							listOpen = false
							-- Animate close
							TweenService:Create(listWrapper, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
								Size = UDim2.new(1, 0, 0, 0),
								BackgroundTransparency = 1,
							}):Play()
							task.delay(0.2, function()
								listWrapper.Visible = false
							end)
							TweenService:Create(arrowLbl, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
							-- Refresh list visuals
							for _, btn in ipairs(listFrame:GetChildren()) do
								if btn:IsA("TextButton") then
									local bar = btn:FindFirstChildOfClass("Frame")
									local lbl = btn:FindFirstChildOfClass("TextLabel")
									if lbl and lbl.Text == opt then
										if bar then bar.Visible = true end
										btn.BackgroundTransparency = 0.3
										TweenService:Create(lbl, TweenInfo.new(0.15), {TextColor3 = Theme.Bright}):Play()
									else
										if bar then bar.Visible = false end
										btn.BackgroundTransparency = 1
										local stk = btn:FindFirstChildOfClass("UIStroke")
										if stk then stk:Destroy() end
										if lbl then
											TweenService:Create(lbl, TweenInfo.new(0.15), {TextColor3 = Theme.Text2}):Play()
										end
									end
								end
							end
							pcall(callback, selected)
						end)
					end
				end
				populateList()

				local function openList()
					if listOpen then return end
					listOpen = true
					local count = #options
					local h = math.min(count * 36 + 8, 176)
					listWrapper.Size = UDim2.new(1, 0, 0, 0)
					listWrapper.Visible = true
					listWrapper.BackgroundTransparency = 0.2
					listWrapper.ZIndex = zIdx
					dropFrame.ZIndex = zIdx
					for _, c in ipairs(dropFrame:GetDescendants()) do
						if c:IsA("GuiObject") then
							c.ZIndex = math.max(c.ZIndex, zIdx)
						end
					end
					TweenService:Create(listWrapper, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, h)
					}):Play()
					TweenService:Create(arrowLbl, TweenInfo.new(0.25), {Rotation = 180}):Play()
				end

				local function closeList()
					if not listOpen then return end
					listOpen = false
					TweenService:Create(listWrapper, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Size = UDim2.new(1, 0, 0, 0),
						BackgroundTransparency = 1,
					}):Play(function()
						listWrapper.Visible = false
						dropFrame.ZIndex = 1
					end)
					TweenService:Create(arrowLbl, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0}):Play()
				end

				trigger.MouseButton1Click:Connect(function()
					if listOpen then closeList() else openList() end
				end)

				-- Click outside to close
				local inputCon
				inputCon = UserInputService.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						task.wait()
						if listOpen and dropFrame.Visible then
							local mousePos = UserInputService:GetMouseLocation()
							local absPos = dropFrame.AbsolutePosition
							local absSize = dropFrame.AbsoluteSize
							local listH = listWrapper.AbsoluteSize.Y
							if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y + listH then
								closeList()
							end
						end
					end
				end)

				-- Cleanup inputCon khi row bị destroy
				local cleanupCon
				cleanupCon = row.Destroying:Connect(function()
					if inputCon then inputCon:Disconnect() end
					if cleanupCon then cleanupCon:Disconnect() end
				end)

				row._get = function() return selected end
				row._set = function(val)
					if table.find(options, val) then
						selected = val
						trigText.Text = val
						populateList()
						pcall(callback, selected)
					end
				end
				row._updateOptions = function(newOpts)
					options = newOpts or {}
					if #options > 0 and not table.find(options, selected) then
						selected = options[1]
						trigText.Text = selected
						pcall(callback, selected)
					end
					populateList()
				end

				return row
			end

			function SectionObj:AddSlider(cfg)
				cfg = cfg or {}
				local label = cfg.Name or cfg.label or "Slider"
				local min = cfg.min or cfg.Min or 0
				local max = cfg.max or cfg.Max or 100
				local default = cfg.default or min
				local callback = cfg.callback or cfg.Changed or function() end
				elementId = elementId + 1

				local row = new("Frame", {
					Size = UDim2.new(1, 0, 0, 42),
					BackgroundTransparency = 1,
					Parent = bodyContainer,
				})

				local sLbl = new("TextLabel", {
					Size = UDim2.new(1, -60, 0, 16),
					BackgroundTransparency = 1,
					Text = label,
					TextColor3 = Theme.Bright,
					TextSize = 11,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				local valLbl = new("TextLabel", {
					Size = UDim2.new(0, 50, 0, 16),
					Position = UDim2.new(1, -50, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(default),
					TextColor3 = Theme.Accent,
					TextSize = 12,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = row,
				})

				local track = new("Frame", {
					Size = UDim2.new(1, 0, 0, 8),
					Position = UDim2.new(0, 0, 1, -12),
					BackgroundColor3 = Color3.fromRGB(255, 140, 180),
					BorderSizePixel = 0,
					Parent = row,
				})
				mkRound(track, 4)
				mkGlass(track, 0.55, Theme.Border, 0.5)

				local fill = new("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(255, 150, 190),
					BorderSizePixel = 0,
					Parent = track,
				})
				mkRound(fill, 4)
				mkGlass(fill, 0.15, Theme.Accent2, 0.1)
				local fillGrad = mkGradient(fill, Theme.Accent3, Theme.Accent, 0)

				local currentValue = default
				local dragging = false

				local function updateFromPos(posX)
					local absPos = track.AbsolutePosition
					local absSize = track.AbsoluteSize.X
					local relX = math.clamp(posX - absPos.X, 0, absSize)
					local pct = relX / absSize
					currentValue = math.floor(min + (max - min) * pct + 0.5)
					currentValue = math.clamp(currentValue, min, max)
					local fillWidth = (currentValue - min) / (max - min) * absSize
					fill.Size = UDim2.new(0, fillWidth, 1, 0)
					valLbl.Text = tostring(currentValue)
				end

				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						updateFromPos(input.Position.X)
					end
				end)
				track.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
						pcall(callback, currentValue)
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						updateFromPos(input.Position.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
						dragging = false
						pcall(callback, currentValue)
					end
				end)

				-- Set default position
				task.wait()
				if default > min then
					local absSize = track.AbsoluteSize.X
					local fillWidth = (default - min) / (max - min) * absSize
					fill.Size = UDim2.new(0, fillWidth, 1, 0)
				end

				row._get = function() return currentValue end
				row._set = function(val)
					currentValue = math.clamp(val, min, max)
					valLbl.Text = tostring(currentValue)
					local absSize = track.AbsoluteSize.X
					local fillWidth = (currentValue - min) / (max - min) * absSize
					TweenService:Create(fill, TweenInfo.new(0.15), {Size = UDim2.new(0, fillWidth, 1, 0)}):Play()
				end
				return row
			end

			-- Stat grid (scientific spacing, no waste)
			function SectionObj:AddStatGrid(cfg)
				cfg = cfg or {}
				local items = cfg.items or {}
				local cols = math.min(cfg.columns or 3, #items)
				if #items == 0 then return end

				local frame = new("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Parent = bodyContainer,
				})

				local grid = Instance.new("UIGridLayout")
				grid.FillDirection = Enum.FillDirection.Horizontal
				grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
				grid.VerticalAlignment = Enum.VerticalAlignment.Top
				grid.CellPadding = UDim2.new(0, 6, 0, 6)
				grid.CellSize = UDim2.new(0, 1, 0, 52)
				grid.SortOrder = Enum.SortOrder.LayoutOrder
				grid.Parent = frame

				for i, item in ipairs(items) do
					local card = new("Frame", {
						Size = UDim2.new(0, 1, 0, 52),
						BackgroundColor3 = Color3.fromRGB(255, 150, 190),
						BorderSizePixel = 0,
						LayoutOrder = i,
						Parent = frame,
					})
					mkRound(card, 10)
					mkGlass(card, 0.6, Theme.Border, 0.4)

					local val = new("TextLabel", {
						Size = UDim2.new(1, 0, 0, 26),
						Position = UDim2.new(0, 0, 0, 4),
						BackgroundTransparency = 1,
						Text = tostring(item.value or "—"),
						TextColor3 = Theme.Bright,
						TextSize = 17,
						Font = Enum.Font.GothamBold,
						Parent = card,
					})

					local lbl = new("TextLabel", {
						Size = UDim2.new(1, 0, 0, 16),
						Position = UDim2.new(0, 0, 0, 30),
						BackgroundTransparency = 1,
						Text = item.label or "",
						TextColor3 = Color3.fromRGB(200, 160, 175),
						TextSize = 10,
						Font = Enum.Font.Gotham,
						TextTransparency = 0.2,
						Parent = card,
					})
				end

				task.wait()
				if cols > 0 then
					local pw = 6
					local cellW = (frame.AbsoluteSize.X - (cols - 1) * pw) / cols
					if cellW > 0 then
						grid.CellSize = UDim2.new(0, cellW, 0, 52)
					end
				end
				return frame
			end

			function SectionObj:AddLabel(text)
				local lbl = new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Theme.Text2,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = bodyContainer,
					RichText = true,
				})
				return lbl
			end

			function SectionObj:AddProgress(percent)
				percent = percent or 0
				local row = new("Frame", {
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundTransparency = 1,
					Parent = bodyContainer,
				})

				local track = new("Frame", {
					Size = UDim2.new(1, -50, 0, 8),
					Position = UDim2.new(0, 0, 0.5, -4),
					BackgroundColor3 = Color3.fromRGB(255, 140, 180),
					BorderSizePixel = 0,
					Parent = row,
				})
				mkRound(track, 5)
				mkGlass(track, 0.55, Theme.Border, 0.5)

				local fill = new("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(255, 150, 190),
					BorderSizePixel = 0,
					Parent = track,
				})
				mkRound(fill, 5)
				mkGlass(fill, 0.1, Theme.Accent2, 0.1)
				mkGradient(fill, Theme.Accent3, Theme.Accent, 0)

				local pctLbl = new("TextLabel", {
					Size = UDim2.new(0, 42, 1, 0),
					Position = UDim2.new(1, -46, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(percent) .. "%",
					TextColor3 = Theme.Accent,
					TextSize = 11,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = row,
				})

				function row:_set(val)
					percent = math.clamp(val, 0, 100)
					local absSize = track.AbsoluteSize.X
					local fillWidth = percent / 100 * absSize
					TweenService:Create(fill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, fillWidth, 1, 0)}):Play()
					pctLbl.Text = tostring(math.floor(percent)) .. "%"
				end

				-- Set initial
				task.wait()
				local absSize = track.AbsoluteSize.X
				local fillWidth = percent / 100 * absSize
				fill.Size = UDim2.new(0, fillWidth, 1, 0)

				return row
			end

			function SectionObj:AddSpacer()
				return addSpacer()
			end

			-- Button group
			function SectionObj:AddButtonGroup(buttons)
				buttons = buttons or {}
				local frame = new("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Parent = bodyContainer,
				})
				local grid = Instance.new("UIGridLayout")
				grid.FillDirection = Enum.FillDirection.Horizontal
				grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
				grid.VerticalAlignment = Enum.VerticalAlignment.Center
				grid.CellPadding = UDim2.new(0, 6, 0, 0)
				grid.CellSize = UDim2.new(0, 1, 0, 34)
				grid.SortOrder = Enum.SortOrder.LayoutOrder
				grid.Parent = frame

				local btns = {}
				for i, btnCfg in ipairs(buttons) do
					local b = self:AddButton(btnCfg)
					b.Parent = frame
					b.LayoutOrder = i
					table.insert(btns, b)
				end

				-- Adjust cell sizes
				task.wait()
				local count = #buttons
				if count > 0 then
					local cellW = (frame.AbsoluteSize.X - (count - 1) * 6) / count
					if cellW > 0 then
						grid.CellSize = UDim2.new(0, cellW, 0, 34)
					end
				end

				return frame
			end

			return SectionObj
		end

		return PageObj
	end

	-- API methods
	local WinAPI = {}

	function WinAPI:UpdateServerInfo(info)
		info = info or {}
		infoRefs.ping = info.ping or infoRefs.ping or 0
		infoRefs.fps = info.fps or infoRefs.fps or 60
		infoRefs.level = info.level or infoRefs.level or 1
		infoRefs.bounty = info.bounty or infoRefs.bounty or "0"
		if infoRefs._pingRefresh then infoRefs._pingRefresh() end
		if infoRefs._fpsRefresh then infoRefs._fpsRefresh() end
		if infoRefs._lvlRefresh then infoRefs._lvlRefresh() end
		if infoRefs._btyRefresh then infoRefs._btyRefresh() end
	end

	function WinAPI:Minimize() minify() end
	function WinAPI:Maximize() maxify() end
	function WinAPI:Destroy()
		screenGui:Destroy()
		if toggleCon then toggleCon:Disconnect() end
		for _, c in ipairs(dragCons) do if c then c:Disconnect() end end
	end
	function WinAPI:UpdateDI(fps, farmTarget, playerName)
		if di then
			di._updateFps(fps or 60)
			di._updateFarm(farmTarget or "Idle")
			di._updatePlayer(playerName or (Players.LocalPlayer and Players.LocalPlayer.Name) or "...")
		end
	end
	function WinAPI:GetMainFrame() return main end
	function WinAPI:GetScreenGui() return screenGui end

	WinAPI.AddTab = WindowObj.AddTab

	return WinAPI
end

return DeniaLib
