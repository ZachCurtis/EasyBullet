---
sidebar_position: 2
---
# EasyBullet Settings

## Full Lua Definition
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
    BulletData: {[string]: unknown}? -- A dictionary of any data you wish to associate with this bullet. HitVelocity and BulletId are reserved keys for this table, and are set by EasyBullet before passing the BulletData table to the BulletHit, BulletHitHumanoid, and BulletUpdated events. Useful for variations such as displaying a different hit effect for a sniper, or altering the damage dependent on the gun type.
}
```

## Default EasyBulletSettings
| Field   | Type    | Default |
| ------- | ------- | ------- |
| Gravity | boolean | true    |
| RenderBullet | boolean | true |
| BulletColor | Color3 | Color3.new(0.945098, 0.490196, 0.062745) |
|  BulletThickness | number | .1 |
| FilterList | { [number]: Instance } | {} |
| FilterType | [RaycastFilterType](https://create.roblox.com/docs/reference/engine/enums/RaycastFilterType) | Enum.RaycastFilterType.Exclude |
| BulletPartProps | { [string]: unknown } | {} |
| BulletData | { [string]: unknown } | {} |