-- HungDao9999 | Bay Thẳng + Xuyên Tường + Instant Pickup (2 NÚT: ĐI/VỀ)
-- FIXED: Reset 100% trạng thái sau khi bay xong
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ====== CONFIG ======
local SPEED = 500
local POINTS_GO = {
	Vector3.new(147, 3.38, -138),
	Vector3.new(2588, -0.43, -138.4),
	Vector3.new(2588.35, -0.43, -100.66)
}
local POINTS_BACK = {
	Vector3.new(2588.35, -0.43, -100.66),
	Vector3.new(2588, -0.43, -138.4),
	Vector3.new(147, 3.38, -138)
}
local arrivalThreshold = 5

-- ====== STATE ======
local ENABLED = false
local flyConn, noclipConn, promptConn

-- ====== CHARACTER ======
local function getChar()
	local c = player.Character or player.CharacterAdded:Wait()
	return c, c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
end

-- ====== NOCLIP LIÊN TỤC ======
local function enableNoclip(char)
	if noclipConn then noclipConn:Disconnect() end
	noclipConn = RunService.Stepped:Connect(function()
		if not ENABLED then return end
		for _, v in pairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				v.Massless = true
			end
		end
	end)
end

local function disableNoclip(char)
	if noclipConn then 
		noclipConn:Disconnect() 
		noclipConn = nil
	end
	-- Khôi phục collision cho tất cả parts
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Name == "HumanoidRootPart" then
				v.CanCollide = false
			else
				v.CanCollide = true
			end
			v.Massless = false
		end
	end
end

-- ====== BAY THẲNG BẰNG CFRAME ======
local function flyDirectTo(hrp, targetPos)
	if not hrp or not hrp.Parent or not ENABLED then
		return false
	end
	
	print("🎯 Flying to: " .. tostring(targetPos))
	
	local startTime = tick()
	local timeout = 120
	local completed = false
	
	if flyConn then flyConn:Disconnect() end
	
	flyConn = RunService.Heartbeat:Connect(function(dt)
		if not ENABLED or not hrp or not hrp.Parent then
			completed = false
			if flyConn then flyConn:Disconnect() end
			return
		end
		
		local currentPos = hrp.Position
		local direction = (targetPos - currentPos).Unit
		local distance = (targetPos - currentPos).Magnitude
		
		if distance <= arrivalThreshold then
			hrp.CFrame = CFrame.new(targetPos)
			completed = true
			if flyConn then flyConn:Disconnect() end
			return
		end
		
		if tick() - startTime > timeout then
			completed = false
			if flyConn then flyConn:Disconnect() end
			return
		end
		
		local moveDistance = math.min(SPEED * dt, distance)
		local newPos = currentPos + (direction * moveDistance)
		hrp.CFrame = CFrame.new(newPos)
	end)
	
	while not completed and ENABLED do
		if tick() - startTime > timeout then
			if flyConn then flyConn:Disconnect() end
			return false
		end
		task.wait()
	end
	
	return completed
end

-- ====== INSTANT PICKUP (TỰ ĐỘNG ẤN E) ======
local function enableInstantPickup()
	if promptConn then promptConn:Disconnect() end
	promptConn = ProximityPromptService.PromptShown:Connect(function(p)
		if not ENABLED then return end
		p.HoldDuration = 0
		task.wait()
		pcall(function()
			fireproximityprompt(p)
		end)
	end)
end

local function disableInstantPickup()
	if promptConn then 
		promptConn:Disconnect() 
		promptConn = nil
	end
end

-- ====== RESET HOÀN TOÀN TRẠNG THÁI (FIXED) ======
local function fullReset()
	print("🔄 Bắt đầu reset hoàn toàn...")
	
	ENABLED = false
	
	-- Ngắt tất cả connections
	if flyConn then 
		flyConn:Disconnect() 
		flyConn = nil
	end
	
	local success, char, hrp, hum = pcall(getChar)
	if not success or not char then 
		print("⚠️ Không tìm thấy character")
		return 
	end
	
	-- 1. TẮT NOCLIP NGAY LẬP TỨC
	disableNoclip(char)
	print("✅ Đã tắt noclip")
	
	-- 2. KHÔI PHỤC GRAVITY
	workspace.Gravity = 196.2
	
	-- 3. RESET HOÀN TOÀN HUMANOID
	if hum then
		hum.PlatformStand = false
		hum.Sit = false
		hum.AutoRotate = true
		
		-- Force về trạng thái đứng bình thường
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait(0.1)
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	
	-- 4. RESET VẬT LÝ HRP
	if hrp then
		hrp.Anchored = false
		hrp.Velocity = Vector3.new(0, 0, 0)
		hrp.RotVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end
	
	-- 5. RESET TẤT CẢ PARTS TRONG CHARACTER
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Velocity = Vector3.new(0, 0, 0)
			v.RotVelocity = Vector3.new(0, 0, 0)
			v.Anchored = false
			v.Massless = false
			
			if v.Name ~= "HumanoidRootPart" then
				v.CanCollide = true
			end
		end
	end
	
	-- 6. ĐỢI CHẠM ĐẤT
	local touchedGround = false
	local startWait = tick()
	repeat
		task.wait(0.1)
		if hum and hum.FloorMaterial ~= Enum.Material.Air then
			touchedGround = true
		end
	until touchedGround or tick() - startWait > 5
	
	-- 7. FORCE JUMP RỒI LANDING (để reset physics hoàn toàn)
	if hum and touchedGround then
		task.wait(0.2)
		hum.Jump = true
		task.wait(0.3)
		
		-- Đợi hạ xuống lại
		local landed = false
		local jumpWait = tick()
		repeat
			task.wait(0.1)
			if hum.FloorMaterial ~= Enum.Material.Air then
				landed = true
			end
		until landed or tick() - jumpWait > 3
	end
	
	-- 8. FINAL RESET
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait(0.1)
	end
	
	disableInstantPickup()
	
	print("✅ HOÀN TẤT RESET 100% - Có thể di chuyển bình thường")
