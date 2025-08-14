--[[ 
    ✨ All-in-one Colorful Menu (LocalScript)
    Place: StarterPlayer → StarterPlayerScripts
    Works on PC & Mobile • GUI không mất khi chết

    Main features:
      • Infinite Jump (toggle)
      • Float (đứng giữa không + di chuyển được)
      • Speed tùy chỉnh (fade nhập)
      • Teleport đến player (scroll list)
      • Rejoin
      • Server Hop
      • Buff máu tùy chỉnh
      • Spawn Classic Sword
      • God Mode (2 lớp)
      • Body Size slider realtime (-100 → 100)
      • Troll Menu (5 trò): Plane Ride • Head Spin • Giant Arm Grab • Follow Magnet • Seat Attach
--]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- =========================
-- UI helpers
-- =========================
local function tweenProp(obj, prop, from, to, t)
	obj[prop] = from
	local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[prop]=to})
	tw:Play()
	return tw
end

local function fancyStroke(obj, thickness, color)
	local st = Instance.new("UIStroke")
	st.Thickness = thickness or 2
	st.Color = color or Color3.fromRGB(255,255,255)
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = obj
end

local function fancyGradient(obj, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2) }
	g.Rotation = rot or 45
	g.Parent = obj
end

local function softCorner(obj, r)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, r or 12)
	u.Parent = obj
end

local function shadow(obj)
	local s = Instance.new("ImageLabel")
	s.Size = UDim2.fromScale(1,1)
	s.Position = UDim2.fromScale(0,0)
	s.BackgroundTransparency = 1
	s.Image = "rbxassetid://5028857084"
	s.ImageTransparency = 0.3
	s.ScaleType = Enum.ScaleType.Slice
	s.SliceCenter = Rect.new(24,24,276,276)
	s.Parent = obj
end

-- =========================
-- Root GUI
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ColorfulMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Nút mở menu
local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 90, 0, 44)
openBtn.Position = UDim2.new(0, 12, 0, 12)
openBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
openBtn.Text = "MENU"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 18
openBtn.Parent = screenGui
softCorner(openBtn, 14); fancyGradient(openBtn, Color3.fromRGB(255,120,0), Color3.fromRGB(255,0,200)); fancyStroke(openBtn, 2, Color3.fromRGB(255,255,255)); shadow(openBtn)

-- Panel chính (scroll)
local menuFrame = Instance.new("ScrollingFrame")
menuFrame.Size = UDim2.new(0, 300, 0, 380)
menuFrame.Position = UDim2.new(0.5, -150, 0.5, -190)
menuFrame.BackgroundColor3 = Color3.fromRGB(20,20,24)
menuFrame.ScrollBarThickness = 6
menuFrame.Visible = false
menuFrame.ClipsDescendants = true
menuFrame.Parent = screenGui
softCorner(menuFrame, 18); fancyGradient(menuFrame, Color3.fromRGB(30,30,70), Color3.fromRGB(10,10,20)); fancyStroke(menuFrame, 2, Color3.fromRGB(120,180,255)); shadow(menuFrame)

local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, -20, 0, 36)
titleBar.Position = UDim2.new(0, 10, 0, 8)
titleBar.BackgroundTransparency = 1
titleBar.Text = "✨ Power Menu"
titleBar.Font = Enum.Font.GothamBlack
titleBar.TextSize = 20
titleBar.TextColor3 = Color3.fromRGB(255,255,255)
titleBar.Parent = menuFrame

local contentPad = Instance.new("Frame")
contentPad.Size = UDim2.new(1, -20, 1, -60)
contentPad.Position = UDim2.new(0, 10, 0, 50)
contentPad.BackgroundTransparency = 1
contentPad.Parent = menuFrame

local list = Instance.new("UIListLayout")
list.Parent = contentPad
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder

menuFrame.CanvasSize = UDim2.new(0,0,0,0)
list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	menuFrame.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y + 60)
end)

openBtn.MouseButton1Click:Connect(function()
	menuFrame.Visible = not menuFrame.Visible
	if menuFrame.Visible then
		menuFrame.BackgroundTransparency = 1
		tweenProp(menuFrame, "BackgroundTransparency", 1, 0, 0.2)
	end
end)

