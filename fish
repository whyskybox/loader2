--[[
    ╔═══════════════════════════════════════════════════════╗
    ║         AutoFish Premium v16 - Enhanced GUI           ║
    ║  Красивый интерфейс с анимациями и статистикой       ║
    ║  • Glassmorphism дизайн                               ║
    ║  • Живая статистика                                   ║
    ║  • Анимированные переходы                             ║
    ║  • Полная мобильная поддержка                         ║
    ╚═══════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local network = ReplicatedStorage:WaitForChild("Network")

local CAST_INDEX = 109
local REEL_INDEX = 110

local castEvent = network:GetChildren()[CAST_INDEX]
local reelEvent = network:GetChildren()[REEL_INDEX]

local debris = Workspace:WaitForChild("__DEBRIS")

local DEFAULT_CAST_CFRAME = CFrame.new(1572.0552978516, -21.633270263672, 326.69860839844, 1, 0, 0, 0, 1, 0, 0, 0, 1)

local SETTLE_Y_TOLERANCE = 0.05
local SETTLE_SPEED_LIMIT = 2.0
local BITE_Y_DELTA = 0.1
local BITE_OFFSET = 0.1
local CHECK_INTERVAL = 0.05
local MAX_WAIT_BOBBER = 4
local MAX_WAIT_BITE = 20

local autoFishing = false
local fishingCoroutine = nil

-- ===== СТАТИСТИКА =====
local statistics = {
    fishCaught = 0,
    startTime = 0,
    currentStatus = "Ready",
    sessionTime = 0
}

-- ===== ЦВЕТОВАЯ СХЕМА =====
local COLORS = {
    primary = Color3.fromRGB(138, 43, 226),      -- Фиолетовый
    primaryLight = Color3.fromRGB(186, 85, 211), -- Светлый фиолетовый
    secondary = Color3.fromRGB(30, 144, 255),    -- Синий
    success = Color3.fromRGB(50, 205, 50),       -- Зелёный
    warning = Color3.fromRGB(255, 165, 0),       -- Оранжевый
    danger = Color3.fromRGB(255, 71, 87),        -- Красный
    bg = Color3.fromRGB(15, 15, 20),             -- Тёмный фон
    surface = Color3.fromRGB(25, 25, 35),        -- Поверхность
    text = Color3.fromRGB(240, 240, 245),        -- Текст
    textDim = Color3.fromRGB(180, 180, 190)      -- Слабый текст
}

-- ===== ОПРЕДЕЛЕНИЕ ПЛАТФОРМЫ =====
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- ===== СОЗДАНИЕ GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFishPremiumGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false

-- ===== ГЛАВНОЕ ОКНО =====
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainWindow"
mainFrame.Size = isMobile and UDim2.new(0, 320, 0, 500) or UDim2.new(0, 360, 0, 580)
mainFrame.Position = UDim2.new(0, 15, 0, 15)
mainFrame.BackgroundColor3 = COLORS.bg
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.primary
mainStroke.Thickness = 2
mainStroke.Transparency = 0.7
mainStroke.Parent = mainFrame

-- ===== ГРАДИЕНТ ФОНА =====
local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COLORS.bg),
    ColorSequenceKeypoint.new(1, COLORS.surface)
})
bgGradient.Rotation = 45
bgGradient.Parent = mainFrame

-- ===== ЗАГОЛОВОК =====
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0, 70)
headerFrame.BackgroundColor3 = COLORS.surface
headerFrame.BackgroundTransparency = 0.5
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainFrame

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COLORS.primary),
    ColorSequenceKeypoint.new(1, COLORS.secondary)
})
headerGradient.Rotation = 90
headerGradient.Parent = headerFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 20)
headerCorner.Parent = headerFrame

-- Заголовочный текст
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -16, 0, 40)
titleText.Position = UDim2.new(0, 8, 0, 5)
titleText.BackgroundTransparency = 1
titleText.Text = "🎣 AutoFish Premium"
titleText.TextColor3 = COLORS.text
titleText.TextSize = 22
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = headerFrame

