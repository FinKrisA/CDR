-- ═══ INKASATOR AUTOFARM ═══
-- Autofarm collecte d'argent (Mobile friendly)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local farming = false
local loopCount = 0
-- ═══ REFERENCES ═══
local inkUtils = workspace:WaitForChild("Utilities"):WaitForChild("Inkasator")
local zapravka2 = inkUtils:WaitForChild("StartPoints"):WaitForChild("Zapravka2")
local endBase = inkUtils:WaitForChild("EndPoints"):WaitForChild("Base")
-- ═══ FONCTIONS ═══
local function getCar()
	local cars = workspace:FindFirstChild("Cars")
	if not cars then return nil end
	return cars:FindFirstChild(LocalPlayer.Name .. "sCar")
end
local function waitForCar(timeout)
	local t = 0
	while t < (timeout or 8) do
		local car = getCar()
		if car and car:FindFirstChild("DriveSeat") then return car end
		task.wait(0.3)
		t = t + 0.3
	end
	return getCar()
end
local function sitInDriveSeat()
	local car = getCar()
	if not car then return false end
	local seat = car:FindFirstChild("DriveSeat")
	if not seat then return false end
	local char = LocalPlayer.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	if hum.SeatPart == seat then return true end
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
	end
	task.wait(0.2)
	seat:Sit(hum)
	task.wait(0.5)
	return hum.SeatPart == seat
end
-- ═══ TELEPORTATION ANTI-FLIP ═══
local function teleportCar(targetCF)
	local car = getCar()
	if not car then return false end
	local seat = car:FindFirstChild("DriveSeat")
	if not seat then return false end
	car.PrimaryPart = seat
	local parts = {}
	for _, p in ipairs(car:GetDescendants()) do
		if p:IsA("BasePart") then
			table.insert(parts, {Part = p, WasAnchored = p.Anchored})
		end
	end
	local targetPos = targetCF.Position
	local _, targetYRot, _ = targetCF:ToEulerAnglesYXZ()
	local uprightCF = CFrame.new(targetPos) * CFrame.Angles(0, targetYRot, 0)
	for _, data in ipairs(parts) do
		pcall(function()
			data.Part.AssemblyLinearVelocity = Vector3.zero
			data.Part.AssemblyAngularVelocity = Vector3.zero
			data.Part.Velocity = Vector3.zero
			data.Part.RotVelocity = Vector3.zero
		end)
	end
	for _, data in ipairs(parts) do
		pcall(function()
			data.Part.Anchored = true
		end)
	end
	task.wait(0.05)
	for i = 1, 8 do
		pcall(function()
			car:PivotTo(uprightCF)
		end)
		task.wait()
	end
	task.wait(0.2)
	for _, data in ipairs(parts) do
		pcall(function()
			data.Part.AssemblyLinearVelocity = Vector3.zero
			data.Part.AssemblyAngularVelocity = Vector3.zero
			data.Part.Velocity = Vector3.zero
			data.Part.RotVelocity = Vector3.zero
		end)
	end
	for _, data in ipairs(parts) do
		pcall(function()
			data.Part.Anchored = data.WasAnchored
		end)
	end
	task.spawn(function()
		for i = 1, 10 do
			pcall(function()
				seat.AssemblyLinearVelocity = Vector3.zero
				seat.AssemblyAngularVelocity = Vector3.zero
				seat.Velocity = Vector3.zero
				seat.RotVelocity = Vector3.zero
				car:PivotTo(uprightCF)
			end)
			task.wait()
		end
	end)
	task.wait(0.3)
	return true
