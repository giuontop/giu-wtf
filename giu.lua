-- Da Hood | Script éducatif : Speed + ESP + Cible + Eject
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ▼ CONFIG
local NORMAL_SPEED = 16
local FAST_SPEED = 130
local speedKey = Enum.KeyCode.C
local cibleKey = Enum.KeyCode.Q
local hitboxSize = Vector3.new(30,30,30)

-- ▼ ÉTAT
local speedOn = false
local rainbowHL = nil
local target = nil
local lineBeam = nil
local guiRoot = nil
local espFolder = nil

-- ▼ UTILS
local function notify(title, text, uid)
	local thumb = ""
	pcall(function()
		thumb = Players:GetUserThumbnailAsync(uid or player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Icon = thumb,
			Duration = 3
		})
	end)
end

local function addRainbowOutline()
	if rainbowHL then rainbowHL:Destroy() end
	local hl = Instance.new("Highlight")
	hl.Name = "RainbowOutline"
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.OutlineColor = Color3.new(1,0,0)
	hl.Adornee = player.Character
	hl.Parent = player.Character
	rainbowHL = hl

	local hue = 0
	RunService.RenderStepped:Connect(function()
		if rainbowHL and speedOn then
			hue = (hue + 0.01) % 1
			rainbowHL.OutlineColor = Color3.fromHSV(hue,1,1)
		end
	end)
end

local function toggleSpeed()
	speedOn = not speedOn
	notify("Speed", speedOn and "Activé (130)" or "Désactivé (16)", player.UserId)
	if speedOn then
		addRainbowOutline()
	else
		if rainbowHL then rainbowHL:Destroy(); rainbowHL=nil end
	end
end

-- ▼ ESP
local function createBillboard(char, text)
	local bb = Instance.new("BillboardGui")
	bb.Name = "ESP"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0,200, 0,50)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.Adornee = char:WaitForChild("Head")

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 20
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.TextStrokeTransparency = 0
	lbl.Text = text

	bb.Parent = espFolder
end

local function setupESPForPlayer(plr)
	local function onChar(char)
		for _,v in ipairs(espFolder:GetChildren()) do
			if v:IsA("BillboardGui") and v.Adornee and v.Adornee:IsDescendantOf(char) then
				v:Destroy()
			end
		end
		createBillboard(char, plr.DisplayName or plr.Name)
	end
	if plr.Character then onChar(plr.Character) end
	plr.CharacterAdded:Connect(onChar)
end

local function initESP()
	espFolder = Instance.new("Folder")
	espFolder.Name = "ESP_Folder"
	espFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")

	for _,plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			setupESPForPlayer(plr)
		end
	end
	Players.PlayerAdded:Connect(function(plr)
		if plr ~= player then
			setupESPForPlayer(plr)
		end
	end)
end

-- ▼ CIBLE
local function clearTargetArtifacts()
	if lineBeam then lineBeam:Destroy(); lineBeam=nil end
	if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = target.Character.HumanoidRootPart
		hrp.Size = Vector3.new(2,2,1)
		hrp.Transparency = 0
		hrp.Material = Enum.Material.Plastic
	end
end

local function lockOnTarget()
	if target then
		notify("Cible retirée", target.Name, target.UserId)
		clearTargetArtifacts()
		target = nil
		return
	end

	local cam = Workspace.CurrentCamera
	local closest, minDist = nil, math.huge
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local pos, onScreen = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
			if onScreen then
				local dist = (Vector2.new(mouse.X,mouse.Y) - Vector2.new(pos.X,pos.Y)).Magnitude
				if dist < minDist then
					minDist, closest = dist, plr
				end
			end
		end
	end
	if not closest then return end

	target = closest
	notify("Cible verrouillée", closest.Name, closest.UserId)

	local a0 = Instance.new("Attachment", player.Character:WaitForChild("HumanoidRootPart"))
	local a1 = Instance.new("Attachment", closest.Character:WaitForChild("HumanoidRootPart"))
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.1
	beam.Width1 = 0.1
	beam.Color = ColorSequence.new(Color3.new(1,0,0))
	beam.FaceCamera = true
	beam.Parent = player.Character
	lineBeam = beam

	local hrp = closest.Character.HumanoidRootPart
	hrp.Size = hitboxSize
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Material = Enum.Material.Neon
end

-- ▼ GUI
local function createGUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CheatGUI"
	gui.ResetOnSpawn = false
	pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end
	guiRoot = gui

	local function makeBtn(text,pos,col)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,130,0,45)
		b.Position = pos
		b.Text = text
		b.BackgroundColor3 = col
		b.TextColor3 = Color3.new(1,1,1)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 20
		b.BorderSizePixel = 0
		b.Active, b.Draggable = true,true
		b.Parent = gui
		return b
	end

	local speedBtn = makeBtn("Speed : OFF", UDim2.new(0,20,0.7,0), Color3.fromRGB(25,25,25))
	speedBtn.MouseButton1Click:Connect(function()
		toggleSpeed()
		speedBtn.Text = speedOn and "Speed : ON" or "Speed : OFF"
	end)

	local cibleBtn = makeBtn("🎯 Cible", UDim2.new(0,20,0.6,0), Color3.fromRGB(40,80,160))
	cibleBtn.MouseButton1Click:Connect(lockOnTarget)

	local ejectBtn = makeBtn("❌ Eject", UDim2.new(0,20,0.8,0), Color3.fromRGB(180,40,40))
	ejectBtn.MouseButton1Click:Connect(function()
		speedOn = false
		clearTargetArtifacts()
		if rainbowHL then rainbowHL:Destroy(); rainbowHL=nil end
		if guiRoot then guiRoot:Destroy() end
		if espFolder then espFolder:Destroy() end
		target = nil
		notify("Cheats désactivés","Nettoyé",player.UserId)
	end)
end

-- ▼ LOOP
RunService.RenderStepped:Connect(function()
	if not player.Character then return end
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = speedOn and FAST_SPEED or NORMAL_SPEED
	end
end)

UserInputService.InputBegan:Connect(function(inp,gpe)
	if gpe then return end
	if inp.KeyCode == speedKey then
		toggleSpeed()
	elseif inp.KeyCode == cibleKey then
		lockOnTarget()
	end
end)

-- ▼ INIT
createGUI()
initESP()
notify("Script chargé","Speed [C] | Cible [Q] | GUI boutons",player.UserId)