-- Версия
local versionText = Instance.new("TextLabel")
versionText.Size = UDim2.new(1, -16, 0, 20)
versionText.Position = UDim2.new(0, 8, 0, 45)
versionText.BackgroundTransparency = 1
versionText.Text = "v16 • Enhanced"
versionText.TextColor3 = COLORS.textDim
versionText.TextSize = 11
versionText.Font = Enum.Font.Gotham
versionText.TextXAlignment = Enum.TextXAlignment.Left
versionText.Parent = headerFrame

-- ===== СТАТИСТИКА КАРТОЧКА =====
local statsContainer = Instance.new("Frame")
statsContainer.Name = "Stats"
statsContainer.Size = UDim2.new(1, -16, 0, 90)
statsContainer.Position = UDim2.new(0, 8, 0, 80)
statsContainer.BackgroundColor3 = COLORS.surface
statsContainer.BackgroundTransparency = 0.4
statsContainer.BorderSizePixel = 0
statsContainer.Parent = mainFrame

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 12)
statsCorner.Parent = statsContainer

local statsStroke = Instance.new("UIStroke")
statsStroke.Color = COLORS.primaryLight
statsStroke.Thickness = 1
statsStroke.Transparency = 0.6
statsStroke.Parent = statsContainer

-- Раскладка статистики (2x2)
local statsList = Instance.new("UIGridLayout")
statsList.CellSize = UDim2.new(0.5, -4, 0, 40)
statsList.CellPadding = UDim2.new(0, 8, 0, 8)
statsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
statsList.VerticalAlignment = Enum.VerticalAlignment.Center
statsList.Parent = statsContainer

-- Функция создания статистики
local function createStatCard(parent, label, value)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = COLORS.surface
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    local label_text = Instance.new("TextLabel")
    label_text.BackgroundTransparency = 1
    label_text.Text = label
    label_text.TextColor3 = COLORS.textDim
    label_text.TextSize = 10
    label_text.Font = Enum.Font.Gotham
    label_text.Size = UDim2.new(1, -4, 0.5, 0)
    label_text.Position = UDim2.new(0, 2, 0, 0)
    label_text.Parent = card
    
    local value_text = Instance.new("TextLabel")
    value_text.BackgroundTransparency = 1
    value_text.Text = value or "0"
    value_text.TextColor3 = COLORS.primary
    value_text.TextSize = 18
    value_text.Font = Enum.Font.GothamBold
    value_text.Size = UDim2.new(1, -4, 0.5, 0)
    value_text.Position = UDim2.new(0, 2, 0.5, 0)
    value_text.Parent = card
    
    return value_text
end

local fishCounter = createStatCard(statsContainer, "Поймано рыб", "0")
local statusDisplay = createStatCard(statsContainer, "Статус", "Ready")
local timerDisplay = createStatCard(statsContainer, "Время сессии", "00:00")
local speedDisplay = createStatCard(statsContainer, "Скорость", "0/m")

-- ===== ГЛАВНАЯ КНОПКА =====
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, -16, 0, 60)
buttonContainer.Position = UDim2.new(0, 8, 0, 180)
buttonContainer.BackgroundTransparency = 1
buttonContainer.BorderSizePixel = 0
buttonContainer.Parent = mainFrame

local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(1, 0, 1, 0)
startButton.BackgroundColor3 = COLORS.success
startButton.TextColor3 = COLORS.text
startButton.Text = "▶ START FISHING"
startButton.TextSize = 18
startButton.Font = Enum.Font.GothamBold
startButton.BorderSizePixel = 0
startButton.AutoButtonColor = false
startButton.Parent = buttonContainer

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 14)
buttonCorner.Parent = startButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(255, 255, 255)
buttonStroke.Thickness = 2
buttonStroke.Transparency = 0.5
buttonStroke.Parent = startButton

