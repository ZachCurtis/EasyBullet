---
sidebar_position: 1
---
# Simplest Usage Example

This is the simplest possible usage example of EasyBullet. This won't include any of the settings and extra methods.



## Construct the library
First step is to construct EasyBullet on the server and client. We aren't using any settings in this example, so nothing needs to be passed to the constructors. 
```lua
-- Server Script
local EasyBullet = require(game:GetService("ReplicatedStorage"):WaitForChild("EasyBullet"))

local easyBullet = EasyBullet.new()
```

```lua
--- Client LocalScript
local EasyBullet = require(game:GetService("ReplicatedStorage"):WaitForChild("EasyBullet"))

local easyBullet = EasyBullet.new()
```
From now on, whenever we're interacting with EasyBullet we'll use the constructed object referenced by the `easyBullet` variable

## Bind to the BulletHitHumanoid event on the server
We'll use the `easyBullet.BulletHitHumanoid` signal to deal damage whenever a bullet hits a part belonging to a humanoid character.

Dealing damage is always something you want to do server authoritatively, so we'll connect to the event in the Server Script
```lua
--- Server Script
local EasyBullet = require(game:GetService("ReplicatedStorage"):WaitForChild("EasyBullet"))

local easyBullet = EasyBullet.new()

-- Bind to the BulletHitHumanoid signal
easyBullet.BulletHitHumanoid:Connect(function(shootingPlayer: Player?, raycastResult: RaycastResult, hitHumanoid: Humanoid)

    -- We'll use the shootingPlayer parameter to filter out damaging the shooting player
    if shootingPlayer.Character and shootingPlayer.Character:IsAncestorOf(hitHumanoid) then
        -- early exit
        return
    end

    -- Deal damage to any humanoid that doesn't belong to the shooting player
    hitHumanoid:TakeDamage(15)
end)
```

## Handle user input to fire a bullet
We need a way for our player to tell EasyBullet to fire a bullet. For the sake of simplicity, we'll use the old PlayerMouse to solve for aiming the bullet and handle the click event, and use the HumanoidRootPart to find the barrel position.

The FireBullet() method takes in 3 arguments: The position of the barrel, the velocity of the bullet, and an optional settings override table to use for just this bullet. We're going to ignore the third argument and just worry about the barrel position and bullet velocity for this example. 
```lua
-- Client LocalScript
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Mouse = Player:GetMouse()

local EasyBullet = require(game:GetService("ReplicatedStorage"):WaitForChild("EasyBullet"))

local easyBullet = EasyBullet.new()

-- First let's make a helper function to return a barrel CFrame slightly in front of our HumanoidRootPart
local function getBarrelCFrame()
    return HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
end

-- Handle the mouse clicking to fire the bullet
Mouse.Button1Down:Connect(function()

    -- We call the FireBullet() method every time we want to fire a bullet.
    -- It takes a barrel position, and a bullet velocity. Both are Vector3's.

    -- Use our helper function from above to get the barrel position
    local barrelPos = getBarrelCFrame().Position

    -- Find the direction of the velocity vector by creating a new vector from the barrelPos to the Mouse.Hit.Position
    local direction = Mouse.Hit.Position - barrelPos

    -- Scale the direction's Unit vector by our desired bullet velocity
    local velocity = direction.Unit * 85

    -- Call the FireBullet() method
    easyBullet:FireBullet(barrelPos, velocity)
end)
```


## Full example
And it's as easy as that! The full scripts from our steps above are as follows:
```lua
--- Server Script
local EasyBullet = require(game:GetService("ReplicatedStorage"):WaitForChild("EasyBullet"))

local easyBullet = EasyBullet.new()

easyBullet.BulletHitHumanoid:Connect(function(shootingPlayer: Player?, raycastResult: RaycastResult, hitHumanoid: Humanoid)
    if shootingPlayer.Character and shootingPlayer.Character:IsAncestorOf(hitHumanoid) then
        return
    end

    hitHumanoid:TakeDamage(15)
end)
```

```lua
-- Client LocalScript
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Mouse = Player:GetMouse()

local EasyBullet = require(game:GetService("ReplicatedStorage"):WaitForChild("EasyBullet"))

local easyBullet = EasyBullet.new()

local function getBarrelCFrame()
    return HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
end

Mouse.Button1Down:Connect(function()
    local barrelPos = getBarrelCFrame().Position

    local direction = Mouse.Hit.Position - barrelPos

    local velocity = direction.Unit * 85

    easyBullet:FireBullet(barrelPos, velocity)
end)
```
