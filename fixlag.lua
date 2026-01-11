-- 🔥 BLOX FRUITS V9 FINAL - TRUE AFK FIX LAG 🔥
-- CLEAN EFFECTS | SAFE GODHUMAN | FIX GREY MAP | NO CONSOLE ERROR

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer

_G.GreyMapEnabled = true
_G.Rendering3D = true

-- =========================
-- 📦 MAP BACKUP (FOR TOGGLE)
-- =========================
local MapBackup = {}

local function SaveMap(obj)
    if not MapBackup[obj] then
        MapBackup[obj] = {
            Color = obj.Color,
            Material = obj.Material,
            CastShadow = obj.CastShadow
        }
    end
end

local function ApplyGrey(obj)
    SaveMap(obj)
    obj.Color = Color3.fromRGB(110,110,110)
    obj.Material = Enum.Material.SmoothPlastic
    obj.CastShadow = false
end

local function RestoreMap(obj)
    local data = MapBackup[obj]
    if data then
        obj.Color = data.Color
        obj.Material = data.Material
        obj.CastShadow = data.CastShadow
    end
end

-- =========================
-- 💣 TOTAL EFFECT NUKE
-- =========================
local function TotalNuke(obj)
    if not obj then return end
    if obj:FindFirstAncestorOfClass("Tool") then return end

    pcall(function()
        if obj:IsA("ParticleEmitter") then
            obj.Enabled = false
            obj.Rate = 0
            obj.Lifetime = NumberRange.new(0)
            obj.Size = NumberSequence.new(0)

        elseif obj:IsA("Trail") then
            obj.Enabled = false
            obj.WidthScale = NumberSequence.new(0)

        elseif obj:IsA("Beam") then
            obj.Enabled = false

        elseif obj:IsA("Explosion") then
            obj.BlastPressure = 0
            obj.Visible = false

        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1

        elseif obj:IsA("Highlight") then
            obj.Enabled = false

        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false

        elseif obj:IsA("Sound") then
            obj.Volume = 0
        end
    end)
end

-- =========================
-- 🗺 MAP GREY HANDLER
-- =========================
local function HandleMap(obj)
    if obj:IsA("BasePart") and not obj:IsDescendantOf(LP.Character) then
        if _G.GreyMapEnabled then
            ApplyGrey(obj)
        else
            RestoreMap(obj)
        end
    end
end

-- =========================
-- 🌀 GODHUMAN SAFE SPIN FIX
-- =========================
local lastSkill = 0

local function SetupCharacter(char)
    local root = char:WaitForChild("HumanoidRootPart", 5)

    char.DescendantAdded:Connect(function(v)
        if v:IsA("BodyMover") or v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
            lastSkill = tick()
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not root then return end

        local dt = tick() - lastSkill

        -- ⚠ CHỈ FIX XOAY SAU KHI HẾT CHIÊU
        if dt > 3 and dt < 6 then
            if root.AssemblyAngularVelocity.Magnitude > 2 then
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end

-- =========================
-- 👂 LISTEN WORLD
-- =========================
Workspace.DescendantAdded:Connect(function(obj)
    TotalNuke(obj)
    HandleMap(obj)
end)

-- =========================
-- 🚀 INIT SCAN
-- =========================
for _, v in ipairs(Workspace:GetDescendants()) do
    TotalNuke(v)
    HandleMap(v)
end

if LP.Character then
    SetupCharacter(LP.Character)
end
LP.CharacterAdded:Connect(SetupCharacter)

-- =========================
-- 🎛 GUI
-- =========================
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,160,0,120)
frame.Position = UDim2.new(0,10,0.5,-60)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Active = true
frame.Draggable = true

-- MAP BUTTON
local mapBtn = Instance.new("TextButton", frame)
mapBtn.Size = UDim2.new(0.9,0,0,40)
mapBtn.Position = UDim2.new(0.05,0,0.1,0)
mapBtn.Text = "MAP XÁM: ON"
mapBtn.TextColor3 = Color3.new(1,1,1)
mapBtn.BackgroundColor3 = Color3.fromRGB(180,0,0)

mapBtn.MouseButton1Click:Connect(function()
    _G.GreyMapEnabled = not _G.GreyMapEnabled
    mapBtn.Text = _G.GreyMapEnabled and "MAP XÁM: ON" or "MAP XÁM: OFF"
    for obj,_ in pairs(MapBackup) do
        if obj and obj.Parent then
            HandleMap(obj)
        end
    end
end)

-- RENDER BUTTON
local renderBtn = Instance.new("TextButton", frame)
renderBtn.Size = UDim2.new(0.9,0,0,40)
renderBtn.Position = UDim2.new(0.05,0,0.55,0)
renderBtn.Text = "RENDER 3D: ON"
renderBtn.TextColor3 = Color3.new(1,1,1)
renderBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)

renderBtn.MouseButton1Click:Connect(function()
    _G.Rendering3D = not _G.Rendering3D
    RunService:Set3dRenderingEnabled(_G.Rendering3D)
    renderBtn.Text = _G.Rendering3D and "RENDER 3D: ON" or "RENDER 3D: OFF"
end)

print("✅ V9 FINAL LOADED | CLEAN | STABLE | AFK READY")