-- ===== ПАНЕЛЬ СТАТУСА =====
local statusPanel = Instance.new("Frame")
statusPanel.Name = "StatusPanel"
statusPanel.Size = UDim2.new(1, -16, 0, 140)
statusPanel.Position = UDim2.new(0, 8, 0, 250)
statusPanel.BackgroundColor3 = COLORS.surface
statusPanel.BackgroundTransparency = 0.4
statusPanel.BorderSizePixel = 0
statusPanel.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 12)
statusCorner.Parent = statusPanel

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = COLORS.secondary
statusStroke.Thickness = 1
statusStroke.Transparency = 0.6
statusStroke.Parent = statusPanel

-- Иконка статуса (большой кружок с анимацией)
local statusIcon = Instance.new("Frame")
statusIcon.Name = "StatusIcon"
statusIcon.Size = UDim2.new(0, 50, 0, 50)
statusIcon.Position = UDim2.new(0, 15, 0, 12)
statusIcon.BackgroundColor3 = COLORS.warning
statusIcon.BorderSizePixel = 0
statusIcon.Parent = statusPanel

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = statusIcon

local statusTextLabel = Instance.new("TextLabel")
statusTextLabel.Name = "StatusText"
statusTextLabel.Size = UDim2.new(1, -75, 0, 60)
statusTextLabel.Position = UDim2.new(0, 70, 0, 8)
statusTextLabel.BackgroundTransparency = 1
statusTextLabel.Text = "🎣 Ready to start"
statusTextLabel.TextColor3 = COLORS.text
statusTextLabel.TextSize = 16
statusTextLabel.Font = Enum.Font.GothamBold
statusTextLabel.TextXAlignment = Enum.TextXAlignment.Left
statusTextLabel.TextWrapped = true
statusTextLabel.Parent = statusPanel

-- Детали статуса (маленький текст)
local detailsText = Instance.new("TextLabel")
detailsText.Name = "Details"
detailsText.Size = UDim2.new(1, -16, 0, 40)
detailsText.Position = UDim2.new(0, 8, 0, 75)
detailsText.BackgroundTransparency = 1
detailsText.Text = "Press START to begin fishing"
detailsText.TextColor3 = COLORS.textDim
detailsText.TextSize = 11
detailsText.Font = Enum.Font.Gotham
detailsText.TextXAlignment = Enum.TextXAlignment.Left
detailsText.TextWrapped = true
detailsText.Parent = statusPanel

-- ===== ПЕРЕКЛЮЧАТЕЛИ НАСТРОЕК =====
local settingsContainer = Instance.new("Frame")
settingsContainer.Name = "Settings"
settingsContainer.Size = UDim2.new(1, -16, 0, 90)
settingsContainer.Position = UDim2.new(0, 8, isMobile and 0.8 or 0.75)
settingsContainer.BackgroundColor3 = COLORS.surface
settingsContainer.BackgroundTransparency = 0.4
settingsContainer.BorderSizePixel = 0
settingsContainer.Parent = mainFrame

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 12)
settingsCorner.Parent = settingsContainer

-- Функция создания переключателя
local function createToggle(parent, label, y)
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(1, -16, 0, 28)
    toggle.Position = UDim2.new(0, 8, 0, y)
    toggle.BackgroundTransparency = 1
    toggle.BorderSizePixel = 0
    toggle.Parent = parent
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(0.7, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = label
    text.TextColor3 = COLORS.text
    text.TextSize = 13
    text.Font = Enum.Font.Gotham
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = toggle
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 20)
    btn.Position = UDim2.new(1, -50, 0.5, -10)
    btn.BackgroundColor3 = COLORS.danger
    btn.TextColor3 = COLORS.text
    btn.Text = "OFF"
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = toggle
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and COLORS.success or COLORS.danger
        btn.Text = state and "ON" or "OFF"
    end)
    
    return btn, state
end