-- Button factory
local function createButton(text, colors, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 42)
	btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.AutoButtonColor = true
	btn.Parent = contentPad
	softCorner(btn, 12); fancyGradient(btn, colors[1], colors[2]); fancyStroke(btn, 2, Color3.fromRGB(255,255,255)); shadow(btn)
	btn.MouseButton1Click:Connect(function() if callback then callback() end end)
	return btn
end

-- Modal nhập số (fade)
local function promptNumber(title, placeholder, onOK)
	menuFrame.Visible = false
	local modal = Instance.new("Frame")
	modal.Size = UDim2.new(0, 240, 0, 130)
	modal.Position = UDim2.new(0.5, -120, 0.5, -65)
	modal.BackgroundColor3 = Color3.fromRGB(25,25,35)
	modal.Parent = screenGui
	softCorner(modal, 14); fancyGradient(modal, Color3.fromRGB(90,0,150), Color3.fromRGB(0,160,255)); fancyStroke(modal, 2, Color3.fromRGB(255,255,255)); shadow(modal)
	modal.BackgroundTransparency = 1
	tweenProp(modal, "BackgroundTransparency", 1, 0, 0.2)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -20, 0, 28)
	lbl.Position = UDim2.new(0, 10, 0, 10)
	lbl.BackgroundTransparency = 1
	lbl.Text = title
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = 18
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.Parent = modal

	local tb = Instance.new("TextBox")
	tb.Size = UDim2.new(1, -20, 0, 36)
	tb.Position = UDim2.new(0, 10, 0, 46)
	tb.PlaceholderText = placeholder
	tb.Text = ""
	tb.TextColor3 = Color3.fromRGB(255,255,255)
	tb.Font = Enum.Font.Gotham
	tb.TextSize = 16
	tb.BackgroundColor3 = Color3.fromRGB(40,40,60)
	tb.Parent = modal
	softCorner(tb, 10); fancyStroke(tb, 1, Color3.fromRGB(255,255,255))

	local ok = Instance.new("TextButton")
	ok.Size = UDim2.new(1, -20, 0, 28)
	ok.Position = UDim2.new(0, 10, 1, -38)
	ok.Text = "OK"
	ok.Font = Enum.Font.GothamBold
	ok.TextSize = 16
	ok.TextColor3 = Color3.fromRGB(255,255,255)
	ok.BackgroundColor3 = Color3.fromRGB(30,120,40)
	ok.Parent = modal
	softCorner(ok, 10); fancyGradient(ok, Color3.fromRGB(0,200,100), Color3.fromRGB(0,120,255)); fancyStroke(ok, 1, Color3.fromRGB(255,255,255))

	ok.MouseButton1Click:Connect(function()
		local v = tonumber(tb.Text)
		pcall(function() onOK(v) end)
		tweenProp(modal, "BackgroundTransparency", 0, 1, 0.2).Completed:Wait()
		modal:Destroy()
		menuFrame.Visible = true
	end)
end

-- Modal chọn người chơi (scroll + fade)
local function promptPlayerSelect(onPick)
	menuFrame.Visible = false
	local frame = Instance.new("ScrollingFrame")
	frame.Size = UDim2.new(0, 300, 0, 360)
	frame.Position = UDim2.new(0.5, -150, 0.5, -180)
	frame.BackgroundColor3 = Color3.fromRGB(24,24,34)
	frame.ScrollBarThickness = 6
	frame.Parent = screenGui
	softCorner(frame, 16); fancyGradient(frame, Color3.fromRGB(0,120,255), Color3.fromRGB(255,0,150)); fancyStroke(frame, 2, Color3.fromRGB(255,255,255)); shadow(frame)
	frame.BackgroundTransparency = 1
	tweenProp(frame, "BackgroundTransparency", 1, 0, 0.2)

	local cap = Instance.new("TextLabel")
	cap.Size = UDim2.new(1, -20, 0, 36)
	cap.Position = UDim2.new(0, 10, 0, 8)
	cap.BackgroundTransparency = 1
	cap.Text = "Chọn người chơi"
	cap.Font = Enum.Font.GothamBlack
	cap.TextSize = 20
	cap.TextColor3 = Color3.fromRGB(255,255,255)
	cap.Parent = frame

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -20, 1, -60)
	holder.Position = UDim2.new(0, 10, 0, 50)
	holder.BackgroundTransparency = 1
	holder.Parent = frame

	local l = Instance.new("UIListLayout", holder)
	l.Padding = UDim.new(0, 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder

	local function addBtn(plr)
		if plr == player then return end
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 40)
		b.Text = plr.Name
		b.TextColor3 = Color3.fromRGB(255,255,255)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 16
		b.BackgroundColor3 = Color3.fromRGB(50,50,70)
		b.Parent = holder
		softCorner(b, 10); fancyGradient(b, Color3.fromRGB(255,140,0), Color3.fromRGB(255,0,150)); fancyStroke(b, 1, Color3.fromRGB(255,255,255))

		b.MouseButton1Click:Connect(function()
			pcall(function() onPick(plr) end)
			tweenProp(frame, "BackgroundTransparency", 0, 1, 0.2).Completed:Wait()
			frame:Destroy()
			menuFrame.Visible = true
		end)
	end

	for _,plr in ipairs(Players:GetPlayers()) do addBtn(plr) end
	Players.PlayerAdded:Connect(addBtn)
	frame.CanvasSize = UDim2.new(0,0,0,l.AbsoluteContentSize.Y + 60)
