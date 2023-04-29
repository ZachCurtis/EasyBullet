local RunService = game:GetService("RunService")

local kinematic = require(script:WaitForChild("kinematic"))
local BulletDraw = require(script:WaitForChild("BulletDraw"))
local Signal = require(script.Parent:WaitForChild("Signal"))

export type CastCallback = (shooter: Player?, pos0: Vector3, pos1: Vector3, elapsedTime: number) -> RaycastResult?

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

function Bullet.new(shootingPlayer: Player?, barrelPosition: Vector3, velocity: Vector3, easyBulletSettings)
    local self = setmetatable({}, Bullet)

    self.Shooter = shootingPlayer
    
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

    self.BulletHit = Signal.new()
    self.BelowFallenParts = Signal.new()

    return self
end

function Bullet:Start(ping: number?)
    self.StartTime = os.clock()

    if ping then 
        self.StartTime -= ping
    end
end

function Bullet:Update(castCallback: CastCallback?): (Vector3?, Vector3?)
    local lastPosition = self._lastPosition
    local currentPosition, elapsedTime = self:_getCurrentPositionAndLifetime()

    if currentPosition.Y <= workspace.FallenPartsDestroyHeight then
        self.BelowFallenParts:Fire()
        return
    end

    local rayResult

    if castCallback then
        rayResult = castCallback(self.Shooter, lastPosition, currentPosition, elapsedTime)
    else
        rayResult = raycast(lastPosition, currentPosition, self.RayParams)
    end
    
    self:_handleRayResult(rayResult)

    if self._bulletDraw then
        self._bulletDraw:Draw(lastPosition, currentPosition)
    end

    self._lastPosition = currentPosition

    return lastPosition, currentPosition
end

function Bullet:Destroy()
    if self._bulletDraw then
        self._bulletDraw:Destroy()
        self._bulletDraw = nil
    end

    self.BulletHit:Destroy()
    self.BelowFallenParts:Destroy()
end

function Bullet:_getCurrentPositionAndLifetime(): (Vector3, number)
    local currentTime = os.clock()
    local elapsedTime = currentTime - self.StartTime

    local acceleration = self.EasyBulletSettings.Gravity and Vector3.new(0, -workspace.Gravity, 0) or Vector3.zero

    local currentDisplacement = kinematic(self.Velocity, acceleration, elapsedTime)
    local currentPosition = self.BarrelPosition + currentDisplacement

    return currentPosition, elapsedTime
end

function Bullet:_handleRayResult(raycastResult: RaycastResult?)
    if not raycastResult then return end

    local hitHumanoid = recursiveHumanoidCheck(raycastResult.Instance)

    self.BulletHit:Fire(raycastResult, hitHumanoid)
end


return Bullet