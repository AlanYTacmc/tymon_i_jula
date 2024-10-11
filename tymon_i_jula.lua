-- Tworzymy ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") -- Dodajemy GUI do gracza

-- Tworzymy Frame dla początkowego menu (autoryzacja)
local authFrame = Instance.new("Frame")
authFrame.Size = UDim2.new(0, 300, 0, 150) -- Rozmiar ramki
authFrame.Position = UDim2.new(0.5, -150, 0.5, -75) -- Pozycja (na środku ekranu)
authFrame.BackgroundColor3 = Color3.new(0, 0, 0.1) -- Niebiesko-czarny kolor tła
authFrame.Parent = screenGui -- Dodajemy Frame do GUI

-- Tworzymy dynamiczny efekt RGB dla tekstu
local function dynamicRGB(element)
    local hue = 0 -- Wartość hue, która zmienia się, aby uzyskać efekt kolorystyczny
    while element.Parent do
        hue = hue + 0.01
        if hue > 1 then
            hue = 0
        end
        element.TextColor3 = Color3.fromHSV(hue, 1, 1) -- Zmieniamy kolor tekstu
        wait(0.05) -- Opóźnienie między zmianami kolorów
    end
end

-- Funkcja do przesuwania GUI
local function makeDraggable(frame)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    -- Funkcja uruchamiana po kliknięciu na ramkę
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    -- Rozpoczynamy przeciąganie
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    -- Kontynuujemy przeciąganie
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    -- Aktualizujemy pozycję ramki podczas przeciągania
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)
end

-- Funkcja do teleportacji gracza i latania wokół najbliższego gracza
local orbitRunning = false -- Flaga do śledzenia stanu
local function teleportAndOrbit()
    if orbitRunning then
        orbitRunning = false -- Wyłączamy krążenie
        return
    end
    
    orbitRunning = true -- Włączamy krążenie
    
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Znajdujemy najbliższego gracza
    local closestPlayer = nil
    local closestDistance = math.huge -- Ustawiamy początkowo jako bardzo dużą wartość
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
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

-- Tworzymy pole tekstowe (TextBox) do wpisywania tekstu
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0, 200, 0, 50) -- Rozmiar pola tekstowego
inputBox.Position = UDim2.new(0.5, -100, 0.3, -25) -- Pozycja pola tekstowego (w środku ramki)
inputBox.Text = "Wpisz KOD" -- Domyślny tekst
inputBox.TextColor3 = Color3.new(1, 1, 1) -- Kolor tekstu (biały)
inputBox.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2) -- Tło pola tekstowego (ciemnoszare)
inputBox.Font = Enum.Font.GothamBold -- Ustawiamy czcionkę
inputBox.Parent = authFrame -- Dodajemy pole tekstowe do ramki

-- Tworzymy przycisk do sprawdzenia tekstu
local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(0, 200, 0, 50) -- Rozmiar przycisku
submitButton.Position = UDim2.new(0.5, -100, 0.7, -25) -- Pozycja przycisku (na dole ramki)
submitButton.BackgroundColor3 = Color3.new(0, 0, 0.4) -- Kolor przycisku (ciemnoniebieski)
submitButton.Text = "Sprawdz Kod" -- Tekst na przycisku
submitButton.TextColor3 = Color3.new(1, 1, 1) -- Kolor tekstu (biały)
submitButton.Font = Enum.Font.GothamBold -- Czcionka GothamBold
submitButton.Parent = authFrame -- Dodajemy przycisk do ramki
spawn(function() dynamicRGB(submitButton) end) -- Dynamiczny efekt RGB dla przycisku

-- Tworzymy tekst do wyświetlania komunikatu (początkowo niewidoczny)
local successLabel = Instance.new("TextLabel")
successLabel.Size = UDim2.new(0, 300, 0, 100) -- Rozmiar tekstu
successLabel.Position = UDim2.new(0.5, -150, 0.4, -50) -- Wyświetlany na środku ekranu
successLabel.Text = "Successfully accessed" -- Tekst komunikatu
successLabel.TextColor3 = Color3.new(0, 1, 0) -- Zielony kolor tekstu
successLabel.BackgroundTransparency = 1 -- Przezroczyste tło
successLabel.Font = Enum.Font.GothamBold -- Czcionka GothamBold
successLabel.TextScaled = true -- Automatyczne skalowanie tekstu
successLabel.Visible = false -- Na start ukryty
successLabel.Parent = screenGui
spawn(function() dynamicRGB(successLabel) end) -- Dynamiczny efekt RGB dla komunikatu

-- Działanie po kliknięciu przycisku
submitButton.MouseButton1Click:Connect(function()
    local enteredText = inputBox.Text -- Pobieramy tekst wpisany w TextBox
    if enteredText == "TYMON_I_JULA" then
        -- Wyświetlamy komunikat na ekranie
        successLabel.Visible = true
        wait(2) -- Czekamy 2 sekundy
        successLabel.Visible = false -- Ukrywamy komunikat
        authFrame:Destroy() -- Usuwamy GUI autoryzacji
        
        -- Tworzymy nowe GUI z highlightami i przyciskiem do teleportacji
        local highlightFrame = Instance.new("Frame")
        highlightFrame.Size = UDim2.new(0, 300, 0, 150)
        highlightFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
        highlightFrame.BackgroundColor3 = Color3.new(0, 0, 0.1)
        highlightFrame.Parent = screenGui

        -- Przycisk do pokazywania/wyłączania highlightów
        local highlightButton = Instance.new("TextButton")
        highlightButton.Size = UDim2.new(0, 200, 0, 50)
        highlightButton.Position = UDim2.new(0.5, -100, 0.2, -25)
        highlightButton.BackgroundColor3 = Color3.new(0, 0, 0.4)
        highlightButton.Text = "Włącz espa i nie pierdol"
        highlightButton.TextColor3 = Color3.new(1, 1, 1)
        highlightButton.Font = Enum.Font.GothamBold
        highlightButton.Parent = highlightFrame
        spawn(function() dynamicRGB(highlightButton) end)

        local highlightEnabled = false -- Flaga do śledzenia stanu highlightów

        highlightButton.MouseButton1Click:Connect(function()
            highlightEnabled = not highlightEnabled -- Przełączamy stan highlightów
            for _, player in pairs(game.Players:GetPlayers()) do
                if player.Character then
                    local highlight = player.Character:FindFirstChild("Highlight")
                    if highlightEnabled then
                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.FillColor = Color3.fromRGB(255, 0, 0)
                            highlight.OutlineTransparency = 0
                            highlight.Parent = player.Character
                        end
                    else
                        if highlight then
                            highlight:Destroy()
                        end
                    end
                end
            end
        end)

        -- Przycisk do teleportacji i krążenia
        local orbitButton = Instance.new("TextButton")
        orbitButton.Size = UDim2.new(0, 200, 0, 50)
        orbitButton.Position = UDim2.new(0.5, -100, 0.6, -25)
        orbitButton.BackgroundColor3 = Color3.new(0, 0, 0.4)
        orbitButton.Text = "Nie krąż"
        orbitButton.TextColor3 = Color3.new(1, 1, 1)
        orbitButton.Font = Enum.Font.GothamBold
        orbitButton.Parent = highlightFrame
        spawn(function() dynamicRGB(orbitButton) end)

        orbitButton.MouseButton1Click:Connect(function()
            teleportAndOrbit()
        end)
        
        makeDraggable(highlightFrame) -- Możliwość przeciągania nowego okna
    end
end)

-- Dodajemy funkcjonalność przesuwania dla GUI
makeDraggable(authFrame)