end

-- =========================
-- State / Logic
-- =========================
local speedValue = 16
local infiniteJump = false

-- God Mode
local godEnabled = false
local godConn -- HealthChanged connection
local keepAliveThread

local function applyGod(hum)
	if not hum then return end
	pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
	hum.MaxHealth = math.huge
	hum.Health = hum.MaxHealth

	if godConn then godConn:Disconnect() godConn = nil end
	godConn = hum.HealthChanged:Connect(function(h)
		if not godEnabled then return end
		if h < hum.MaxHealth then
			hum.MaxHealth = math.huge
			hum.Health = hum.MaxHealth
		end
	end)

	if keepAliveThread then task.cancel(keepAliveThread) end
	keepAliveThread = task.spawn(function()
		while godEnabled and hum.Parent do
			pcall(function()
				hum.MaxHealth = math.huge
				if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
				hum.PlatformStand = false
			end)
			task.wait(0.5)
		end
	end)
end

local function removeGod()
	godEnabled = false
	if godConn then godConn:Disconnect() godConn = nil end
	if keepAliveThread then task.cancel(keepAliveThread) keepAliveThread = nil end
end

-- Float
local floatEnabled = false
local floatBV -- BodyVelocity cho float

-- =========================
-- Troll states
-- =========================
local planeActive = false
local planeSpinConn

local headSpinActive = false
local headSpinConn
local savedNeckC0 -- original C0
local function getNeck(char)
	-- R15: UpperTorso.Neck ; R6: Torso.Neck
	local neck
	local upper = char:FindFirstChild("UpperTorso")
	local torso = char:FindFirstChild("Torso")
	if upper and upper:FindFirstChild("Neck") then
		neck = upper.Neck
	elseif torso and torso:FindFirstChild("Neck") then
		neck = torso.Neck
	end
	return neck
end

local giantArmActive = false
local giantArmFolder
local giantUpdateConn

local magnetActive = false
local magnetConn
local magnetVisual -- sphere
local magnetRadius = 16

local seatAttachActive = false
local seatWelded -- Seat

