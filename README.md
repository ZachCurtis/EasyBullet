# EasyBullet

A simple bullet runtime that handles network replication, network syncing, and adjusts the rendered bullets by client framerate. 

## Getting Started
Download the [EasyBullet.rbxmx](https://github.com/ZachCurtis/EasyBullet/blob/main/EasyBullet.rbxmx) file and drag it into studio

Or grab the [Marketplace model](https://create.roblox.com/marketplace/asset/13513545189/EasyBullet) and insert it via the Toolbox window

To build EasyBullet into a model, use:

```bash
rojo build -o "EasyBullet.rbxmx" build.project.json
```

To serve EasyBullet into your game, use:
```bash
rojo serve
```

To install using wally, add to your wally.toml dependencies:
```toml
EasyBullet = "zachcurtis/easybullet@0.2.4"
```
Then run:
```bash
wally install
```

## Example
```lua
local EasyBullet = require(path.To.EasyBullet)

local defaultSettings = {
    Gravity = true,
    RenderBullet = true,
    BulletColor = Color3.new(0.945098, 0.490196, 0.062745),
    BulletThickness = .1,
    FilterList = {},
    FilterType = Enum.RaycastFilterType.Exclude,
    BulletPartProps = {},
    BulletData = {}
}

local easyBullet = easyBullet.new(defaultSettings)

easeBullet:FireBullet(barrelPosition, bulletVelocity)

easyBullet.BulletHitHumanoid:Connect(function(shootingPlayer, rayResult, hitHumanoid)
    hitHumanoid:TakeDamage(15)
end)
```

## API

EasyBulletSettings
```lua
export type EasyBulletSettings = {
    Gravity: boolean?, -- Should the bullet curve according to workspace.Gravity
    RenderBullet: boolean?, -- Should EasyBullet display a rendered bullet on the client
    BulletColor: Color3?, -- Sets the color of the bullets rendered
    BulletThickness: number?, -- Sets the thickness of the bullets in studs
    FilterList: {[number]: Instance}?, -- An array of instances assigned to RayParams.FilterDescendantsInstances
    FilterType: Enum.RaycastFilterType?, -- The RaycastFilterType, either Include or Exclude
    BulletPartProps: {[string]: unknown}?, -- A dictionary of properties matching the properties of BasePart to override the bullet part rendering. Cannot include keys "CFrame", "Size", or "Color"
    BulletData: {[string]: unknown}? -- A dictionary of any data you wish to associate with this bullet. HitVelocity is a reserved key for this table, and is set by EasyBullet before passing the BulletData table to the BulletHit, BulletHitHumanoid, and BulletUpdated events. Useful for variations such as displaying a different hit effect for a sniper, or altering the damage dependent on the gun type.
}
```
#### Default EasyBulletSettings
| Field   | Type    | Default |
| ------- | ------- | ------- |
| Gravity | boolean | true    |
| RenderBullet | boolean | true |
| BulletColor | Color3 | Color3.new(0.945098, 0.490196, 0.062745) |
|  BulletThickness | number | .1 |
| FilterList | table | {} |
| FilterType | [RaycastFilterType](https://create.roblox.com/docs/reference/engine/enums/RaycastFilterType) | Enum.RaycastFilterType.Exclude |
| BulletPartProps | table | {} |


### Methods
Constructor - EasyBullet is a singleton so it will only construct once per server or client but any subsequent calls to EasyBullet.new will return the constructed singleton. Only the settings overrides passed to the first constructor will be used.
```lua
local EasyBulletSettingsOverrides = {
    BulletColor = Color3.new(1, 0, 0),
    Gravity = false
}

local easyBullet = EasyBullet.new(EasyBulletSettingsOverrides)
```

FireBullet - call on client or server to fire a bullet
```lua
local direction = mouse.Hit.Position - gun.BarrelPosition
local velocity = direction.Unit * 400

local optionalEasyBulletSettings = {
    BulletThickness = .4
}

easyBullet:FireBullet(gun.BarrelPosition, velocity, optionalEasyBulletSettings)
```

BindCustomCast - pass a callback that returns a RaycastResult or nil to implement custom raycast behavior, such as lag compensation for network delayed character positions
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

### Events

BulletHit - called whenever a bullet hits something
```lua
easyBullet.BulletHit:Connect(function(shootingPlayer: Player?, raycastResult: RaycastResult, bulletData: {[string]: Unknown} | {HitVelocity: Vector3})
    print(raycastResult.Instance.Name)
end)
```

BulletHitHumanoid - called whenever a bullet hits a part belonging to a model with a child humanoid
```lua
easyBullet.BulletHitHumanoid:Connect(function(shootingPlayer: Player?, raycastResult: RaycastResult, hitHumanoid: Humanoid, bulletData: {[string]: Unknown} | {HitVelocity: Vector3})
    hitHumanoid:TakeDamage(15)
end)
```

BulletUpdated - called every time the bullet updates. Useful for rendering custom bullets.
```lua
easyBullet.BulletUpdated:Connect(function(lastFramePosition: Vector3, thisFramePosition: Vector3, bulletData: {[string]: unknown})
    local direction = lastFramePosition - thisFramePosition

    bulletPart.Size = Vector3.new(.2, .2, direction.Magnitude)
    bulletPart.CFrame = CFrame.lookAt(lastFramePosition, thisFramePosition) * CFrame.new(0,0, -direction.Magnitude * .5)
end)
```