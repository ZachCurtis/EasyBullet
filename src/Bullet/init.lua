--!strict

-- COPYRIGHT 2023 Zach Curtis
-- Distrubted under the MIT License

local RunService = game:GetService("RunService")

local KinematicEquations = require(script:WaitForChild("KinematicEquations"))
local BulletDraw = require(script:WaitForChild("BulletDraw"))
local Signal = require(script.Parent:WaitForChild("Signal"))

type BulletDataKey = "HitVelocity"

export type BulletData = {[BulletDataKey | string]: unknown}

export type CastCallback = (shooter: Player?, pos0: Vector3, pos1: Vector3, elapsedTime: number, BulletData) -> RaycastResult?

export type EasyBulletSettings = {
	Gravity: boolean,
	RenderBullet: boolean,
	BulletColor: Color3,
	BulletThickness: number,
	FilterList: {[number]: Instance},
	FilterType: Enum.RaycastFilterType,
    BulletPartProps: {[string]: unknown},
    BulletData: BulletData
}

type BulletProps = {
    Shooter: Player?,
    BarrelPosition: Vector3,
    Velocity: Vector3,
    EasyBulletSettings: EasyBulletSettings,
    RayParams: RaycastParams,
    BulletHit: Signal.Signal<RaycastResult, boolean | Humanoid, BulletData>,
    BelowFallenParts: Signal.Signal<nil>,
    StartTime: number,
    _bulletDraw: BulletDraw.BulletDraw?,
    _lastPosition: Vector3,
}

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

export type Bullet = typeof(setmetatable({} :: BulletProps, Bullet))


function Bullet.new(shootingPlayer: Player?, barrelPosition: Vector3, velocity: Vector3, easyBulletSettings: EasyBulletSettings)
    local self = setmetatable({} :: BulletProps, Bullet)

    self.Shooter = shootingPlayer
    
    self.BarrelPosition = barrelPosition
    self.Velocity = velocity
    self.EasyBulletSettings = easyBulletSettings

    self.RayParams = RaycastParams.new()
    self.RayParams.FilterDescendantsInstances = easyBulletSettings.FilterList or {}
    self.RayParams.FilterType = easyBulletSettings.FilterType or Enum.RaycastFilterType.Exclude
    
    if RunService:IsClient() and easyBulletSettings.RenderBullet then
        self._bulletDraw = BulletDraw.new(easyBulletSettings.BulletColor, easyBulletSettings.BulletThickness, self.EasyBulletSettings.BulletPartProps)
    end
    
    self._lastPosition = barrelPosition
    self.StartTime = 0

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

function Bullet.Update(self: Bullet, castCallback: CastCallback?): (Vector3?, Vector3?)
    local lastPosition = self._lastPosition
    local currentPosition, elapsedTime = self:_getCurrentPositionAndLifetime()

    if currentPosition.Y <= workspace.FallenPartsDestroyHeight then
        self.BelowFallenParts:Fire()
        return
    end

    local rayResult

    if castCallback then
        rayResult = castCallback(self.Shooter, lastPosition, currentPosition, elapsedTime, self.EasyBulletSettings.BulletData)
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

function Bullet.Destroy(self: Bullet)
    if self._bulletDraw then
        self._bulletDraw:Destroy()
        self._bulletDraw = nil
    end

    self.BulletHit:Destroy()
    self.BelowFallenParts:Destroy()
end

function Bullet:_getElapsedTime(): number
    local currentTime = os.clock()

    return currentTime - self.StartTime
end

function Bullet:_getAcceleration(): Vector3
    return self.EasyBulletSettings.Gravity and Vector3.new(0, -workspace.Gravity, 0) or Vector3.zero
end

function Bullet._getCurrentPositionAndLifetime(self: Bullet): (Vector3, number)
    local elapsedTime = self:_getElapsedTime()
    local acceleration = self:_getAcceleration()

    local currentDisplacement = KinematicEquations:GetDisplacementFromTime(self.Velocity, acceleration, elapsedTime)
    local currentPosition = self.BarrelPosition + currentDisplacement

    return currentPosition, elapsedTime
end

function Bullet:_handleRayResult(raycastResult: RaycastResult?)
    if not raycastResult then return end

    local elapsedTime = self:_getElapsedTime()
    local acceleration = self:_getAcceleration()

    local hitVelocity = KinematicEquations:GetFinalVelocityFromTime(self.Velocity, acceleration, elapsedTime)

    local bulletData = self.EasyBulletSettings.BulletData
    
    bulletData.HitVelocity = hitVelocity

    local hitHumanoid = recursiveHumanoidCheck(raycastResult.Instance)

    self.BulletHit:Fire(raycastResult, hitHumanoid, bulletData)
end


return Bullet