-- =========================
-- Troll builders
-- =========================
-- Plane Ride
local function makeWeld(a,b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a; w.Part1 = b; w.Parent = a
	return w
end

local function buildPlaneRig(char)
	local hrp = char and char:FindChild("HumanoidRootPart") or char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local plane = Instance.new("Folder")
	plane.Name = "PlaneRig"
	plane.Parent = char

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(6, 0.4, 1)
	body.Color = Color3.fromRGB(200, 200, 200)
	body.Massless = true
	body.CanCollide = false
	body.Parent = plane
	body.CFrame = hrp.CFrame * CFrame.new(0, 1.2, 0)
	makeWeld(body, hrp)

	local seat = Instance.new("Seat")
	seat.Name = "PassengerSeat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.Color = Color3.fromRGB(120, 170, 255)
	seat.Massless = true
	seat.CanCollide = true
	seat.Parent = plane
	seat.CFrame = hrp.CFrame * CFrame.new(0, 1.7, -1.5)
	makeWeld(seat, hrp)

	local hub = Instance.new("Part")
	hub.Name = "PropHub"
	hub.Size = Vector3.new(0.3, 0.3, 0.3)
	hub.Color = Color3.fromRGB(255, 255, 255)
	hub.Massless = true
	hub.CanCollide = false
	hub.Parent = plane
	hub.CFrame = hrp.CFrame * CFrame.new(0, 1.5, -2)
	makeWeld(hub, hrp)

	local blade1 = Instance.new("Part")
	blade1.Name = "Blade1"
	blade1.Size = Vector3.new(0.2, 3.2, 0.2)
	blade1.Color = Color3.fromRGB(255, 0, 0)
	blade1.Massless = true
	blade1.CanCollide = false
	blade1.Parent = plane
	blade1.CFrame = hub.CFrame * CFrame.new(0, 1.6, 0)
	makeWeld(blade1, hub)

	local blade2 = Instance.new("Part")
	blade2.Name = "Blade2"
	blade2.Size = Vector3.new(0.2, 3.2, 0.2)
	blade2.Color = Color3.fromRGB(0, 255, 0)
	blade2.Massless = true
	blade2.CanCollide = false
	blade2.Parent = plane
	blade2.CFrame = hub.CFrame * CFrame.new(0, -1.6, 0)
	makeWeld(blade2, hub)

	local angle = 0
	planeSpinConn = RunService.RenderStepped:Connect(function(dt)
		angle += dt * 25 * math.pi
		if hrp then
			hub.CFrame = (hrp.CFrame * CFrame.new(0, 1.5, -2)) * CFrame.Angles(0, 0, angle)
		end
	end)
end

local function removePlaneRig(char)
	local folder = char and char:FindFirstChild("PlaneRig")
	if folder then folder:Destroy() end
	if planeSpinConn then planeSpinConn:Disconnect(); planeSpinConn = nil end
end

local function togglePlane()
	planeActive = not planeActive
	local char = player.Character
	if not char then return end
	if planeActive then buildPlaneRig(char) else removePlaneRig(char) end
end

-- Head Spin
local function toggleHeadSpin()
	headSpinActive = not headSpinActive
	local char = player.Character; if not char then return end
	local neck = getNeck(char)
	if headSpinActive and neck and neck:IsA("Motor6D") then
		if not savedNeckC0 then savedNeckC0 = neck.C0 end
		local t = 0
		headSpinConn = RunService.RenderStepped:Connect(function(dt)
			if not neck.Parent then return end
			t += dt * math.pi * 2
			pcall(function()
				neck.C0 = savedNeckC0 * CFrame.Angles(0, t, 0)
			end)
		end)
	else
		if headSpinConn then headSpinConn:Disconnect(); headSpinConn = nil end
		if neck and savedNeckC0 then pcall(function() neck.C0 = savedNeckC0 end) end
	end
end

-- Giant Arm Grab (cánh tay dài để "chạm" xa, đẩy người khác trên client mình)
local function unitLook(cf) return (cf.LookVector) end

local function buildGiantArm(char)
	local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	local rHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not rHand then return end

	giantArmFolder = Instance.new("Folder")
	giantArmFolder.Name = "GiantArm"
	giantArmFolder.Parent = char

	local rod = Instance.new("Part")
	rod.Name = "GrabRod"
	rod.Size = Vector3.new(0.4, 0.4, 20) -- dài
	rod.Color = Color3.fromRGB(255, 170, 0)
	rod.Material = Enum.Material.Neon
	rod.Massless = true
	rod.CanCollide = true -- để "đẩy" người khác
	rod.Parent = giantArmFolder

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rHand; weld.Part1 = rod; weld.Parent = rod

	giantUpdateConn = RunService.RenderStepped:Connect(function()
		if not rod.Parent or not rHand.Parent then return end
		local look = unitLook(hrp.CFrame)
		rod.CFrame = CFrame.new(rHand.Position, rHand.Position + look) * CFrame.new(0,0,-10) -- đẩy ra trước
	end)
end

local function removeGiantArm()
	if giantUpdateConn then giantUpdateConn:Disconnect(); giantUpdateConn = nil end
	if giantArmFolder then giantArmFolder:Destroy(); giantArmFolder = nil end
end

local function toggleGiantArm()
	giantArmActive = not giantArmActive
	local char = player.Character; if not char then return end
	if giantArmActive then buildGiantArm(char) else removeGiantArm() end
end

-- Follow Magnet (nam châm hút người khác khi lại gần) – client-side fun
local function drawMagnetVisual(char)
	local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	magnetVisual = Instance.new("Part")
	magnetVisual.Name = "MagnetBubble"
	magnetVisual.Size = Vector3.new(1,1,1)
	magnetVisual.Shape = Enum.PartType.Ball
	magnetVisual.Color = Color3.fromRGB(0, 255, 200)
	magnetVisual.Material = Enum.Material.Neon
	magnetVisual.Transparency = 0.7
	magnetVisual.Anchored = true
	magnetVisual.CanCollide = false
	magnetVisual.Parent = workspace
	RunService.RenderStepped:Connect(function()
		if magnetVisual and hrp then
			magnetVisual.CFrame = hrp.CFrame
			magnetVisual.Size = Vector3.new(magnetRadius*2, magnetRadius*2, magnetRadius*2)
		end
	end)
end

local function removeMagnetVisual()
	if magnetVisual then magnetVisual:Destroy(); magnetVisual = nil end
end

local function toggleMagnet()
	magnetActive = not magnetActive
	local char = player.Character; if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end

	if magnetActive then
		drawMagnetVisual(char)
		magnetConn = RunService.Heartbeat:Connect(function()
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player and plr.Character then
					local th = plr.Character:FindFirstChild("HumanoidRootPart")
					if th then
						local d = (th.Position - hrp.Position).Magnitude
						if d < magnetRadius then
							-- Kéo nhẹ về phía mình (client-side)
							local dir = (hrp.Position - th.Position).Unit
							local newPos = th.Position + dir * 0.8 -- mỗi tick kéo 0.8 stud
							th.CFrame = CFrame.new(newPos, newPos + th.CFrame.LookVector)
						end
					end
				end
			end
		end)
	else
		if magnetConn then magnetConn:Disconnect(); magnetConn = nil end
		removeMagnetVisual()
	end
end

-- Seat Attach (gắn 1 ghế vào người mình để ai cũng có thể ngồi)
local function toggleSeatAttach()
	seatAttachActive = not seatAttachActive
	local char = player.Character; if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
	if seatAttachActive then
		local seat = Instance.new("Seat")
		seat.Name = "FollowerSeat"
		seat.Size = Vector3.new(2,1,2)
		seat.Color = Color3.fromRGB(255, 120, 120)
		seat.CanCollide = true
		seat.Massless = true
		seat.Parent = char
		seat.CFrame = hrp.CFrame * CFrame.new(0, 1.5, -2)
		makeWeld(seat, hrp)
		seatWelded = seat
	else
		if seatWelded then seatWelded:Destroy(); seatWelded = nil end
	end
end

-- =========================
-- Buttons (Main)
-- =========================

-- Infinite Jump
createButton("🟣 Nhảy vô hạn (toggle)", {Color3.fromRGB(255,0,200), Color3.fromRGB(120,0,255)}, function()
	infiniteJump = not infiniteJump
end)

UIS.JumpRequest:Connect(function()
	if infiniteJump then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- Float (đứng giữa không + vẫn di chuyển)
createButton("💠 Float (toggle)", {Color3.fromRGB(0,200,255), Color3.fromRGB(0,120,255)}, function()
	floatEnabled = not floatEnabled
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if floatEnabled and hrp then
		floatBV = Instance.new("BodyVelocity")
		floatBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		floatBV.Velocity = Vector3.zero
		floatBV.Parent = hrp

		task.spawn(function()
			while floatEnabled and floatBV and hrp and char and char.Parent do
				local hum = char:FindFirstChildOfClass("Humanoid")
				local dir = hum and hum.MoveDirection or Vector3.zero
				floatBV.Velocity = dir * speedValue
				task.wait()
			end
		end)
	else
		if floatBV then floatBV:Destroy(); floatBV = nil end
	end
end)

-- Speed
createButton("⚡ Chỉnh tốc độ", {Color3.fromRGB(255,170,0), Color3.fromRGB(255,80,0)}, function()
	promptNumber("Tốc độ đi bộ", "VD: 16 / 50 / 100", function(v)
		if v and v > 0 then
			speedValue = v
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = speedValue end
		end
	end)
end)

-- Buff máu
createButton("❤️ Buff máu", {Color3.fromRGB(255,60,60), Color3.fromRGB(255,120,180)}, function()
	promptNumber("Đặt máu (HP)", "VD: 100 / 500 / 9999", function(v)
		if v and v > 0 and player.Character then
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.MaxHealth = v
				hum.Health = v
			end
		end
	end)
end)

-- God Mode 2 lớp
createButton("🛡️ God Mode (toggle)", {Color3.fromRGB(160,160,255), Color3.fromRGB(100,0,255)}, function()
	godEnabled = not godEnabled
	if godEnabled then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then applyGod(hum) end
	else
		removeGod()
	end
end)

-- Body Size (slider realtime -100..100)
createButton("🧍 Body Size (slider)", {Color3.fromRGB(0,255,170), Color3.fromRGB(0,180,255)}, function()
	menuFrame.Visible = false
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 320, 0, 170)
	panel.Position = UDim2.new(0.5, -160, 0.5, -85)
	panel.BackgroundColor3 = Color3.fromRGB(25,25,35)
	panel.Parent = screenGui
	softCorner(panel, 16); fancyGradient(panel, Color3.fromRGB(0,200,200), Color3.fromRGB(255,0,160)); fancyStroke(panel, 2, Color3.fromRGB(255,255,255)); shadow(panel)
	panel.BackgroundTransparency = 1
	tweenProp(panel, "BackgroundTransparency", 1, 0, 0.2)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 28)
	title.Position = UDim2.new(0, 12, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "Body Size (-100 → 100)"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 28, 0, 28)
	close.Position = UDim2.new(1, -34, 0, 10)
	close.Text = "✕"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.TextColor3 = Color3.fromRGB(255,255,255)
	close.BackgroundColor3 = Color3.fromRGB(60,0,80)
	close.Parent = panel
	softCorner(close, 8); fancyStroke(close, 1, Color3.fromRGB(255,255,255))

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, -24, 0, 24)
	valueLabel.Position = UDim2.new(0, 12, 0, 44)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "Giá trị: 0  (≈ scale 1.0)"
	valueLabel.Font = Enum.Font.GothamSemibold
	valueLabel.TextSize = 16
	valueLabel.TextColor3 = Color3.fromRGB(255,255,255)
	valueLabel.Parent = panel

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 6)
	bar.Position = UDim2.new(0, 12, 0, 84)
	bar.BackgroundColor3 = Color3.fromRGB(60,60,80)
	bar.Parent = panel
	softCorner(bar, 6)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.5, 0, 1, 0)
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255,255,255)
	fill.BackgroundTransparency = 0.6
	fill.Parent = bar
	softCorner(fill, 6)

	local knob = Instance.new("ImageButton")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.BackgroundTransparency = 1
	knob.Image = "rbxassetid://3570695787"
	knob.ImageColor3 = Color3.fromRGB(255,255,255)
	knob.Parent = panel

	local function setKnobByValue(v) -- v: -100..100
		v = math.clamp(v, -100, 100)
		local x0 = bar.AbsolutePosition.X
		local w = bar.AbsoluteSize.X
		local alpha = (v + 100)/200 -- 0..1
		local x = x0 + alpha * w
		knob.Position = UDim2.fromOffset(x - 9, bar.AbsolutePosition.Y - 6)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		return v
	end

	local function vToScale(v)
		return math.clamp(1 + (v/10), 0.05, 100)
	end

	local function applyScale(v)
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		local height = hum:FindFirstChild("BodyHeightScale")
		local width  = hum:FindFirstChild("BodyWidthScale")
		local depth  = hum:FindFirstChild("BodyDepthScale")
		local head   = hum:FindFirstChild("HeadScale")

		local s = vToScale(v)
		valueLabel.Text = string.format("Giá trị: %d  (≈ scale %.2f)", v, s)

		if height and width and depth and head then
			height.Value = s; width.Value = s; depth.Value = s; head.Value = math.clamp(s, 0.05, 100)
		else
			valueLabel.Text = valueLabel.Text .. "  | R6/Locked"
		end
	end

	local dragging = false
	local function updateFromMouse(mx)
		local x0 = bar.AbsolutePosition.X
		local w = bar.AbsoluteSize.X
		local alpha = math.clamp((mx - x0)/w, 0, 1)
		local v = math.floor(alpha*200 - 100 + 0.5)
		setKnobByValue(v)
		applyScale(v)
	end

	knob.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = true end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UIS.InputChanged:Connect(function(inp)
		if not dragging then return end
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			updateFromMouse(inp.Position.X)
		end
	end)
	bar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			updateFromMouse(inp.Position.X)
			dragging = true
		end
	end)

	setKnobByValue(0); applyScale(0)

	close.MouseButton1Click:Connect(function()
		tweenProp(panel, "BackgroundTransparency", 0, 1, 0.2).Completed:Wait()
		panel:Destroy()
		menuFrame.Visible = true
	end)