createToggle(settingsContainer, "🔊 Sound Effects", 0)
createToggle(settingsContainer, "📊 Show Details", 30)
createToggle(settingsContainer, "🔁 Auto Restart", 60)

-- ===== ЛОГИКА ПЕРЕТАСКИВАНИЯ =====
local dragging = false
local dragStart = nil
local frameStart = nil

headerFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        frameStart = mainFrame.Position
    end
end)

headerFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                     input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
    end
end)

-- ===== АНИМАЦИЯ КНОПКИ =====
local function animateButton(button, scale)
    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(
        0.15,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    local tween = tweenService:Create(button, tweenInfo, {Size = UDim2.new(scale, 0, 1, 0)})
    tween:Play()
end

startButton.MouseEnter:Connect(function()
    startButton.BackgroundColor3 = COLORS.primaryLight
    animateButton(startButton, 1.05)
end)

startButton.MouseLeave:Connect(function()
    startButton.BackgroundColor3 = startButton.BackgroundColor3 == COLORS.success and COLORS.success or COLORS.danger
    animateButton(startButton, 1)
end)

-- ===== ОБНОВЛЕНИЕ СТАТУСА =====
local function updateStatus(msg, category)
    statusTextLabel.Text = msg
    detailsText.Text = os.date("%H:%M:%S") .. " • " .. (category or "Event")
    
    if msg:find("Reel") or msg:find("Reeling") or msg:find("caught") then
        statusIcon.BackgroundColor3 = COLORS.success
    elseif msg:find("Pool") or msg:find("Waiting") then
        statusIcon.BackgroundColor3 = COLORS.warning
    elseif msg:find("Error") then
        statusIcon.BackgroundColor3 = COLORS.danger
    elseif msg:find("Stopped") then
        statusIcon.BackgroundColor3 = COLORS.textDim
    else
        statusIcon.BackgroundColor3 = COLORS.secondary
    end
end

-- ===== ТАЙМЕР СЕССИИ =====
task.spawn(function()
    while true do
        if autoFishing and statistics.startTime > 0 then
            statistics.sessionTime = tick() - statistics.startTime
            local minutes = math.floor(statistics.sessionTime / 60)
            local seconds = math.floor(statistics.sessionTime % 60)
            timerDisplay.Text = string.format("%02d:%02d", minutes, seconds)
            
            -- Скорость (рыб в минуту)
            local rate = minutes > 0 and (statistics.fishCaught / minutes) or 0
            speedDisplay.Text = string.format("%.1f/m", rate)
        end
        task.wait(1)
    end
end)

-- ===== ОСНОВНАЯ ЛОГИКА РЫБАЛКИ =====
local function getCastTarget()
    local whirlpool = debris:FindFirstChild("DeepPoolWhirl")
    if whirlpool and whirlpool:IsA("BasePart") then
        return whirlpool.CFrame
    end
    return DEFAULT_CAST_CFRAME
end

local function waitForNewBobber(targetPos)
    local connection
    local foundBobber = nil
    local done = false

    connection = debris.ChildAdded:Connect(function(child)
        if done then return end
        if child.Name == "Bobber On Water" and child:IsA("BasePart") then
            if (child.CFrame.Position - targetPos).Magnitude < 0.5 then
                foundBobber = child
                done = true
            end
        end
    end)

    local waited = 0
    while not done and waited < MAX_WAIT_BOBBER and autoFishing do
        task.wait(0.1)
        waited = waited + 0.1
    end
    connection:Disconnect()
    return foundBobber
end

local function waitForWaterContact(bobber, waterY)
    if not bobber then return false end
    local t0 = tick()
    local prevY = bobber.CFrame.Position.Y
    while autoFishing and (tick() - t0) < 3 do
        if not bobber.Parent then return false end
        local curY = bobber.CFrame.Position.Y
        local speed = math.abs(curY - prevY) / CHECK_INTERVAL
        if math.abs(curY - waterY) < SETTLE_Y_TOLERANCE and speed < SETTLE_SPEED_LIMIT then
            return true
        end
        prevY = curY
        task.wait(CHECK_INTERVAL)
    end
    return false
end

local function fishingCycle()
    while autoFishing do
        local success, err = pcall(function()
            local castTarget = getCastTarget()
            local waterY = castTarget.Position.Y

            if castTarget == DEFAULT_CAST_CFRAME then
                updateStatus("🎣 Casting to default spot", "Casting")
            else
                updateStatus("🌀 Casting to whirlpool", "Casting")
            end

            castEvent:InvokeServer(castTarget)

            local bobber = waitForNewBobber(castTarget.Position)
            if not bobber then
                updateStatus("❌ Bobber not found", "Error")
                task.wait(0.5)
                return
            end

            updateStatus("⏳ Waiting for water contact", "Settling")
            if not waitForWaterContact(bobber, waterY) then
                updateStatus("❌ Water contact failed", "Error")
                task.wait(0.5)
                return
            end

            updateStatus("🎣 Waiting for a bite...", "Waiting")
            local initialPos = bobber.CFrame.Position
            local biteDetected = false
            local startWait = tick()

            while bobber and bobber.Parent == debris and autoFishing do
                if not bobber:IsDescendantOf(debris) then break end
                local curPos = bobber.CFrame.Position
                local verticalDrop = initialPos.Y - curPos.Y
                local offset = (curPos - initialPos).Magnitude

                if verticalDrop >= BITE_Y_DELTA or offset >= BITE_OFFSET then
                    biteDetected = true
                    break
                end

                if tick() - startWait > MAX_WAIT_BITE then
                    updateStatus("⏱️ No bite - Recasting", "Timeout")
                    break
                end
                task.wait(CHECK_INTERVAL)
            end

            if not autoFishing then return end

            if biteDetected then
                updateStatus("⚡ FISH BITING! REELING!", "Reeling")
                reelEvent:InvokeServer()
                statistics.fishCaught = statistics.fishCaught + 1
                fishCounter.Text = tostring(statistics.fishCaught)
                task.wait(0.3)
                updateStatus("✅ Fish caught! " .. statistics.fishCaught, "Success")
                task.wait(0.1)
            else
                updateStatus("🔄 Recasting", "Retry")
            end

            task.wait(0)
        end)

        if not success then
            updateStatus("⚠️ ERROR: Script error", "Error")
            task.wait(1)
        end
    end
    updateStatus("⏹ Fishing stopped", "Stopped")
end

-- ===== ОБРАБОТЧИК КНОПКИ START/STOP =====
startButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        
        autoFishing = not autoFishing
        if autoFishing then
            startButton.BackgroundColor3 = COLORS.danger
            startButton.Text = "⏹ STOP FISHING"
            statistics.startTime = tick()
            updateStatus("🟢 FISHING ACTIVE", "Started")
            fishingCoroutine = coroutine.wrap(fishingCycle)
            fishingCoroutine()
        else
            startButton.BackgroundColor3 = COLORS.success
            startButton.Text = "▶ START FISHING"
            autoFishing = false
            updateStatus("⏸ Fishing paused", "Paused")
        end
    end
end)

-- ===== ПУЛЬСИРУЮЩАЯ АНИМАЦИЯ ИКОНКИ =====
task.spawn(function()
    while true do
        if autoFishing then
            local tweenService = game:GetService("TweenService")
            local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            local tween = tweenService:Create(statusIcon, tweenInfo, {BackgroundTransparency = 0.3})
            tween:Play()
            tween.Completed:Wait()
            
            local tweenInfo2 = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            local tween2 = tweenService:Create(statusIcon, tweenInfo2, {BackgroundTransparency = 0})
            tween2:Play()
            tween2.Completed:Wait()
        else
            task.wait(0.5)
        end
    end
end)

print("✅ AutoFish Premium v16 loaded!")
print("🎨 Enhanced GUI with statistics and animations")
