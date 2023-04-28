local RunService = game:GetService("RunService")

local kinematic = require(script:WaitForChild("kinematic"))
local BulletDraw = require(script:WaitForChild("BulletDraw"))
local Signal = require(script.Parent:WaitForChild("Signal"))

local function raycast(v0: Vector3, v1: Vector3, rayparams: RaycastParams)
    local diff = v1 - v0

    return workspace:Raycast(v0, diff, rayparams)
end

local function recursiveHumanoidCheck(instance: Instance): boolean | Humanoid
    local parentModel = instance:FindFirstAncestorOfClass("Model")

    if (not parentModel) or parentModel:IsA("WorldRoot") then
        return false
    end

    local childHumanoid = parentModel:FindFirstChildOfClass("Humanoid")

    if childHumanoid then
        return childHumanoid
    else
        return recursiveHumanoidCheck(parentModel)
    end
end

local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(barrelPosition: Vector3, velocity: Vector3, easyBulletSettings)
    local self = setmetatable({}, Bullet)

    self.BulletHit = Signal.new()
    self.BelowFallenParts = Signal.new()
    
    self.BarrelPosition = barrelPosition
    self.Velocity = velocity
    self.EasyBulletSettings = easyBulletSettings

    self.RayParams = RaycastParams.new()
    self.RayParams.FilterDescendantsInstances = easyBulletSettings.FilterList or {}
    self.RayParams.FilterType = easyBulletSettings.FilterType or Enum.RaycastFilterType.Exclude
    
    if RunService:IsClient() and easyBulletSettings.RenderBullet then
        self._bulletDraw = BulletDraw.new(easyBulletSettings.BulletColor, easyBulletSettings.BulletThickness)
    end
    
    self._lastPosition = barrelPosition

    return self
end

function Bullet:Start(ping: number?)
    self.StartTime = os.clock()

    if ping then 
        self.StartTime -= ping
    end
end

function Bullet:Update()
    local currentTime = os.clock()
    local elapsedTime = currentTime - self.StartTime

    local acceleration = self.EasyBulletSettings.Gravity and Vector3.new(0, -workspace.Gravity, 0) or Vector3.zero

    local currentDisplacement = kinematic(self.Velocity, acceleration, elapsedTime)

    local currentPosition = self.BarrelPosition + currentDisplacement

    if currentPosition.Y <= workspace.FallenPartsDestroyHeight then
        self.BelowFallenParts:Fire()
        return
    end

    local rayResult = raycast(self._lastPosition, currentPosition, self.RayParams)

    self:HandleRayResult(rayResult)

    if self._bulletDraw then
        self._bulletDraw:Draw(self._lastPosition, currentPosition)
    end

    self._lastPosition = currentPosition
end

function Bullet:HandleRayResult(raycastResult: RaycastResult?)
    if not raycastResult then return end

    local hitHumanoid = recursiveHumanoidCheck(raycastResult.Instance)

    self.BulletHit:Fire(raycastResult, hitHumanoid)
end

function Bullet:Destroy()
    if self._bulletDraw then
        self._bulletDraw:Destroy()
        self._bulletDraw = nil
    end

    self.BulletHit:Destroy()
    self.BelowFallenParts:Destroy()
end


return Bullet