end)

-- Teleport
createButton("🧭 Teleport tới người chơi", {Color3.fromRGB(0,255,170), Color3.fromRGB(0,180,255)}, function()
	promptPlayerSelect(function(targetPlr)
		local myChar = player.Character
		local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local trg = targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart")
		if hrp and trg then
			hrp.CFrame = trg.CFrame + Vector3.new(0,2,0)
		end
	end)
end)

-- Rejoin
createButton("🔁 Rejoin", {Color3.fromRGB(160,160,255), Color3.fromRGB(100,0,255)}, function()
	TeleportService:Teleport(game.PlaceId, player)
end)

-- Server Hop
createButton("🌐 Server Hop", {Color3.fromRGB(0,255,120), Color3.fromRGB(0,200,255)}, function()
	local ok, res = pcall(function()
		return HttpService:GetAsync(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId))
	end)
	if not ok then
		warn("Không thể lấy danh sách server (có thể game khoá HTTP).")
		return
	end
	local data = HttpService:JSONDecode(res)
	local options = {}
	for _, s in ipairs(data.data or {}) do
		if s.playing < s.maxPlayers and s.id ~= game.JobId then
			table.insert(options, s.id)
		end
	end
	if #options > 0 then
		TeleportService:TeleportToPlaceInstance(game.PlaceId, options[math.random(1,#options)], player)
	else
		warn("Không tìm thấy server trống để hop.")
	end
end)

-- Spawn Classic Sword (local basic)
createButton("🗡️ Spawn Classic Sword", {Color3.fromRGB(255,200,0), Color3.fromRGB(255,0,0)}, function()
	local char = player.Character
	if not char then return end

	local tool = Instance.new("Tool")
	tool.Name = "Classic Sword"
	tool.RequiresHandle = true
	tool.CanBeDropped = true
	tool.Parent = player.Backpack

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 4, 0.5)
	handle.Color = Color3.fromRGB(30,30,30)
	handle.Massless = true
	handle.CanCollide = false
	handle.Parent = tool
	local weld = Instance.new("WeldConstraint", handle)

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.2, 3.2, 0.3)
	blade.Color = Color3.fromRGB(200,200,200)
	blade.Massless = true
	blade.CanCollide = false
	blade.Parent = tool
	local weld2 = Instance.new("WeldConstraint")
	weld2.Part0 = handle
	weld2.Part1 = blade
	weld2.Parent = handle
	blade.CFrame = handle.CFrame * CFrame.new(0, 3.2/2, 0)

	tool.Equipped:Connect(function()
		if char and char:FindFirstChild("RightHand") then
			weld.Part0 = char.RightHand
			weld.Part1 = handle
			handle.CFrame = char.RightHand.CFrame
		end
	end)

	local attacking = false
	local dmg = 25
	local hitCooldown = {}
	local function canHit(hum)
		if not hum or hum.Parent == char then return false end
		if hitCooldown[hum] and tick() - hitCooldown[hum] < 0.35 then return false end
		return true
	end
	local function tagHit(hum) hitCooldown[hum] = tick() end
	local function doSlash() attacking = true; task.delay(0.25, function() attacking = false end) end
	tool.Activated:Connect(function() if attacking then return end doSlash() end)
	local function onTouched(part)
		if not attacking then return end
		local hum = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
		if canHit(hum) then tagHit(hum); hum:TakeDamage(dmg) end
	end
	handle.Touched:Connect(onTouched)
	blade.Touched:Connect(onTouched)
end)

