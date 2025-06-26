-- Da Hood | Cheat éducatif : Speed + ESP + Cible Mobile/PC

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local NORMAL_SPEED = 16
local FAST_SPEED = 130
local KEY_SPEED = Enum.KeyCode.C
local KEY_CIBLE = Enum.KeyCode.Q
local HITBOX_SIZE = Vector3.new(30, 30, 30)

local speedOn = false
local rainbowHL, target, lineBeam, guiRoot

local function notify(title, text, uid)
    local thumb
    pcall(function()
        thumb = Players:GetUserThumbnailAsync(uid or player.UserId,
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Icon = thumb, Duration = 3
        })
    end)
end

-- Rainbow Highlight
local function addRainbow()
    if rainbowHL then rainbowHL:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Name = "RainbowHL"
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.new(1, 0, 0)
    hl.Adornee = player.Character
    hl.Parent = player.Character
    rainbowHL = hl

    local hue = 0
    RunService.RenderStepped:Connect(function()
        if rainbowHL and speedOn then
            hue = (hue + 0.01) % 1
            rainbowHL.OutlineColor = Color3.fromHSV(hue, 1, 1)
        end
    end)
end

-- Toggle Speed
local function toggleSpeed()
    speedOn = not speedOn
    notify("Speed", speedOn and "Activé (130)" or "Désactivé (16)", player.UserId)
    if speedOn then addRainbow() else
        if rainbowHL then rainbowHL:Destroy() rainbowHL = nil end
    end
end

-- ESP Basique (affiche noms plus petits)
local function createESPForCharacter(char, plr)
    local head = char:WaitForChild("Head", 5)
    if not head then return end
    if head:FindFirstChild("NameESP") then return end

    local esp = Instance.new("BillboardGui")
    esp.Name = "NameESP"
    esp.AlwaysOnTop = true
    esp.Size = UDim2.new(0, 100, 0, 10)
    esp.StudsOffset = Vector3.new(0, 2, 0)
    esp.Adornee = head
    esp.Parent = head

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = plr.DisplayName
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextStrokeTransparency = 0
    text.TextStrokeColor3 = Color3.new(0, 0, 0)
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.TextSize = 6
    text.Parent = esp
end

local function setupESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if plr.Character then
                createESPForCharacter(plr.Character, plr)
            end
            plr.CharacterAdded:Connect(function(char)
                createESPForCharacter(char, plr)
            end)
        end
    end
    Players.PlayerAdded:Connect(function(plr)
        if plr ~= player then
            plr.CharacterAdded:Connect(function(char)
                createESPForCharacter(char, plr)
            end)
        end
    end)
end

-- Ciblage
local function clearTarget()
    if lineBeam then lineBeam:Destroy(); lineBeam = nil end
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = target.Character.HumanoidRootPart
        hrp.Size = Vector3.new(2, 2, 1)
        hrp.Transparency = 0
        hrp.Material = Enum.Material.Plastic
    end
end

local function getClosestToScreenCenter()
    local cam = Workspace.CurrentCamera
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, visible = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if visible then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

local function getClosestToCursor()
    local cam = Workspace.CurrentCamera
    local cursor = Vector2.new(mouse.X, mouse.Y)
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, visible = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if visible then
                local dist = (Vector2.new(pos.X, pos.Y) - cursor).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

local function lockTarget(fromButton)
    if target then
        notify("Cible retirée", target.Name, target.UserId)
        clearTarget()
        target = nil
        return
    end

    local newTarget = fromButton and getClosestToScreenCenter() or getClosestToCursor()
    if not newTarget then return end
    target = newTarget
    notify("Ciblé", target.Name, target.UserId)

    local a0 = Instance.new("Attachment", player.Character:WaitForChild("HumanoidRootPart"))
    local a1 = Instance.new("Attachment", target.Character:WaitForChild("HumanoidRootPart"))
    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Width0 = 0.1
    beam.Width1 = 0.1
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
    })
    beam.FaceCamera = true
    beam.Parent = player.Character
    lineBeam = beam

    local hrp = target.Character.HumanoidRootPart
    hrp.Size = HITBOX_SIZE
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Material = Enum.Material.Neon
end

-- GUI
local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CheatGUI"
    gui.ResetOnSpawn = false
    gui.Parent = (gethui and gethui()) or player:WaitForChild("PlayerGui")
    guiRoot = gui

    local function mkBtn(text, posX, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.Position = UDim2.new(0, posX, 0, 0.8)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 30
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.BorderSizePixel = 0
        btn.Parent = gui
        btn.MouseButton1Click:Connect(callback)
    end

    mkBtn("🚀", 20, toggleSpeed)
    mkBtn("🎯", 90, function() lockTarget(true) end)
    mkBtn("📍", 160, function()
        local giu = Players:FindFirstChild("Giuliqn")
        if giu and giu.Character and giu.Character:FindFirstChild("HumanoidRootPart") then
            local root = giu.Character.HumanoidRootPart
            player.Character:PivotTo(CFrame.new(root.Position + Vector3.new(0, 5, 0)))
        else
            notify("Tp Giu", "Giuliqn introuvable", player.UserId)
        end
    end)
end

-- Bind PC
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == KEY_SPEED then toggleSpeed() end
    if input.KeyCode == KEY_CIBLE then lockTarget(false) end
end)

RunService.RenderStepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = speedOn and FAST_SPEED or NORMAL_SPEED
    end
end)

createGUI()
setupESP()
notify("Script prêt", "C = Speed | Q = Cible | 🎯 Mobile", player.UserId)