end

-- ====== STOP & CLEANUP ======
local function stopAndCleanup()
	fullReset()
end

-- ====== MAIN LOGIC ======
local function run(points, direction)
	local char, hrp, hum = getChar()
	
	enableNoclip(char)
	enableInstantPickup()
	
	workspace.Gravity = 0
	hum:ChangeState(Enum.HumanoidStateType.Physics)
	
	print("🚀 Bắt đầu bay " .. direction .. "...")
	
	for i, pos in ipairs(points) do
		if not ENABLED then break end
		
		print("=== Điểm " .. i .. "/" .. #points .. " ===")
		local success = flyDirectTo(hrp, pos)
		
		if not success then
			print("❌ Thất bại tại điểm " .. i)
			fullReset()
			return
		end
		
		print("✅ Đã đến điểm " .. i)
		task.wait(0.3)
	end
	
	if ENABLED then
		print("✅ Hoàn thành bay " .. direction .. "!")
		
		-- RESET HOÀN TOÀN SAU KHI BAY XONG
		fullReset()
	end
end

-- ====== GUI 2 NÚT ======
local gui = Instance.new("ScreenGui", PlayerGui)
gui.ResetOnSpawn = false
gui.Name = "HungDaoFlyGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(220, 100)
frame.Position = UDim2.fromScale(0.4, 0.45)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
frame.Draggable = true
frame.BorderSizePixel = 0

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 2

-- NÚT ĐI
local btnGo = Instance.new("TextButton", frame)
btnGo.Size = UDim2.new(0.42, 0, 0.5, 0)
btnGo.Position = UDim2.new(0.05, 0, 0.35, 0)
btnGo.Font = Enum.Font.GothamBold
btnGo.TextSize = 18
btnGo.TextColor3 = Color3.new(1, 1, 1)
btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnGo.Text = "ĐI"
btnGo.BorderSizePixel = 0

local btnGoCorner = Instance.new("UICorner", btnGo)
btnGoCorner.CornerRadius = UDim.new(0, 8)

local btnGoStroke = Instance.new("UIStroke", btnGo)
btnGoStroke.Color = Color3.fromRGB(255, 255, 255)
btnGoStroke.Thickness = 1

-- NÚT VỀ
local btnBack = Instance.new("TextButton", frame)
btnBack.Size = UDim2.new(0.42, 0, 0.5, 0)
btnBack.Position = UDim2.new(0.53, 0, 0.35, 0)
btnBack.Font = Enum.Font.GothamBold
btnBack.TextSize = 18
btnBack.TextColor3 = Color3.new(1, 1, 1)
btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnBack.Text = "VỀ"
btnBack.BorderSizePixel = 0

local btnBackCorner = Instance.new("UICorner", btnBack)
btnBackCorner.CornerRadius = UDim.new(0, 8)

local btnBackStroke = Instance.new("UIStroke", btnBack)
btnBackStroke.Color = Color3.fromRGB(255, 255, 255)
btnBackStroke.Thickness = 1

-- LABEL TRẠNG THÁI
local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(0.9, 0, 0.2, 0)
label.Position = UDim2.new(0.05, 0, 0.05, 0)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextColor3 = Color3.new(1, 1, 1)
label.BackgroundTransparency = 1
label.Text = "SẴN SÀNG"

-- LOGIC NÚT ĐI
btnGo.MouseButton1Click:Connect(function()
	if ENABLED then
		stopAndCleanup()
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "SẴN SÀNG"
		return
	end
	
	ENABLED = true
	btnGo.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	label.Text = "ĐANG BAY ĐI..."
	
	task.spawn(function()
		run(POINTS_GO, "ĐI")
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "HOÀN THÀNH"
		task.wait(1)
		label.Text = "SẴN SÀNG"
	end)
end)

-- LOGIC NÚT VỀ
btnBack.MouseButton1Click:Connect(function()
	if ENABLED then
		stopAndCleanup()
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "SẴN SÀNG"
		return
	end
	
	ENABLED = true
	btnBack.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
	btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	label.Text = "ĐANG BAY VỀ..."
	
	task.spawn(function()
		run(POINTS_BACK, "VỀ")
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "HOÀN THÀNH"
		task.wait(1)
		label.Text = "SẴN SÀNG"
	end)
end)

-- XỬ LÝ RESPAWN
player.CharacterAdded:Connect(function()
	if ENABLED then
		task.wait(1)
		stopAndCleanup()
		btnGo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btnBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.Text = "SẴN SÀNG"
	end
end)

print("🌟 HungDao9999 Script Loaded! (FIXED VERSION - Reset 100%) 🌟")
