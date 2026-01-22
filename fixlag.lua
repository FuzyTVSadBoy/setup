-- BLOX FRUITS V19: NO LEAK | WEAK TABLE MEMORY | SINGLE THREAD CPU
-- TỐI ƯU HÓA: 100% KHÔNG TRÀN RAM - KHÔNG CHỒNG LOOP

-- ====================================
-- ⚙️ CẤU HÌNH
-- ====================================
_G.TargetFPS = 15          -- FPS mong muốn
_G.GreyMapEnabled = true    -- Map Xám
_G.Rendering3D = true       -- Render hình ảnh
_G.UseGUI = true            -- Bật Menu

-- ====================================
-- ⚡ KHỞI TẠO HỆ THỐNG
-- ====================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

-- Giới hạn FPS cứng (Không dùng vòng lặp)
if setfpscap then setfpscap(_G.TargetFPS) end

-- Tắt hiệu ứng Lighting (Chạy 1 lần)
Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
for _, v in pairs(Lighting:GetChildren()) do
    if v:IsA("PostProcessEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") then
        v.Enabled = false
    end
end

-- ====================================
-- 📦 HỆ THỐNG MAP (FIX MEMORY LEAK)
-- ====================================
-- SỬ DỤNG WEAK KEYS: Tự động xóa dữ liệu rác khi Part bị hủy
local MapBackup = setmetatable({}, { __mode = "k" }) 

local function HandleMap(obj)
    if not _G.GreyMapEnabled and not MapBackup[obj] then return end -- Tối ưu CPU
    
    if obj:IsA("BasePart") and not obj:IsDescendantOf(LP.Character) and not obj.Name:find("Chest") then
        if _G.GreyMapEnabled then
            -- Chỉ lưu nếu chưa có trong backup
            if not MapBackup[obj] then
                MapBackup[obj] = {
                    Color = obj.Color,
                    Material = obj.Material,
                    CastShadow = obj.CastShadow
                }
            end
            -- Áp dụng màu xám
            obj.Color = Color3.fromRGB(110,110,110)
            obj.Material = Enum.Material.SmoothPlastic
            obj.CastShadow = false
        else
            -- Khôi phục từ Backup (Nếu part còn tồn tại)
            local data = MapBackup[obj]
            if data then
                obj.Color = data.Color
                obj.Material = data.Material
                obj.CastShadow = data.CastShadow
            end
        end
    end
end

-- ====================================
-- 💣 TOTAL NUKE (CPU OPTIMIZED)
-- ====================================
local function TotalNuke(obj)
    if not obj then return end
    
    -- 1. Bỏ qua Tool (Giảm tải CPU cực lớn khi PVP/Farm)
    if obj:FindFirstAncestorOfClass("Tool") then return end
    -- 2. Bỏ qua Rương (Tránh lỗi script auto chest)
    if obj.Name:find("Chest") then return end

    -- Sử dụng logic if-elseif nhanh thay vì pcall lồng nhau
    pcall(function()
        if obj:IsA("ParticleEmitter") then
            obj.Enabled = false; obj.Rate = 0; obj:Clear()
        elseif obj:IsA("Trail") then
            obj.Enabled = false; obj.WidthScale = NumberSequence.new(0)
        elseif obj:IsA("Beam") then
            obj.Enabled = false
        elseif obj:IsA("Explosion") then
            obj.BlastPressure = 0; obj.Visible = false
        elseif obj:IsA("Highlight") then
            obj.Enabled = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false
        end
    end)
end

-- ====================================
-- 🌀 SPIN FIX (FIX CPU LEAK - SINGLE THREAD)
-- ====================================
local lastSkill = 0

-- Lắng nghe skill (Chỉ gán sự kiện, nhẹ máy)
local function OnCharacterAdded(char)
    char.DescendantAdded:Connect(function(v)
        if v:IsA("BodyMover") or v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
            lastSkill = tick()
        end
    end)
end

if LP.Character then OnCharacterAdded(LP.Character) end
LP.CharacterAdded:Connect(OnCharacterAdded)

-- VÒNG LẶP DUY NHẤT TOÀN CỤC (Thay vì tạo mới mỗi lần hồi sinh)
RunService.Heartbeat:Connect(function()
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        local dt = tick() - lastSkill
        -- Logic: Sau 3s hết chiêu mới chặn xoay
        if dt > 3 and dt < 6 then
            if root.AssemblyAngularVelocity.Magnitude > 2 then
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end)

-- ====================================
-- 👂 LẮNG NGHE & QUÉT (THROTTLED)
-- ====================================
Workspace.DescendantAdded:Connect(function(obj)
    TotalNuke(obj)
    HandleMap(obj)
end)

-- Quét 1 lần khởi đầu (Chia nhỏ task để không lag khi inject)
task.spawn(function()
    local all = Workspace:GetDescendants()
    for i = 1, #all do
        TotalNuke(all[i])
        HandleMap(all[i])
        if i % 500 == 0 then task.wait() end -- Nghỉ mỗi 500 object
    end
end)

-- ====================================
-- 🎛 GUI ĐIỀU KHIỂN
-- ====================================
if _G.UseGUI then
    local gui = Instance.new("ScreenGui")
    -- Bảo vệ GUI khỏi game detect (nếu executor hỗ trợ)
    if gethui then gui.Parent = gethui() else gui.Parent = game.CoreGui end
    
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0,160,0,120)
    frame.Position = UDim2.new(0,10,0.5,-60)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.Active = true; frame.Draggable = true

    local function CreateBtn(text, y, col, cb)
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0.9,0,0,40)
        btn.Position = UDim2.new(0.05,0,y,0)
        btn.Text = text
        btn.TextColor3 = Color3.new(1,1,1)
        btn.BackgroundColor3 = col
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    local mapBtn = CreateBtn("MAP XÁM: ON", 0.1, Color3.fromRGB(180,0,0), function()
        _G.GreyMapEnabled = not _G.GreyMapEnabled
        mapBtn.Text = _G.GreyMapEnabled and "MAP XÁM: ON" or "MAP XÁM: OFF"
        mapBtn.BackgroundColor3 = _G.GreyMapEnabled and Color3.fromRGB(180,0,0) or Color3.fromRGB(60,60,60)
        
        -- Cập nhật lại Map (An toàn với Weak Table)
        for obj, _ in pairs(MapBackup) do
            if obj.Parent then HandleMap(obj) end -- Chỉ xử lý part chưa bị xóa
        end
    end)

    local renderBtn = CreateBtn("RENDER 3D: ON", 0.55, Color3.fromRGB(0,150,0), function()
        _G.Rendering3D = not _G.Rendering3D
        RunService:Set3dRenderingEnabled(_G.Rendering3D)
        renderBtn.Text = _G.Rendering3D and "RENDER 3D: ON" or "RENDER 3D: OFF"
        renderBtn.BackgroundColor3 = _G.Rendering3D and Color3.fromRGB(0,150,0) or Color3.fromRGB(60,60,60)
    end)
end

print("🟢 V19 STABLE: 0% LEAK | WEAK TABLE | SINGLE THREAD")
