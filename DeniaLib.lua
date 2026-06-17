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

-- Theme — Baby Pink
local Theme = {
	Base = Color3.fromRGB(8, 7, 10),
	Surface = Color3.fromRGB(13, 10, 18),
	Surface2 = Color3.fromRGB(20, 16, 26),
	Surface3 = Color3.fromRGB(26, 20, 36),
	Surface4 = Color3.fromRGB(36, 26, 48),
	Accent = Color3.fromRGB(244, 143, 177),
	Accent2 = Color3.fromRGB(236, 64, 122),
	Accent3 = Color3.fromRGB(216, 27, 96),
	Accent4 = Color3.fromRGB(173, 20, 87),
	Text = Color3.fromRGB(212, 200, 208),
	Text2 = Color3.fromRGB(138, 122, 136),
	Text3 = Color3.fromRGB(90, 77, 85),
	Bright = Color3.fromRGB(240, 228, 234),
	Danger = Color3.fromRGB(224, 90, 74),
	Warning = Color3.fromRGB(212, 168, 72),
	Info = Color3.fromRGB(72, 152, 212),
	Border = Color3.fromRGB(244, 143, 177),
}
local BorderTrans = 0.75
local BorderTrans2 = 0.88

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

-- Dynamic Island
local DynIsland = nil
local function CreateDynamicIsland(parentGui)
	if DynIsland then return end
	DynIsland = new("Frame", {
		Name = "DynIsland",
		Size = UDim2.new(0, 0, 0, 38),
		Position = UDim2.new(0.5, 0, 0, 16),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Visible = false,
		Parent = parentGui,
		ZIndex = 9999,
	})
	mkRound(DynIsland, 20)
	mkShadow(DynIsland, 0.7, 0.5, 0.5)

	local pulse = new("Frame", {
		Size = UDim2.new(0, 6, 0, 6),
		Position = UDim2.new(0, 14, 0.5, -3),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = DynIsland,
	})
	mkRound(pulse, 3)

	local fpsLabel = new("TextLabel", {
		Size = UDim2.new(0, 30, 1, 0),
		Position = UDim2.new(0, 26, 0, 0),
		BackgroundTransparency = 1,
		Text = "60",
		TextColor3 = Theme.Bright,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = DynIsland,
	})
	local fpsSuffix = new("TextLabel", {
		Size = UDim2.new(0, 24, 1, 0),
		Position = UDim2.new(0, 56, 0, 0),
		BackgroundTransparency = 1,
		Text = "FPS",
		TextColor3 = Theme.Text3,
		TextSize = 10,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = DynIsland,
	})
	local sep = new("Frame", {
		Size = UDim2.new(0, 1, 0, 18),
		Position = UDim2.new(0, 84, 0.5, -9),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		Parent = DynIsland,
	})
	local farmLabel = new("TextLabel", {
		Size = UDim2.new(0, 130, 1, 0),
		Position = UDim2.new(0, 92, 0, 0),
		BackgroundTransparency = 1,
		Text = "Idle",
		TextColor3 = Theme.Text2,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = DynIsland,
	})
	local arrow = new("TextLabel", {
		Size = UDim2.new(0, 16, 1, 0),
		Position = UDim2.new(1, -18, 0, 0),
		BackgroundTransparency = 1,
		Text = "▸",
		TextColor3 = Theme.Text3,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		Parent = DynIsland,
	})

	local targetSize = UDim2.new(0, 260, 0, 38)
	DynIsland._expand = function()
		TweenService:Create(DynIsland, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = targetSize}):Play()
	end
	DynIsland._collapse = function()
		TweenService:Create(DynIsland, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 38)}):Play()
	end

	DynIsland._updateFps = function(val)
		fpsLabel.Text = tostring(val)
	end
	DynIsland._updateFarm = function(text)
		farmLabel.Text = text
	end

	-- Click to maximize
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

	-- Shroud
	local shroud = new("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.3,
		Visible = false,
		Parent = screenGui,
	})
	mkRound(shroud, 18)

	-- Main Window
	local main = new("Frame", {
		Name = "MainWindow",
		Size = windowSize,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Base,
		BorderSizePixel = 0,
		Parent = screenGui,
		ClipsDescendants = true,
	})
	mkRound(main, 18)
	mkShadow(main, 0.6)

	-- Window gradient overlay
	mkGradient(main, Theme.Base, Theme.Surface, 160)

	-- Topbar
	local topbar = new("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Parent = main,
	})
	mkGradient(topbar, Color3.fromRGB(13, 10, 18), Color3.fromRGB(16, 13, 24), 135)

	local topBorder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.8,
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
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(0, 14, 0.5, -15),
		BackgroundColor3 = Theme.Accent3,
		BorderSizePixel = 0,
		Parent = brand,
	})
	mkRound(logo, 9)
	mkGradient(logo, Theme.Accent4, Theme.Accent, 135)
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
			Size = UDim2.new(0, 1, 0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
		})
		mkRound(frame, 7)
		mkShadow(frame, 0.85)

		local dot = new("Frame", {
			Size = UDim2.new(0, 5, 0, 5),
			Position = UDim2.new(0, 8, 0.5, -2.5),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
		})
		mkRound(dot, 2.5)
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
		val.Parent = frame
		lbl.Parent = frame

		-- reposition label after val updates
		local function refresh()
			val.Text = getValue and getValue() or "—"
			lbl.Position = UDim2.new(0, val.TextBounds.X + 17, 0, 0)
		end
		return frame, refresh
	end

	-- Info items
	local infoRefs = {}
	local _, pingRef = makeInfoItem("ms", function() return tostring(infoRefs.ping or 0) end)
	_, infoRefs.pingRef = pingRef, nil
	local _, fpsRef = makeInfoItem("FPS", function() return tostring(infoRefs.fps or 60) end)
	_, infoRefs.fpsRef = fpsRef, nil
	local _, lvlRef = makeInfoItem("Lv.", function() return tostring(infoRefs.level or 1) end)
	_, infoRefs.lvlRef = lvlRef, nil
	local _, btyRef = makeInfoItem("Bounty", function() return tostring(infoRefs.bounty or "0") end)
	_, infoRefs.btyRef = btyRef, nil

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
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Text = "−",
		TextColor3 = Theme.Text3,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = actions,
	})
	mkRound(minimizeBtn, 9)
	mkShadow(minimizeBtn, 0.75)
	minimizeBtn.MouseEnter:Connect(function()
		TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Surface3, TextColor3 = Theme.Text}):Play()
	end)
	minimizeBtn.MouseLeave:Connect(function()
		TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Text3}):Play()
	end)

	local closeBtn = new("TextButton", {
		Size = UDim2.new(0, 30, 0, 30),
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Text = "✕",
		TextColor3 = Theme.Text3,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Parent = actions,
	})
	mkRound(closeBtn, 9)
	mkShadow(closeBtn, 0.75)
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 20, 20), TextColor3 = Theme.Danger}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Text3}):Play()
	end)

	-- Tab bar
	local tabBar = new("Frame", {
		Name = "TabBar",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(11, 8, 18),
		BorderSizePixel = 0,
		Parent = main,
	})
	local tabBorder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.8,
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

	-- Body
	local body = new("ScrollingFrame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -90),
		Position = UDim2.new(0, 0, 0, 90),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Accent4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = main,
	})
	local bodyPadding = UIPad(body, 12)
	local bodyLayout = UIList(body, Enum.FillDirection.Vertical, 0, 10)
	bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- Window dragging
	local dragging, dragStart, startPos
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
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
			tabObj.Page.Visible = isActive
		end
		body.CanvasPosition = Vector2.new(0, 0)
	end

	local WindowObj = {}

	function WindowObj:AddTab(name, iconChar)
		local idx = #tabs + 1
		local tabBtn = new("TextButton", {
			Size = UDim2.new(0, 1, 0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = (iconChar or "•") .. "  " .. name,
			TextColor3 = Theme.Text3,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			Parent = tabContainer,
		})
		UIPad(tabBtn, 10)

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

		local tabInfo = {Button = tabBtn, Page = page, Underline = underline}
		tabObjects[idx] = tabInfo
		tabs[idx] = tabInfo

		if #tabs == 1 then
			activeTab = 1
			tabBtn.TextColor3 = Theme.Bright
			underline.Visible = true
			page.Visible = true
		end

		tabBtn.MouseButton1Click:Connect(function()
			switchTab(idx)
			for _, t in pairs(tabObjects) do
				t.Underline.Visible = false
			end
			TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, -20, 0, 2.5)}):Play()
			underline.Visible = true
		end)
		tabBtn.MouseEnter:Connect(function()
			if activeTab ~= idx then
				TweenService:Create(tabBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Text2}):Play()
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if activeTab ~= idx then
				TweenService:Create(tabBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Text3}):Play()
			end
		end)

		-- Section/Page methods
		local PageObj = {}

		function PageObj:AddSection(sectionTitle)
			local card = new("Frame", {
				Size = UDim2.new(1, -0, 0, 1),
				BackgroundColor3 = Theme.Surface,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = page,
			})
			mkRound(card, 14)
			mkShadow(card, 0.75)

			local cardGrad = mkGradient(card, Color3.fromRGB(13, 14, 18), Color3.fromRGB(15, 16, 21), 135)

			-- Card Header
			local header = new("Frame", {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Theme.Surface2,
				BorderSizePixel = 0,
				BackgroundTransparency = 0.4,
				Parent = card,
			})
			mkGradient(header, Color3.fromRGB(20, 14, 28):lerp(Color3.new(1,1,1), 0.03), Color3.fromRGB(20, 14, 28), 90)
			local hdrBorder = new("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Theme.Border,
				BackgroundTransparency = 0.9,
				BorderSizePixel = 0,
				Parent = header,
			})

			-- Collapse button
			local collapsed = false
			local collBtn = new("TextButton", {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -32, 0.5, -12),
				BackgroundTransparency = 1,
				Text = "−",
				TextColor3 = Theme.Text3,
				TextSize = 16,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Parent = header,
			})
			collBtn.MouseEnter:Connect(function()
				TweenService:Create(collBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Accent}):Play()
			end)
			collBtn.MouseLeave:Connect(function()
				TweenService:Create(collBtn, TweenInfo.new(0.15), {TextColor3 = Theme.Text3}):Play()
			end)

			local sectionIcon = new("TextLabel", {
				Size = UDim2.new(0, 22, 0, 22),
				Position = UDim2.new(0, 12, 0.5, -11),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.88,
				BorderSizePixel = 0,
				Text = "◈",
				TextColor3 = Theme.Accent,
				TextSize = 12,
				Font = Enum.Font.GothamBold,
				Parent = header,
			})
			mkRound(sectionIcon, 7)

			local hdrTitle = new("TextLabel", {
				Size = UDim2.new(1, -70, 1, 0),
				Position = UDim2.new(0, 40, 0, 0),
				BackgroundTransparency = 1,
				Text = sectionTitle or "Section",
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = header,
			})

			-- Card Body
			local bodyContainer = new("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0, 38),
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
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					Parent = bodyContainer,
				})

				local lbl = new("TextLabel", {
					Size = UDim2.new(1, -54, 1, 0),
					BackgroundTransparency = 1,
					Text = label,
					TextColor3 = Theme.Text,
					TextSize = 12.5,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})

				local state = default
				local track = new("Frame", {
					Size = UDim2.new(0, 42, 0, 24),
					Position = UDim2.new(1, -48, 0.5, -12),
					BackgroundColor3 = state and Theme.Accent2 or Theme.Surface3,
					BorderSizePixel = 0,
					Parent = row,
				})
				mkRound(track, 14)

				local knob = new("Frame", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0, state and 21 or 3, 0.5, -9),
					BackgroundColor3 = Theme.Bright,
					BorderSizePixel = 0,
					Parent = track,
				})
				mkRound(knob, 9)

				local function updateVisual(s)
					local targetColor = s and Theme.Accent2 or Theme.Surface3
					local targetPos = s and 21 or 3
					TweenService:Create(track, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
					TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, targetPos, 0.5, -9)}):Play()
				end

				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						state = not state
						updateVisual(state)
						pcall(callback, state)
					end
				end)

				-- Live setter
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
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Parent = bodyContainer,
				})

				local state = default
				local box = new("Frame", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0, 0, 0.5, -9),
					BackgroundColor3 = state and Theme.Accent2 or Color3.new(0, 0, 0),
					BackgroundTransparency = 0.85,
					BorderSizePixel = 0,
					BorderColor3 = Theme.Border,
					Parent = row,
				})
				mkRound(box, 5)

				local tick = new("Frame", {
					Size = UDim2.new(0, 10, 0, 10),
					Position = UDim2.new(0.5, -5, 0.5, -5),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = box,
				})
				mkRound(tick, 3)
				local tickScale = tick:TweenPosition(UDim2.new(0.5, -5, 0.5, -5), "Out", "Quad", 0, true)
				tick.Size = state and UDim2.new(0, 10, 0, 10) or UDim2.new(0, 0, 0, 0)

				local lbl = new("TextLabel", {
					Size = UDim2.new(1, -26, 1, 0),
					Position = UDim2.new(0, 26, 0, 0),
					BackgroundTransparency = 1,
					Text = label,
					TextColor3 = state and Theme.Text2 or Theme.Text3,
					TextSize = 11,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})

				local function updateVisual(s)
					TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = s and Theme.Accent2 or Color3.new(0, 0, 0), BackgroundTransparency = s and 0.7 or 0.85}):Play()
					TweenService:Create(tick, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = s and UDim2.new(0, 10, 0, 10) or UDim2.new(0, 0, 0, 0)}):Play()
					TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = s and Theme.Text2 or Theme.Text3}):Play()
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
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundColor3 = danger and Color3.fromRGB(40, 15, 15) or Theme.Surface2,
					BorderSizePixel = 0,
					Text = label,
					TextColor3 = danger and Theme.Danger or Theme.Text,
					TextSize = 12,
					Font = Enum.Font.GothamBold,
					AutoButtonColor = false,
					Parent = bodyContainer,
				})
				mkRound(btn, 10)
				mkShadow(btn, 0.8)

				local btnGrad
				if danger then
					btnGrad = mkGradient(btn, Color3.fromRGB(40, 15, 15), Color3.fromRGB(35, 12, 12), 135)
				else
					btnGrad = mkGradient(btn, Theme.Accent3, Theme.Accent2, 135)
				end

				local clrNormal = btn.BackgroundColor3
				local txtNormal = btn.TextColor3
				btn.MouseButton1Click:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Theme.Accent4}):Play()
					task.delay(0.08, function()
						TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = clrNormal}):Play()
					end)
					pcall(callback)
				end)
				btn.MouseEnter:Connect(function()
					if not danger then
						TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent2}):Play()
					end
					TweenService:Create(btn, TweenInfo.new(0.15), {TextColor3 = Theme.Bright}):Play()
				end)
				btn.MouseLeave:Connect(function()
					TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = clrNormal}):Play()
					TweenService:Create(btn, TweenInfo.new(0.15), {TextColor3 = txtNormal}):Play()
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
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					Parent = bodyContainer,
				})

				local sLbl = new("TextLabel", {
					Size = UDim2.new(0, 56, 1, 0),
					BackgroundTransparency = 1,
					Text = label,
					TextColor3 = Theme.Text3,
					TextSize = 11,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})

				local selected = default
				local dropFrame = new("Frame", {
					Size = UDim2.new(1, -64, 0, 34),
					Position = UDim2.new(0, 60, 0, 0),
					BackgroundColor3 = Theme.Surface2,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Parent = row,
				})
				mkRound(dropFrame, 10)
				mkShadow(dropFrame, 0.8)
				local zIdx = 100 + elementId

				local trigger = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					Parent = dropFrame,
				})
				local trigText = new("TextLabel", {
					Size = UDim2.new(1, -24, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = selected,
					TextColor3 = Theme.Text,
					TextSize = 12,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = trigger,
				})
				local arrowLbl = new("TextLabel", {
					Size = UDim2.new(0, 14, 0, 14),
					Position = UDim2.new(1, -22, 0.5, -7),
					BackgroundTransparency = 1,
					Text = "▾",
					TextColor3 = Theme.Text3,
					TextSize = 12,
					Font = Enum.Font.GothamBold,
					Parent = trigger,
				})

				local listFrame = new("ScrollingFrame", {
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 0, 38),
					BackgroundColor3 = Theme.Surface2,
					BorderSizePixel = 0,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = Theme.Accent4,
					Visible = false,
					ZIndex = zIdx,
					Parent = dropFrame,
				})
				mkRound(listFrame, 10)
				local listPad = UIPad(listFrame, 4)
				local listLayout = UIList(listFrame)

				local listOpen = false
				local function populateList()
					for _, child in ipairs(listFrame:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					for i, opt in ipairs(options) do
						local isActive = opt == selected
						local optBtn = new("TextButton", {
							Size = UDim2.new(1, 0, 0, 30),
							BackgroundTransparency = 1,
							Text = "",
							AutoButtonColor = false,
							ZIndex = zIdx,
							Parent = listFrame,
						})
						local optDot = new("Frame", {
							Size = UDim2.new(0, 3, 0, 14),
							Position = UDim2.new(0, 0, 0.5, -7),
							BackgroundColor3 = Theme.Accent,
							BorderSizePixel = 0,
							Visible = isActive,
							ZIndex = zIdx,
							Parent = optBtn,
						})
						mkRound(optDot, 2)
						local optLbl = new("TextLabel", {
							Size = UDim2.new(1, -16, 1, 0),
							Position = UDim2.new(0, 12, 0, 0),
							BackgroundTransparency = 1,
							Text = opt,
							TextColor3 = isActive and Theme.Bright or Theme.Text2,
							TextSize = 12,
							Font = Enum.Font.Gotham,
							TextXAlignment = Enum.TextXAlignment.Left,
							ZIndex = zIdx,
							Parent = optBtn,
						})
						optBtn.MouseEnter:Connect(function()
							TweenService:Create(optLbl, TweenInfo.new(0.1), {TextColor3 = Theme.Text}):Play()
						end)
						optBtn.MouseLeave:Connect(function()
							TweenService:Create(optLbl, TweenInfo.new(0.1), {TextColor3 = isActive and Theme.Bright or Theme.Text2}):Play()
						end)
						optBtn.MouseButton1Click:Connect(function()
							selected = opt
							trigText.Text = opt
							listOpen = false
							listFrame.Visible = false
							listFrame.Size = UDim2.new(1, 0, 0, 0)
							TweenService:Create(arrowLbl, TweenInfo.new(0.2), {Rotation = 0}):Play()
							-- Update all options
							for _, btn in ipairs(listFrame:GetChildren()) do
								if btn:IsA("TextButton") then
									local dot = btn:FindFirstChildOfClass("Frame")
									local lbl = btn:FindFirstChildOfClass("TextLabel")
									if btn:FindFirstChildOfClass("TextLabel") and btn:FindFirstChildOfClass("TextLabel").Text == opt then
										if dot then dot.Visible = true end
										if lbl then
											lbl.TextColor3 = Theme.Bright
											TweenService:Create(lbl, TweenInfo.new(0.15), {TextColor3 = Theme.Bright}):Play()
										end
									else
										if dot then dot.Visible = false end
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
					local h = math.min(count * 34 + 8, 164)
					listFrame.Size = UDim2.new(1, 0, 0, 0)
					listFrame.Visible = true
					listFrame.ZIndex = zIdx
					TweenService:Create(listFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, h)}):Play()
					TweenService:Create(arrowLbl, TweenInfo.new(0.2), {Rotation = 180}):Play()
					-- Increase ZIndex of parent
					dropFrame.ZIndex = zIdx
					for _, c in ipairs(dropFrame:GetDescendants()) do
						if c:IsA("GuiObject") then
							c.ZIndex = math.max(c.ZIndex, zIdx)
						end
					end
				end

				local function closeList()
					if not listOpen then return end
					listOpen = false
					TweenService:Create(listFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)}):Play(function()
						listFrame.Visible = false
						dropFrame.ZIndex = 1
					end)
					TweenService:Create(arrowLbl, TweenInfo.new(0.2), {Rotation = 0}):Play()
				end

				trigger.MouseButton1Click:Connect(function()
					if listOpen then closeList() else openList() end
				end)

				-- Close list when clicking outside
				local inputCon
				inputCon = UserInputService.InputBegan:Connect(function(input, gpe)
					if gpe then return end
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						task.wait()
						if listOpen and dropFrame.Visible then
							local mousePos = UserInputService:GetMouseLocation()
							local absPos = dropFrame.AbsolutePosition
							local absSize = dropFrame.AbsoluteSize
							local listH = listFrame.AbsoluteSize.Y
							if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y + listH then
								closeList()
							end
						end
					end
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
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundTransparency = 1,
					Parent = bodyContainer,
				})

				local sLbl = new("TextLabel", {
					Size = UDim2.new(1, -60, 0, 16),
					BackgroundTransparency = 1,
					Text = label,
					TextColor3 = Theme.Text3,
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
					Size = UDim2.new(1, 0, 0, 6),
					Position = UDim2.new(0, 0, 1, -10),
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.8,
					BorderSizePixel = 0,
					Parent = row,
				})
				mkRound(track, 3)

				local fill = new("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = Theme.Accent2,
					BorderSizePixel = 0,
					Parent = track,
				})
				mkRound(fill, 3)
				local fillGrad = mkGradient(fill, Theme.Accent4, Theme.Accent, 0)

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
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.85,
					BorderSizePixel = 0,
					Parent = row,
				})
				mkRound(track, 5)

				local fill = new("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = track,
				})
				mkRound(fill, 5)
				mkGradient(fill, Theme.Accent4, Theme.Accent, 0)

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
	end

	function WinAPI:Minimize() minify() end
	function WinAPI:Maximize() maxify() end
	function WinAPI:Destroy() screenGui:Destroy() if toggleCon then toggleCon:Disconnect() end end
	function WinAPI:UpdateDI(fps, farmTarget)
		if di then
			di._updateFps(fps or 60)
			di._updateFarm(farmTarget or "Idle")
		end
	end
	function WinAPI:GetMainFrame() return main end
	function WinAPI:GetScreenGui() return screenGui end

	return WinAPI
end

return DeniaLib
