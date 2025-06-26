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
local HITBOX_SIZE = Vector3.new(30, 30, 30) -- hitbox cible agrandie

local speedOn = false
local rainbowHL, target, lineBeam, guiRoot, targetHL

------------------------------------------------------------------------
-- UTILS
------------------------------------------------------------------------
local function notify(title, text, uid)
    local thumb = ""
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

-- Crée/retourne un highlight rainbow autour du personnage passé
local function addRainbowHighlight(char)
    local hl = Instance.new("Highlight")
    hl.Name = "RainbowHL"
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.new(1,0,0)
    hl.Adornee = char
    hl.Parent = char

    local hue = 0
    RunService.RenderStepped:Connect(function()
        if hl and hl.Parent then
            hue = (hue + 0.01) % 1
            hl.OutlineColor = Color3.fromHSV(hue,1,1)
        end
    end)
    return hl
end

local function addRainbow()
    if rainbowHL then rainbowHL:Destroy() end
    rainbowHL = addRainbowHighlight(player.Character)
end

------------------------------------------------------------------------
-- SPEED
------------------------------------------------------------------------
local function toggleSpeed()
    speedOn = not speedOn
    notify("Speed", speedOn and "Activé (130)" or "Désactivé (16)", player.UserId)
    if speedOn then addRainbow() elseif rainbowHL then rainbowHL:Destroy() rainbowHL=nil end
end

------------------------------------------------------------------------
-- ESP simple : nom au-dessus de chaque joueur (sauf toi)
------------------------------------------------------------------------
local function createESP(char, plr)
    local head = char:FindFirstChild("Head")
    if not head or head:FindFirstChild("NameESP") then return end

    local esp = Instance.new("BillboardGui")
    esp.Name = "NameESP"
    esp.AlwaysOnTop = true
    esp.Size = UDim2.new(0, 100, 0, 10) -- taille plus petite
    esp.StudsOffset = Vector3.new(0,2,0)
    esp.Adornee = head
    esp.Parent = head

    local lbl = Instance.new("TextLabel", esp)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = plr.DisplayName
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
end

local function setupESP()
    local function onPlayer(p)
        if p == player then return end
        local function charAdded(char)
            createESP(char, p)
        end
        if p.Character then charAdded(p.Character) end
        p.CharacterAdded:Connect(charAdded)
    end
    for _,p in ipairs(Players:GetPlayers()) do onPlayer(p) end
    Players.PlayerAdded:Connect(onPlayer)
end

------------------------------------------------------------------------
-- TARGETING
------------------------------------------------------------------------
local function clearTarget()
    if lineBeam then lineBeam:Destroy() lineBeam=nil end
    if targetHL then targetHL:Destroy() targetHL=nil end
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = target.Character.HumanoidRootPart
        hrp.Size = Vector3.new(2,2,1)
        hrp.Transparency = 0
        hrp.Material = Enum.Material.Plastic
    end
end

local function getClosest(plist)
    local cam = Workspace.CurrentCamera
    local best, dist = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pos, vis = cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if vis then
                local d = (plist - Vector2.new(pos.X,pos.Y)).Magnitude
                if d<dist then dist,best=d,p end
            end
        end
    end
    return best
end

local function lockTarget(fromButton)
    if target then
        notify("Cible retirée", target.Name, target.UserId)
        clearTarget() target=nil return
    end

    local cam = Workspace.CurrentCamera
    local choice
    if fromButton then -- mobile centre écran
        choice = getClosest(Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2))
    else -- curseur PC
        choice = getClosest(Vector2.new(mouse.X, mouse.Y))
    end
    if not choice then return end
    target = choice
    notify("Ciblé", target.Name, target.UserId)

    -- Beam arc‑en‑ciel
    local at0 = Instance.new("Attachment", player.Character:WaitForChild("HumanoidRootPart"))
    local at1 = Instance.new("Attachment", target.Character:WaitForChild("HumanoidRootPart"))
    local beam = Instance.new("Beam")
    beam.Attachment0, beam.Attachment1 = at0, at1
    beam.Width0, beam.Width1 = 0.1, 0.1
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,165,0)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.84, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))
    })
    beam.FaceCamera = true
    beam.Parent = player.Character
    lineBeam = beam

    -- hitbox agrandie
    local hrp = target.Character.HumanoidRootPart
    hrp.Size = HITBOX_SIZE
    hrp.Transparency = 1
    hrp.CanCollide = false
    hrp.Material = Enum.Material.Neon

    -- highlight rainbow sur cible
    targetHL = addRainbowHighlight(target.Character)
end

------------------------------------------------------------------------
-- GUI & CONTROLS
------------------------------------------------------------------------
local function createGUI()
    local gui = Instance.new("ScreenGui", (gethui and gethui()) or player:WaitForChild("PlayerGui"))
    gui.Name="CheatGUI" gui.ResetOnSpawn=false guiRoot=gui

    local function btn(txt,x,callback)
        local b=Instance.new("TextButton",gui)
        b.Size=UDim2.new(0,50,0,50) b.Position=UDim2.new(0,x,0,0.8)
        b.Text=txt b.Font=Enum.Font.GothamBold b.TextSize=30
        b.TextColor3=Color3.new(1,1,1) b.BackgroundColor3=Color3.fromRGB(40,40,40)
        b.BorderSizePixel=0 b.MouseButton1Click:Connect(callback)
    end
    btn("🚀",20,toggleSpeed)
    btn("🎯",90,function() lockTarget(true) end)
    btn("🌀",160,function()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            player.Character:PivotTo(target.Character.HumanoidRootPart.CFrame+Vector3.new(0,5,0))
        else notify("Tp Cible","Aucune cible",player.UserId) end
    end)
end

UserInputService.InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode==KEY_SPEED then toggleSpeed()
    elseif i.KeyCode==KEY_CIBLE then lockTarget(false) end
end)

RunService.RenderStepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = speedOn and FAST_SPEED or NORMAL_SPEED
    end
end)

createGUI()
setupESP()
notify("Script prêt","C=Speed | Q=Cible | 🎯 Mobile",player.UserId)