-- ===== Troll Menu (5 trò) =====
local function openTrollMenu()
	menuFrame.Visible = false
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 320, 0, 300)
	frame.Position = UDim2.new(0.5, -160, 0.5, -150)
	frame.BackgroundColor3 = Color3.fromRGB(25,25,35)
	frame.Parent = screenGui
	softCorner(frame, 18); fancyGradient(frame, Color3.fromRGB(255,180,0), Color3.fromRGB(255,0,150)); fancyStroke(frame, 2, Color3.fromRGB(255,255,255)); shadow(frame)
	frame.BackgroundTransparency = 1
	tweenProp(frame, "BackgroundTransparency", 1, 0, 0.2)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 36)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "😈 Troll Menu"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 20
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.Parent = frame

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -20, 1, -60)
	holder.Position = UDim2.new(0, 10, 0, 50)
	holder.BackgroundTransparency = 1
	holder.Parent = frame

	local l = Instance.new("UIListLayout")
	l.Parent = holder
	l.Padding = UDim.new(0, 8)

	local function tbtn(text, colors, cb)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 42)
		b.Text = text
		b.TextColor3 = Color3.fromRGB(255,255,255)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 16
		b.BackgroundColor3 = Color3.fromRGB(50,50,70)
		b.Parent = holder
		softCorner(b, 10); fancyGradient(b, colors[1], colors[2]); fancyStroke(b, 1, Color3.fromRGB(255,255,255))
		b.MouseButton1Click:Connect(function() if cb then cb() end end)
	end

	-- 1) Plane Ride
	tbtn("✈️ Plane Ride (toggle)", {Color3.fromRGB(0,255,200), Color3.fromRGB(0,140,255)}, function() togglePlane() end)

	-- 2) Head Spin
	tbtn("🌀 Head Spin (toggle)", {Color3.fromRGB(180,180,255), Color3.fromRGB(80,0,255)}, function() toggleHeadSpin() end)

	-- 3) Giant Arm Grab
	tbtn("💪 Giant Arm Grab (toggle)", {Color3.fromRGB(255,170,0), Color3.fromRGB(255,70,0)}, function() toggleGiantArm() end)

	-- 4) Follow Magnet
	tbtn("🧲 Follow Magnet (toggle)", {Color3.fromRGB(0,255,150), Color3.fromRGB(0,200,255)}, function() toggleMagnet() end)

	-- 5) Seat Attach
	tbtn("🪑 Seat Attach (toggle)", {Color3.fromRGB(255,120,120), Color3.fromRGB(255,0,160)}, function() toggleSeatAttach() end)

	-- Close
	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 28, 0, 28)
	close.Position = UDim2.new(1, -38, 0, 10)
	close.Text = "✕"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.TextColor3 = Color3.fromRGB(255,255,255)
	close.BackgroundColor3 = Color3.fromRGB(60,0,80)
	close.Parent = frame
	softCorner(close, 8); fancyStroke(close, 1, Color3.fromRGB(255,255,255))
	close.MouseButton1Click:Connect(function()
		tweenProp(frame, "BackgroundTransparency", 0, 1, 0.2).Completed:Wait()
		frame:Destroy()
		menuFrame.Visible = true
	end)
