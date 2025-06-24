local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "CheatUI"
gui.ResetOnSpawn = false

-- Fonction pour créer un bouton
local function createTopButton(name, text, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 110, 0, 30)
	button.Position = UDim2.new(0, 10 + (position * 120), 0, 10)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 14
	button.Text = text
	button.Parent = gui
	button.BorderSizePixel = 1
	button.BorderColor3 = Color3.fromRGB(255, 255, 255)

	local corner = Instance.new("UICorner", button)
	corner.CornerRadius = UDim.new(0, 8)

	return button
end

-- Créer les boutons
local camlockBtn = createTopButton("Camlock", "Camlock: OFF", 0)
local espBtn = createTopButton("ESP", "ESP: OFF", 1)
local speedBtn = createTopButton("Speed", "Speed: OFF", 2)
local silentAimBtn = createTopButton("SilentAim", "SilentAim: OFF", 3)
local flyBtn = createTopButton("Fly", "Fly: OFF", 4)
local ejectBtn = createTopButton("Eject", "Eject", 5)

-- États
local camlock = false
local esp = false
local speed = false
local silentAim = false
local target = nil
local nameLabels = {}
local bodyVelocity = nil

-- Dot Camlock
local lockDot = Instance.new("Frame")
lockDot.Size = UDim2.new(0, 8, 0, 8)
lockDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockDot.BorderColor3 = Color3.fromRGB(200, 200, 200)
lockDot.BorderSizePixel = 1
lockDot.AnchorPoint = Vector2.new(0.5, 0.5)
lockDot.Visible = false
lockDot.ZIndex = 20
lockDot.Parent = gui
Instance.new("UICorner", lockDot).CornerRadius = UDim.new(1, 0)

-- FOV Circle
local fovCircle = Instance.new("Frame", gui)
fovCircle.Size = UDim2.new(0, 300, 0, 300)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 1
fovCircle.BorderColor3 = Color3.fromRGB(255, 255, 255)
fovCircle.Visible = false
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)

-- Fonction pour trouver la cible la plus proche dans le FOV
local function getClosestInFOV()
	local closest, dist = nil, 999999
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
			local head = plr.Character.Head.Position
			local pos, onScreen = Camera:WorldToViewportPoint(head)
			local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
			if onScreen and mag < 150 and mag < dist then
				dist = mag
				closest = plr
			end
		end
	end
	return closest
end

-- ESP
local function updateESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
			if not nameLabels[plr] then
				local lbl = Instance.new("TextLabel", gui)
				lbl.Size = UDim2.new(0, 100, 0, 14)
				lbl.BackgroundTransparency = 1
				lbl.TextColor3 = Color3.new(1, 1, 1)
				lbl.TextStrokeTransparency = 0.5
				lbl.Font = Enum.Font.SourceSans
				lbl.TextSize = 13
				lbl.Text = plr.Name
				lbl.AnchorPoint = Vector2.new(0.5, 1)
				lbl.ZIndex = 9
				nameLabels[plr] = lbl
			end
		end
	end
end

-- Silent Aim Hook
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldIndex = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
	local args = {...}
	local method = getnamecallmethod()

	if silentAim and tostring(self):lower():find("ray") and method == "FireServer" then
		local closest = getClosestInFOV()
		if closest and closest.Character and closest.Character:FindFirstChild("Head") then
			local head = closest.Character.Head.Position
			args[2] = head
			return oldIndex(self, unpack(args))
		end
	end

	return oldIndex(self, ...)
end)

-- Fonction pour désactiver et nettoyer
local function eject()
	camlock = false
	esp = false
	speed = false
	silentAim = false
	fly = false
	target = nil

	-- Reset Humanoid speed
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.WalkSpeed = 16
	end

	-- Supprimer BodyVelocity si existe
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	-- Supprimer labels ESP
	for _, lbl in pairs(nameLabels) do
		if lbl and lbl.Parent then
			lbl:Destroy()
		end
	end
	nameLabels = {}

	-- Supprimer GUI
	if gui and gui.Parent then
		gui:Destroy()
	end

	-- Reset metatable
	mt.__namecall = oldIndex
	setreadonly(mt, true)
end

-- Render Loop
RunService.RenderStepped:Connect(function()
	updateESP()

	for plr, lbl in pairs(nameLabels) do
		if plr.Character and plr.Character:FindFirstChild("Head") then
			local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position + Vector3.new(0, 0.5, 0))
			lbl.Visible = esp and onScreen
			if lbl.Visible then
				lbl.Position = UDim2.new(0, pos.X, 0, pos.Y)
			end
		end
	end

	if camlock then
		target = getClosestInFOV()
		if target and target.Character and target.Character:FindFirstChild("Head") then
			local targetPos = target.Character.Head.Position
			local camPos = Camera.CFrame.Position

			-- Calcul rotation sticky (lerp smooth)
			local desiredCFrame = CFrame.new(camPos, targetPos)
			Camera.CFrame = Camera.CFrame:Lerp(desiredCFrame, 0.15)

			local pos, visible = Camera:WorldToViewportPoint(targetPos)
			lockDot.Visible = visible
			if visible then
				lockDot.Position = UDim2.new(0, pos.X, 0, pos.Y)
			end
		else
			lockDot.Visible = false
		end
	else
		lockDot.Visible = false
	end

	if speed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.WalkSpeed = 130
	elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.WalkSpeed = 16
	end

	if fly then
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			if not bodyVelocity then
				bodyVelocity = Instance.new("BodyVelocity", hrp)
				bodyVelocity.Velocity = Vector3.new(0, 0, 0)
				bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			end
			local moveDir = LocalPlayer:GetMouse().Hit.p - hrp.Position
			bodyVelocity.Velocity = moveDir.Unit * 80
		end
	else
		if bodyVelocity then
			bodyVelocity:Destroy()
			bodyVelocity = nil
		end
	end
end)

-- Boutons
camlockBtn.MouseButton1Click:Connect(function()
	camlock = not camlock
	camlockBtn.Text = "Camlock: " .. (camlock and "ON" or "OFF")
end)

espBtn.MouseButton1Click:Connect(function()
	esp = not esp
	espBtn.Text = "ESP: " .. (esp and "ON" or "OFF")
end)

speedBtn.MouseButton1Click:Connect(function()
	speed = not speed
	speedBtn.Text = "Speed: " .. (speed and "ON" or "OFF")
end)

silentAimBtn.MouseButton1Click:Connect(function()
	silentAim = not silentAim
	silentAimBtn.Text = "SilentAim: " .. (silentAim and "ON" or "OFF")
	fovCircle.Visible = silentAim
end)

ejectBtn.MouseButton1Click:Connect(function()
	eject()
end)
