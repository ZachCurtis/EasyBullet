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
EasyBullet = "zachcurtis/easybullet@0.0.3"
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
    BulletThickness = .1
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
	BulletThickness: number? -- Sets the thickness of the bullets in studs
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

FireBullet - call on client or server to fire a bullet.
```lua
local direction = mouse.Hit.Position - gun.BarrelPosition
local velocity = direction.Unit * 400

local optionalEasyBulletSettings = {
    BulletThickness
}

easyBullet:FireBullet(gun.BarrelPosition, velocity, optionalEasyBulletSettings)
```

### Events

BulletHit - called whenever a bullet hits something
```lua
easyBullet.BulletHit:Connect(function(shootingPlayer: Player, raycastResult: RaycastResult)
    print(raycastResult.Instance.Name)
end)
```

BulletHitHumanoid - called whenever a bullet hits a part belonging to a model with a child humanoid
```lua
easyBullet.BulletHitHumanoid:Connect(function(shootingPlayer: Player, raycastResult: RaycastResult, hitHumanoid: Humanoid)
    hitHumanoid:TakeDamage(15)
end)