end

-- Nút mở Troll Menu (đặt cuối danh sách)
createButton("😈 Troll Menu", {Color3.fromRGB(255,180,0), Color3.fromRGB(255,0,150)}, function()
	openTrollMenu()
end)

-- =========================
-- Giữ trạng thái sau respawn
-- =========================
player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum.WalkSpeed = speedValue

	-- God Mode
	if godEnabled then task.defer(applyGod, hum) end

	-- reset float (an toàn)
	if floatBV then floatBV:Destroy(); floatBV = nil end
	floatEnabled = false

	-- Re-attach trolls nếu đang bật
	if planeActive then task.defer(function() removePlaneRig(char); buildPlaneRig(char) end) end
	if headSpinActive then task.defer(function()
		local neck = getNeck(char); if neck then savedNeckC0 = neck.C0 end
		toggleHeadSpin(); toggleHeadSpin() -- bật lại (off->on để khởi động loop)
	end) end
	if giantArmActive then task.defer(function() removeGiantArm(); buildGiantArm(char) end) end
	if magnetActive then task.defer(function() if magnetConn then magnetConn:Disconnect() end; toggleMagnet(); toggleMagnet() end) end
	if seatAttachActive then task.defer(function() if seatWelded then seatWelded:Destroy() end; toggleSeatAttach(); end) end
end)