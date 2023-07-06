---
sidebar_position: 1
---
# EasyBullet API

## Table of Contents
- [Constructor](#constructor)
- [Methods](#Methods)
    - [FireBullet()](#fireBullet)
    - [BindCustomCast](#bindCustomCast)
    - [BindShouldFire](#bindShouldFire)
- [Events](#Events)
    - [BulletHit](#BulletHit)
    - [BulletHitHumanoid](#BulletHitHumanoid)
    - [BulletUpdated](#BulletUpdated)

## Constructor {#constructor}

EasyBullet is a singleton so it will only be constructed once per server or client, but any subsequent calls to EasyBullet.new() will return the constructed singleton. Only the settings table passed to the first constructor will be used.
```lua
local EasyBulletSettingsOverrides = {
    BulletColor = Color3.new(1, 0, 0),
    Gravity = false
}

local easyBullet = EasyBullet.new(EasyBulletSettingsOverrides)
```

## Methods

### FireBullet() {#fireBullet}
The primary method used to interact with EasyBullet. It fires a single bullet, and can be called on both the client, and the server. Call FireBullet() on the client to fire a bullet for a player, or on the server to fire a bullet for a NPC.

```lua
local direction = mouse.Hit.Position - gun.BarrelPosition
local velocity = direction.Unit * 400

local optionalEasyBulletSettings = {
    BulletThickness = .4,
    BulletData = {
        BulletType = "AK47"
    }
}

easyBullet:FireBullet(gun.BarrelPosition, velocity, optionalEasyBulletSettings)
```

### BindCustomCast() {#bindCustomCast}
Pass BindCustomCast() a callback that returns a RaycastResult, or nil, to implement custom raycast behavior, such as lag compensation for network delayed character positions, or SphereCast for larger projectiles such as cannonballs.

```lua
easyBullet:BindCustomCast(function(shooter: Player?, lastFramePosition: Vector3, thisFramePosition: Vector3, elapsedTime: number, bulletData: {[string]: Unknown})
    local direction = lastFramePosition - thisFramePosition

    local raycastParams = RaycastParams.new()

    -- npc shots have no shooting player
    if shooter then
        raycastParams.FilterDescendantsInstances = {shooter.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    end

    return workspace:Raycast(lastFramePosition, direction, raycastParams)
end)
```
pass a callback that returns a boolean to provide a means of filtering bullets before they're fired. This doesn't prevent the bullet from being networked (see [#2](https://github.com/ZachCurtis/EasyBullet/issues/2)), so `BindShouldFire` should only be called on the Server
```lua
easyBullet:BindShouldFire(function(shooter: Player?, barrelPosition: Vector3, velocity: Vector3, ping: number, easyBulletSettings: Bullet.EasyBulletSettings?)
    if not shooter or not shooter.Character or not shooter.Character.HumanoidRootPart then
        return false
    end

    local humanoid = shooter.Character.Humanoid
    local rootPart = shooter.Character.HumanoidRootPart

    local discrepancy = (barrelPosition - rootPart.Position).Magnitude
    local desyncTolerance = (shooter:GetNetworkPing() * humanoid.WalkSpeed) * 1.2

    -- return true if barrelPosition is within how far the player could have walked in that time
    return discrepancy <= desyncTolerance
end)
``` 

### BindShouldFire() {#bindShouldFire}
Pass this BindShouldFire() a callback that returns a boolean to provide a means of filtering bullets before they're fired. The bullet will initially be networked before the ShouldFire callback is called, but the bullet will automatically clean it's self up across the network if the ShouldFire callback returns false.
```lua
easyBullet:BindShouldFire(function(shooter: Player?, barrelPosition: Vector3, velocity: Vector3, ping: number, easyBulletSettings: Bullet.EasyBulletSettings?)
    if not shooter or not shooter.Character or not shooter.Character.HumanoidRootPart then
        return false
    end

    local humanoid = shooter.Character.Humanoid
    local rootPart = shooter.Character.HumanoidRootPart

    local discrepancy = (barrelPosition - rootPart.Position).Magnitude
    local desyncTolerance = (shooter:GetNetworkPing() * humanoid.WalkSpeed) * 1.2

    -- return true if barrelPosition is within how far the player could have walked in that time
    return discrepancy <= desyncTolerance
end)
``` 

## Events

### BulletHit
This event is fired whenever a bullet hits something.
```lua
easyBullet.BulletHit:Connect(function(shootingPlayer: Player?, raycastResult: RaycastResult, bulletData: {[string]: Unknown} | {HitVelocity: Vector3})
    print(raycastResult.Instance.Name)
end)
```

### BulletHitHumanoid
This event is fired whenever a bullet hits a part belonging to a model with a child humanoid.
```lua
easyBullet.BulletHitHumanoid:Connect(function(shootingPlayer: Player?, raycastResult: RaycastResult, hitHumanoid: Humanoid, bulletData: {[string]: Unknown} | {HitVelocity: Vector3})
    hitHumanoid:TakeDamage(15)
end)
```

### BulletUpdated
This event is fired every time the bullet updates. Useful for rendering custom bullets.
```lua
easyBullet.BulletUpdated:Connect(function(lastFramePosition: Vector3, thisFramePosition: Vector3, bulletData: {[string]: unknown})
    local direction = lastFramePosition - thisFramePosition

    bulletPart.Size = Vector3.new(.2, .2, direction.Magnitude)
    bulletPart.CFrame = CFrame.lookAt(lastFramePosition, thisFramePosition) * CFrame.new(0,0, -direction.Magnitude * .5)
end)
```