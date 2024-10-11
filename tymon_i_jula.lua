--!native
--!optimize 2

--// Usługi \\--
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// Oczekiwanie na załadowanie \\--
if not game.IsLoaded then 
    game.Loaded:Wait() 
end
if Players.LocalPlayer.PlayerGui:FindFirstChild("LoadingUI") and Players.LocalPlayer.PlayerGui.LoadingUI.Enabled then
    repeat task.wait() until not Players.LocalPlayer.PlayerGui.LoadingUI.Enabled
end

--// Zmienne \\--
local Script = {
    Options = {
        "Nie krąż",            -- Opcja nie krążenia
        "ESP",                 -- Opcja ESP
        "FLY (don't work)"                  -- Opcja latania
    },
    Functions = {}
}

local playerGui = Players.LocalPlayer.PlayerGui
local mainUI = Instance.new("ScreenGui", playerGui)
local window = Instance.new("Frame", mainUI)

-- GUI Design
window.Size = UDim2.new(0.5, 0, 0.5, 0)
window.Position = UDim2.new(0.25, 0, 0.25, 0)
window.BackgroundColor3 = Color3.new(1, 1, 1)
window.BorderSizePixel = 0
window.Name = "MainWindow"

--// Biblioteka \\--
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/LinoriaLib/refs/heads/main/Library.lua"))()

local MainWindow = Library:CreateWindow({
    Title = "Kendzix | GUI",
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = MainWindow:AddTab("Main"), -- Tworzymy zakładkę "Main"
}

--// Funkcje \\--
function Script.Functions.Alert(message)
    Library:Notify(message, 5)
end

-- Funkcje do latania
local flying = false
local control = {F = 0, B = 0, L = 0, R = 0, U = 0, D = 0}
local speed = 50
local function fly()
    if flying then return end
    flying = true

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    local bodyGyro = Instance.new("BodyGyro")
    local bodyVelocity = Instance.new("BodyVelocity")

    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.Parent = rootPart

    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Parent = rootPart

    while flying do
        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
        bodyVelocity.Velocity = (workspace.CurrentCamera.CFrame.LookVector * control.F +
                                 workspace.CurrentCamera.CFrame.RightVector * control.R +
                                 Vector3.new(0, control.U - control.D, 0)) * speed
        RunService.RenderStepped:Wait()
    end

    bodyGyro:Destroy()
    bodyVelocity:Destroy()
end

local function stopFlying()
    flying = false
end

local function toggleFly()
    if flying then
        stopFlying()
    else
        fly()
    end
end

-- Funkcja do teleportacji gracza i latania wokół najbliższego gracza
local orbitRunning = false -- Flaga do śledzenia stanu
local function nieKraz()
    if orbitRunning then
        orbitRunning = false -- Wyłączamy krążenie
        return
    end
    
    orbitRunning = true -- Włączamy krążenie
    
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Znajdujemy najbliższego gracza
    local closestPlayer = nil
    local closestDistance = math.huge -- Ustawiamy początkowo jako bardzo dużą wartość
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local distance = (rootPart.Position - otherRoot.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = otherPlayer
                end
            end
        end
    end

    if closestPlayer and closestPlayer.Character then
        -- Teleportujemy się do najbliższego gracza
        local targetRoot = closestPlayer.Character:WaitForChild("HumanoidRootPart")
        rootPart.CFrame = targetRoot.CFrame * CFrame.new(5, 0, 0) -- Teleportacja obok gracza
        
        -- Latanie wokół gracza
        local radius = 5 -- Promień latania wokół gracza
        local angle = 0 -- Kąt startowy
        while orbitRunning do
            -- Obliczamy nową pozycję na podstawie kąta i promienia (tylko w poziomie X, Z)
            local x = math.cos(angle) * radius
            local z = math.sin(angle) * radius
            rootPart.CFrame = targetRoot.CFrame * CFrame.new(x, 5, z) -- Zachowujemy stałą wysokość
            
            angle = angle + math.rad(5) -- Zwiększamy kąt, aby "obracać się"
            wait(0.05) -- Odstęp między kolejnymi pozycjami
        end
    end
end

-- Funkcja do ESP
local espEnabled = false -- Flaga do śledzenia stanu ESP
local espObjects = {} -- Przechowuje referencje do ESP
local espUpdateInterval = 1 -- Czas w sekundach pomiędzy aktualizacjami ESP

local function updateESP()
    while espEnabled do
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= Players.LocalPlayer then
                if otherPlayer.Character then
                    local highlight = espObjects[otherPlayer.UserId]
                    if not highlight then
                        -- Tworzenie highlightu
                        highlight = Instance.new("Highlight") -- Tworzenie highlightu
                        highlight.Adornee = otherPlayer.Character
                        highlight.FillColor = Color3.new(1, 0, 0) -- Czerwony kolor highlightu
                        highlight.FillTransparency = 0.5 -- Przezroczystość
                        highlight.OutlineColor = Color3.new(0, 0, 0) -- Czarny kontur
                        highlight.OutlineTransparency = 0 -- Brak przezroczystości konturu
                        highlight.Parent = otherPlayer.Character
                        espObjects[otherPlayer.UserId] = highlight -- Dodanie highlightu do listy
                    end
                end
            end
        end
        wait(espUpdateInterval) -- Czekamy na kolejną aktualizację
    end

    -- Usunięcie wszystkich highlightów po wyłączeniu ESP
    for userId, highlight in pairs(espObjects) do
        if highlight then
            highlight:Destroy()
        end
    end
    espObjects = {} -- Resetowanie listy obiektów ESP
end

local function toggleESP()
    espEnabled = not espEnabled -- Zmiana stanu ESP

    if espEnabled then
        Script.Functions.Alert("ESP enabled!")
        spawn(updateESP) -- Uruchamiamy aktualizację ESP w osobnym wątku
    else
        Script.Functions.Alert("ESP disabled!")
    end
end

-- Sekcja Opisów
local OptionsGroup = Tabs.Main:AddLeftGroupbox("Options")
OptionsGroup:AddLabel("Available Options:")
OptionsGroup:AddButton("Nie krąż", function()
    nieKraz()
end)

OptionsGroup:AddButton("ESP", function()
    toggleESP() -- Przełączanie ESP
end)

OptionsGroup:AddButton("FLY", function()
    toggleFly() -- Przełączanie latania
end)

for _, option in ipairs(Script.Options) do
    -- Pomijamy "Nie krąż", "ESP" i "FLY", ponieważ już zostały dodane
    if option ~= "Nie krąż" and option ~= "ESP" and option ~= "FLY" then
        OptionsGroup:AddButton(option, function()
            Script.Functions.Alert(option .. " selected!")
            -- Tutaj dodaj funkcjonalność dla wybranej opcji
        end)
    end
end

-- Możliwość przeciągania GUI
local dragging = false
local dragInput
local dragStart
local startPos

window.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragInput = input
        dragStart = input.Position
        startPos = window.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

window.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Koniec skryptu