end
-- ═══ FIRE PROMPT ═══
local function findAndFirePrompt(targetPart)
	local function searchIn(parent)
		if not parent then return false end
		for _, desc in ipairs(parent:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				pcall(function() fireproximityprompt(desc) end)
				return true
			end
		end
		local p = parent:FindFirstChildOfClass("ProximityPrompt")
		if p then
			pcall(function() fireproximityprompt(p) end)
			return true
		end
		return false
	end
	if searchIn(targetPart) then return true end
	if searchIn(targetPart.Parent) then return true end
	if searchIn(inkUtils) then return true end
	local car = getCar()
	if car and searchIn(car) then return true end
	local pos = targetPart.Position
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			local p = desc.Parent
			if p and p:IsA("BasePart") and (p.Position - pos).Magnitude < 50 then
				pcall(function() fireproximityprompt(desc) end)
				return true
			end
		end
	end
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ClickDetector") then
			local p = desc.Parent
			if p and p:IsA("BasePart") and (p.Position - pos).Magnitude < 50 then
				pcall(function() fireclickdetector(desc) end)
				return true
			end
		end
	end
	return false
end
local function firePromptRetry(targetPart, retries)
	retries = retries or 8
	for i = 1, retries do
		if findAndFirePrompt(targetPart) then return true end
		task.wait(0.3)
	end
	return false
end
local function startRoute()
	pcall(function()
		ReplicatedStorage:WaitForChild("InkasatorEvents"):WaitForChild("Trucker"):FireServer("startroute", "2")
	end)
end
-- ═══ GUI MOBILE ═══
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InkasatorAutofarm"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 170, 0, 105)
Main.Position = UDim2.new(0, 8, 0.35, 0)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1, 0, 0, 20)
TBar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
TBar.BorderSizePixel = 0
TBar.Parent = Main
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 8)
local TTitle = Instance.new("TextLabel")
TTitle.Size = UDim2.new(1, -42, 1, 0)
TTitle.Position = UDim2.new(0, 6, 0, 0)
TTitle.BackgroundTransparency = 1
TTitle.Text = "💰 Inkasator Farm"
TTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
TTitle.TextSize = 10
TTitle.Font = Enum.Font.GothamBold
TTitle.TextXAlignment = Enum.TextXAlignment.Left
TTitle.Parent = TBar
local minimized = false
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 16, 0, 16)
MinBtn.Position = UDim2.new(1, -38, 0, 2)
MinBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 40)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
MinBtn.TextSize = 12
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 16, 0, 16)
CloseBtn.Position = UDim2.new(1, -19, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 9
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -20)
Content.Position = UDim2.new(0, 0, 0, 20)
Content.BackgroundTransparency = 1
Content.Parent = Main
MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	Content.Visible = not minimized
	Main.Size = minimized and UDim2.new(0, 170, 0, 20) or UDim2.new(0, 170, 0, 105)
	MinBtn.Text = minimized and "+" or "-"
end)
CloseBtn.MouseButton1Click:Connect(function()
	farming = false
	ScreenGui:Destroy()
end)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -10, 0, 26)
ToggleBtn.Position = UDim2.new(0, 5, 0, 3)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 170, 35)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "▶ START"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 12
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = Content
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, -10, 0, 14)
StatusLbl.Position = UDim2.new(0, 5, 0, 33)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "⏸ Prêt"
StatusLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLbl.TextSize = 9
StatusLbl.Font = Enum.Font.GothamMedium
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.TextTruncate = Enum.TextTruncate.AtEnd
StatusLbl.Parent = Content
local StepLbl = Instance.new("TextLabel")
StepLbl.Size = UDim2.new(1, -10, 0, 14)
StepLbl.Position = UDim2.new(0, 5, 0, 48)
StepLbl.BackgroundTransparency = 1
StepLbl.Text = ""
StepLbl.TextColor3 = Color3.fromRGB(130, 130, 130)
StepLbl.TextSize = 8
StepLbl.Font = Enum.Font.GothamMedium
StepLbl.TextXAlignment = Enum.TextXAlignment.Left
StepLbl.TextTruncate = Enum.TextTruncate.AtEnd
StepLbl.Parent = Content
local CountLbl = Instance.new("TextLabel")
CountLbl.Size = UDim2.new(1, -10, 0, 14)
CountLbl.Position = UDim2.new(0, 5, 0, 63)
CountLbl.BackgroundTransparency = 1
CountLbl.Text = "🔄 Boucles: 0"
CountLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
CountLbl.TextSize = 9
CountLbl.Font = Enum.Font.GothamMedium
CountLbl.TextXAlignment = Enum.TextXAlignment.Left
CountLbl.Parent = Content
local function setStatus(txt, col)
	StatusLbl.Text = txt
	StatusLbl.TextColor3 = col or Color3.fromRGB(180, 180, 180)
end
local function setStep(txt)
	StepLbl.Text = txt
