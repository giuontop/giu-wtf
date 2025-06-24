local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "CamlockUI"
gui.ResetOnSpawn = false

-- Fonction de style bouton
local function createButton(name, text, posY)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 150, 0, 40)
	button.Position = UDim2.new(0.5, -75, 1, -posY)
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 16
	button.Font = Enum.Font.SourceSansBold
	button.Text = text
	button.BorderColor3 = Color3.fromRGB(255, 255, 255)
	button.BorderSizePixel = 1
	button.ZIndex = 10
	button.Parent = gui

	local corner = Instance.new("UICorner", button)
	corner.CornerRadius = UDim.new(0, 10)

	return button
end

-- Boutons
local camlockButton = createButton("Camlock", "Camlock: OFF", 140)
local espButton = createButton("ESP", "ESP: OFF", 90)
local speedButton = createButton("Speed", "Speed: OFF", 40)

-- Petit point blanc avec contour
local lockDot = Instance.new("Frame")
lockDot.Size = UDim2.new(0, 8, 0, 8)
lockDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockDot.BorderColor3 = Color3.fromRGB(200, 200, 200)
lockDot.BorderSizePixel = 1
lockDot.Visible = false
lockDot.AnchorPoint = Vector2.new(0.5, 0.5)
lockDot.Position = UDim2.new(0.5, 0, 0.5, 0)
lockDot.ZIndex = 20
lockDot.Parent = gui

local lockCorner = Instance.new("UICorner", lockDot)
lockCorner.CornerRadius = UDim.new(1, 0)

-- ESP noms
local nameLabels = {}

local camlockActive = false
local espActive = false
local speedActive = false
local target = nil

-- Get closest player
local function getClosestPlayer()
	local closest, dist = nil, math.huge
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
			if onScreen then
				local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
				if mag < dist then
					dist = mag
					closest = plr
				end
			end
		end
	end
	return closest
end

-- Update ESP
local function updateESP()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
			if not nameLabels[plr] then
				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(0, 100, 0, 14)
				label.BackgroundTransparency = 1
				label.TextColor3 = Color3.new(1, 1, 1)
				label.TextStrokeTransparency = 0.5
				label.Font = Enum.Font.SourceSans
				label.TextSize = 13
				label.Text = plr.Name
				label.ZIndex = 9
				label.AnchorPoint = Vector2.new(0.5, 1)
				label.Parent = gui
				nameLabels[plr] = label
			end
		end
	end
end

-- Remove ESP if dead
local function cleanupESP()
	for plr, label in pairs(nameLabels) do
		if not plr.Character or not plr.Character:FindFirstChild("Head") then
			label:Destroy()
			nameLabels[plr] = nil
		end
	end
end

-- Render loop
RunService.RenderStepped:Connect(function()
	updateESP()
	cleanupESP()

	-- ESP
	for plr, label in pairs(nameLabels) do
		if espActive and plr.Character and plr.Character:FindFirstChild("Head") then
			local headPos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position + Vector3.new(0, 0.3, 0))
			label.Visible = onScreen
			label.Position = UDim2.new(0, headPos.X, 0, headPos.Y)
		elseif label then
			label.Visible = false
		end
	end

	-- Camlock
	if camlockActive and target and target.Character and target.Character:FindFirstChild("Head") then
		local head = target.Character.Head
		local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
		if visible then
			lockDot.Visible = true
			lockDot.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
		else
			lockDot.Visible = false
		end
	else
		lockDot.Visible = false
	end
end)

-- Button toggles
camlockButton.MouseButton1Click:Connect(function()
	if camlockActive then
		camlockActive = false
		target = nil
		camlockButton.Text = "Camlock: OFF"
	else
		target = getClosestPlayer()
		if target then
			camlockActive = true
			camlockButton.Text = "Camlock: ON"
		end
	end
end)

espButton.MouseButton1Click:Connect(function()
	espActive = not espActive
	espButton.Text = "ESP: " .. (espActive and "ON" or "OFF")
end)

speedButton.MouseButton1Click:Connect(function()
	speedActive = not speedActive
	speedButton.Text = "Speed: " .. (speedActive and "ON" or "OFF")
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speedActive and 130 or 16
	end
end)
