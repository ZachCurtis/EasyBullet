# EasyBullet

A simple bullet runtime that handles network replication, network syncing, and adjusts the rendered bullets by client framerate. 

## Getting Started
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
EasyBullet = "zachcurtis/easybullet@0.1.9"
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
    FilterType = Enum.RaycastFilterType.Exclude
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
    FilterType: Enum.RaycastFilterType? -- The RaycastFilterType, either Include or Exclude
}
```

### Methods
Constructor - call once on server and once on client
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
easyBullet:BindCustomCast(function(shooter: Player?, lastFramePosition: Vector3, thisFramePosition: Vector3, elapsedTime: number)
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
easyBullet.BulletHit:Connect(function(shootingPlayer: Player?, raycastResult: RaycastResult)
    print(raycastResult.Instance.Name)
end)
```

BulletHitHumanoid - called whenever a bullet hits a part belonging to a model with a child humanoid
```lua
easyBullet.BulletHitHumanoid:Connect(function(shootingPlayer: Player?, raycastResult: RaycastResult, hitHumanoid: Humanoid)
    hitHumanoid:TakeDamage(15)
end)
```

BulletUpdated - called every time the bullet updates. Useful for rendering custom bullets.
```lua
easyBullet.BulletUpdated:Connect(function(lastFramePosition: Vector3, thisFramePosition: Vector3)
    local direction = lastFramePosition - thisFramePosition

    bulletPart.Size = Vector3.new(.2, .2, direction.Magnitude)
    bulletPart.CFrame = CFrame.lookAt(lastFramePosition, thisFramePosition) * CFrame.new(0,0, -direction.Magnitude * .5)
end)
```