end
-- ═══ BOUCLE PRINCIPALE ═══
local function farmLoop()
	while farming do
		-- 1 : Démarrer la route
		setStatus("🔄 Démarrage route...", Color3.fromRGB(255, 200, 0))
		setStep("[1/7] FireServer startroute 2")
		startRoute()
		task.wait(1.5)
		if not farming then break end
		-- 2 : Attendre la voiture
		setStatus("⏳ Attente voiture...", Color3.fromRGB(255, 200, 0))
		setStep("[2/7] Recherche voiture...")
		local car = waitForCar(8)
		if not car then
			setStatus("❌ Voiture introuvable !", Color3.fromRGB(255, 50, 50))
			setStep("Retry dans 2s...")
			task.wait(2)
			continue
		end
		if not farming then break end
		-- 3 : Monter dans la voiture
		setStatus("🪑 Montée voiture...", Color3.fromRGB(255, 200, 0))
		setStep("[3/7] Sit DriveSeat")
		sitInDriveSeat()
		task.wait(0.5)
		if not farming then break end
		-- 4 : TP au point de chargement (Zapravka2)
		setStatus("📍 TP → Chargement...", Color3.fromRGB(100, 180, 255))
		setStep("[4/7] TP Zapravka2")
		local zapCF = zapravka2.CFrame * CFrame.new(0, 5, 0)
		if not teleportCar(zapCF) then
			setStatus("❌ Échec TP chargement", Color3.fromRGB(255, 50, 50))
			task.wait(1)
			continue
		end
		task.wait(0.5)
		if not farming then break end
		-- 5 : Récupérer l'argent + attente 4s
		setStatus("💵 Récupérer argent...", Color3.fromRGB(100, 255, 100))
		setStep("[5/7] Prompt Zapravka2")
		firePromptRetry(zapravka2, 8)
		for i = 4, 1, -1 do
			if not farming then break end
			setStatus("⏳ Chargement... " .. i .. "s", Color3.fromRGB(255, 255, 100))
			setStep("[5/7] Récupération argent")
			task.wait(1)
		end
		if not farming then break end
		-- 6 : TP au point de dépôt (EndPoints.Base)
		setStatus("📍 TP → Dépôt...", Color3.fromRGB(100, 180, 255))
		setStep("[6/7] TP EndPoints Base")
		local endCF = endBase.CFrame * CFrame.new(0, 5, 0)
		if not teleportCar(endCF) then
			setStatus("❌ Échec TP dépôt", Color3.fromRGB(255, 50, 50))
			task.wait(1)
			continue
		end
		task.wait(0.5)
		if not farming then break end
		-- 7 : Interagir (déposer l'argent)
		setStatus("🏦 Interagir...", Color3.fromRGB(100, 255, 100))
		setStep("[7/7] Prompt Base")
		firePromptRetry(endBase, 8)
		task.wait(0.5)
		-- Boucle terminée
		loopCount = loopCount + 1
		CountLbl.Text = "🔄 Boucles: " .. loopCount
		setStatus("✅ Boucle " .. loopCount .. " OK!", Color3.fromRGB(0, 255, 100))
		setStep("Redémarrage...")
		task.wait(1)
	end
	setStatus("⏸ Arrêté", Color3.fromRGB(180, 180, 180))
	setStep("")
end
-- ═══ RADAR ANTI-DÉTECTION ═══
-- Placé APRÈS farmLoop pour éviter toute référence nil
local RADAR_RADIUS = 80
local isHiding = false
local carSavedCFrame = nil
local radarActive = false

RunService.Heartbeat:Connect(function()
	-- Le radar ne tourne que si le farming est actif OU si la voiture est cachée
	if not farming and not isHiding then return end
	-- Ne pas lancer plusieurs checks en parallèle
	if radarActive then return end

	local car = getCar()
	if not car then return end
	local seat = car:FindFirstChild("DriveSeat")
	if not seat then return end

	local carPos = seat.Position
	local playerDetected = false

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					if (carPos - root.Position).Magnitude <= RADAR_RADIUS then
						playerDetected = true
						break
					end
				end
			end
		end
	end

	-- Joueur détecté → cacher la voiture + stop farm
	if playerDetected and not isHiding then
		isHiding = true
		farming = false
		carSavedCFrame = seat.CFrame
		radarActive = true
		task.spawn(function()
			setStatus("🚨 Joueur détecté ! Cache...", Color3.fromRGB(255, 80, 0))
			setStep("⏸ Autofarm suspendu")
			ToggleBtn.Text = "▶ START"
			ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 170, 35)
			teleportCar(CFrame.new(carSavedCFrame.Position.X, -40, carSavedCFrame.Position.Z))
			radarActive = false
		end)

	-- Plus de joueur → ramener la voiture + reprendre farm
	elseif not playerDetected and isHiding then
		isHiding = false
		radarActive = true
		task.spawn(function()
			setStatus("✅ Zone libre ! Reprise...", Color3.fromRGB(0, 220, 100))
			setStep("▶ Reprise autofarm...")
			if carSavedCFrame then
				teleportCar(carSavedCFrame)
				carSavedCFrame = nil
			end
			task.wait(0.5)
			farming = true
			ToggleBtn.Text = "⏹ STOP"
			ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			task.spawn(farmLoop)
			radarActive = false
		end)
	end
end)
-- ═══ FIN RADAR ═══
ToggleBtn.MouseButton1Click:Connect(function()
	farming = not farming
	if farming then
		ToggleBtn.Text = "⏹ STOP"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		task.spawn(farmLoop)
	else
		ToggleBtn.Text = "▶ START"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 170, 35)
	end
end)
LocalPlayer.CharacterAdded:Connect(function()
	if farming then
		task.wait(2)
		if farming then
			sitInDriveSeat()
		end
	end
end)
setStatus("⏸ Prêt", Color3.fromRGB(180, 180, 180))
