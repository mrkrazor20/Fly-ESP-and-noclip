--[[
    Project: Roblox Mod Menu (Fly, Noclip, ESP, Speed)
    Environment: Roblox Studio / Client LocalScript
]]

local frame = script.Parent
local lp = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local players = game:GetService("Players")

-- Стани
local flyActive = false
local noclipActive = false
local espActive = false
local flySpeed = 50

-- Фізика польоту
local bodyVel = Instance.new("BodyVelocity")
bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)

-- Зберігання ESP підсвіток
local highlights = {}

-- Безпечне підключення кнопок
local function safeConnect(btnName, callback)
	local btn = frame:FindFirstChild(btnName)
	if btn then
		btn.MouseButton1Click:Connect(callback)
	end
end

safeConnect("FlyButton", function() flyActive = not flyActive end)
safeConnect("NoclipButton", function() noclipActive = not noclipActive end)
safeConnect("EspButton", function() 
	espActive = not espActive 
	if not espActive then
		for _, h in pairs(highlights) do
			if h then h:Destroy() end
		end
		highlights = {}
	end
end)
safeConnect("SpeedUp", function() flySpeed = math.min(flySpeed + 25, 300) end)
safeConnect("SpeedDown", function() flySpeed = math.max(flySpeed - 25, 25) end)

-- Перетягування меню мишкою
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)
uis.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
uis.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Головний цикл обробки
runService.RenderStepped:Connect(function()
	local char = lp.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera

	-- 1. Флай (WASD + Space / LeftShift)
	if flyActive and hrp then
		bodyVel.Parent = hrp
		bodyGyro.Parent = hrp
		bodyGyro.CFrame = cam.CFrame
		
		local moveDir = Vector3.new()
		if uis:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
		if uis:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
		if uis:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
		if uis:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
		if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
		if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0, 1, 0) end
		
		bodyVel.Velocity = moveDir * flySpeed
	else
		bodyVel.Parent = nil
		bodyGyro.Parent = nil
	end

	-- 2. Noclip
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not noclipActive
		end
	end

	-- 3. ESP
	if espActive then
		for _, player in pairs(players:GetPlayers()) do
			if player ~= lp and player.Character then
				local pChar = player.Character
				if not highlights[player] or highlights[player].Parent ~= pChar then
					if highlights[player] then highlights[player]:Destroy() end
					local hl = Instance.new("Highlight")
					hl.Adornee = pChar
					hl.FillColor = Color3.fromRGB(255, 0, 0)
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.Parent = pChar
					highlights[player] = hl
				end
			end
		end
	end
end)
