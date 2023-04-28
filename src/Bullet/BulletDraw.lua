local USE_PART_FPS = 45 -- will use a part for bullets above this fps

local RunService = game:GetService("RunService")

local ClientFPS = 1/RunService.Heartbeat:Wait()

if RunService:IsClient() then
    RunService.Heartbeat:Connect(function(dt)
        ClientFPS = 1 / dt 
    end)
end

local bulletCache = {}

local function createBulletPart(addToCache: boolean)
    local newBulletInstance

    if RunService:IsClient() then
        if ClientFPS >= USE_PART_FPS then
            newBulletInstance = Instance.new("Part")
            newBulletInstance.Anchored = true
            newBulletInstance.CanCollide = false
            newBulletInstance.CanTouch = false
            newBulletInstance.CanQuery = false
            newBulletInstance.Material = Enum.Material.Neon
        else
            newBulletInstance = Instance.new("CylinderHandleAdornment")
        end
    else
        newBulletInstance = Instance.new("CylinderHandleAdornment")
    end

    if addToCache then
        table.insert(bulletCache, newBulletInstance)
    end

    return newBulletInstance
end

for _ = 1, 20 do
    createBulletPart(true)
end

local function getBulletPart()
    if #bulletCache == 0 then
        return createBulletPart(false)
    else
        local bulletPart = bulletCache[#bulletCache]
        table.remove(bulletCache, #bulletCache)

        if (bulletPart:IsA("BasePart") and ClientFPS < USE_PART_FPS) or (bulletPart:IsA("CylinderHandleAdornment") and ClientFPS >= USE_PART_FPS) then
            bulletPart:Destroy()

            return createBulletPart(false)
        else
            return bulletPart
        end
    end
end

local function returnBulletPart(bulletPart)
    if (bulletPart:IsA("BasePart") and ClientFPS < USE_PART_FPS) or (bulletPart:IsA("CylinderHandleAdornment") and ClientFPS >= USE_PART_FPS) then
        bulletPart:Destroy()
        createBulletPart(true)
    else
        bulletPart.Parent = nil
        table.insert(bulletCache, bulletPart)
    end
end


local BulletDraw = {}
BulletDraw.__index = BulletDraw

function BulletDraw.new(bulletColor: Color3, bulletThickness: number)
    local self = setmetatable({}, BulletDraw)
    
    self.BulletColor = bulletColor
    self.BulletThickness = bulletThickness

    self:_makeAdornPart()

    self.BulletPart = getBulletPart()
    self:_updateBulletProps()

    self.GraphicsQualityChanged = nil

    return self
end

function BulletDraw:Draw(pos0: Vector3, pos1: Vector3)
    if self.BulletPart.Parent ~= workspace then
        self.BulletPart.Parent = workspace
    end

    local diff = pos0 - pos1

    if self.BulletPart:IsA("BasePart") then
        self.BulletPart.Size = Vector3.new(self.BulletThickness, self.BulletThickness, diff.Magnitude)
        self.BulletPart.CFrame = CFrame.lookAt(pos0, pos1) * CFrame.new(0,0, -diff.Magnitude * .5)
    elseif self.BulletPart:IsA("CylinderHandleAdornment") then
        self.BulletPart.Height = diff.Magnitude
        self.BulletPart.CFrame = self.AdornPart.CFrame:inverse() * (CFrame.lookAt(pos0, pos1) * CFrame.new(0,0, -diff.Magnitude * .5))
    end
end

function BulletDraw:Destroy()
    returnBulletPart(self.BulletPart)

    self.BulletPart = nil
end


-- private methods

function BulletDraw:_updateBulletProps()
    if self.BulletPart:IsA("BasePart") then
        self.BulletPart.Color = self.BulletColor
    elseif self.BulletPart:IsA("CylinderHandleAdornment") then
        self.BulletPart.Color3 = self.BulletColor
        self.BulletPart.Radius = self.BulletThickness * .5
        self.BulletPart.Adornee = self.AdornPart
    end
end

function BulletDraw:_makeAdornPart()
    local adornPart = workspace:FindFirstChild("AdornPart")

    if not adornPart then
        adornPart = Instance.new("Part")
        adornPart.Name = "AdornPart"
        adornPart.Anchored = true
        adornPart.Size = Vector3.new(.001, .001, .001)
        adornPart.Transparency = 1
        adornPart.CanCollide = false
        adornPart.CanTouch = false
        adornPart.CanQuery = false
        adornPart.CFrame = CFrame.new(0, workspace.FallenPartsDestroyHeight + 55, 0)
        adornPart.Parent = workspace
    end

    self.AdornPart = adornPart
end

return BulletDraw