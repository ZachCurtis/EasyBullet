--!strict

-- COPYRIGHT 2023 Zach Curtis
-- Distrubted under the MIT License
-- VERSION 0.2.4

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Bullet = require(script:WaitForChild("Bullet"))
local Signal = require(script:WaitForChild("Signal"))

type EasyBulletProps = {
	EasyBulletSettings: Bullet.EasyBulletSettings,
	BulletHit: Signal.Signal<Player?, RaycastResult, Bullet.BulletData>,
	BulletHitHumanoid: Signal.Signal<Player?, RaycastResult, Humanoid, Bullet.BulletData>,
	BulletUpdated: Signal.Signal<Vector3, Vector3, Bullet.BulletData>,
	Bullets: {[number]: Bullet.Bullet},
	FiredRemote: RemoteEvent?,
	CustomCastCallback: (Player?, Vector3, Vector3, number, Bullet.BulletData) -> ()?
}

type EasyBulletMethods = {
	FireBullet: (self: EasyBullet, barrelPosition: Vector3, bulletVelocity: Vector3, easyBulletSettings: Bullet.EasyBulletSettings?) -> (),
	BindCustomCast: (self: EasyBullet, callback: Bullet.CastCallback) -> (),
	_fireBullet: (self: EasyBullet, shootingPlayer: Player?, barrelPos: Vector3, velocity: Vector3, ping: number, easyBulletSettings: Bullet.EasyBulletSettings?) -> (),
	_bindEvents: () -> (),

}

local function optionalTableMerge(optionalTable: Bullet.EasyBulletSettings, nonOptionalTable: Bullet.EasyBulletSettings): Bullet.EasyBulletSettings
	for key, value in pairs(nonOptionalTable) do
		if optionalTable[key] == nil then
			optionalTable[key] = value
		end
	end

	return optionalTable :: Bullet.EasyBulletSettings
end

local function overrideDefaults(newEasyBulletSettings: Bullet.EasyBulletSettings | {})
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

	for key, value in pairs(newEasyBulletSettings) do
		if defaultSettings[key] == nil then
			warn(`{key} does not exist in type EasyBulletSettings`)
			continue
		end

		if key == "BulletData" then
			for dataKey, _ in pairs(value) do
				assert(dataKey ~= "HitVelocity", `Cannot use key "HitVelocity" in provided BulletData table. "HitVelocity" is a reserved key string used by EasyBullet`)
			end
		end

		defaultSettings[key] = value
	end

	return defaultSettings
end

local constructedEasyBullet

local EasyBullet = {}
EasyBullet.__index = EasyBullet

export type EasyBullet = typeof(setmetatable({} :: EasyBulletProps,  EasyBullet))

function EasyBullet.new(easyBulletSettings: Bullet.EasyBulletSettings?)
	if constructedEasyBullet then
		return constructedEasyBullet
	end

	local self = setmetatable({} :: EasyBulletProps, EasyBullet)

	self.EasyBulletSettings = overrideDefaults(easyBulletSettings or {})

	self.BulletHit = Signal.new()
	self.BulletHitHumanoid = Signal.new()
	self.BulletUpdated = Signal.new()

	self.Bullets = {} :: {[number]: Bullet.Bullet}

	self.FiredRemote = nil
	self.CustomCastCallback = nil

	self:_bindEvents()

	constructedEasyBullet = self

	return self
end

function EasyBullet:FireBullet(barrelPosition: Vector3, bulletVelocity: Vector3, easyBulletSettings: Bullet.EasyBulletSettings?)
	assert(barrelPosition, `EasyBullet:FireBullet requires 2 parameters: a Vector3 position to start the bullet from, and a Velocity Vector3 of the direction to fire the bullet, with a magnitude of the initial velocity`)
	assert(bulletVelocity, `EasyBullet:FireBullet requires 2 parameters: a Vector3 position to start the bullet from, and a Velocity Vector3 of the direction to fire the bullet, with a magnitude of the initial velocity`)
	
	assert(typeof(barrelPosition) == "Vector3", "The first parameter to EasyBullet:FireBullet must be a Vector3")
	assert(typeof(bulletVelocity) == "Vector3", "The second parameter to EasyBullet:FireBullet must be a Vector3")
	
	easyBulletSettings = optionalTableMerge(easyBulletSettings or {} :: Bullet.EasyBulletSettings, self.EasyBulletSettings)

	-- Server; only used for non player bullets.
	if RunService:IsServer() then
		for _, v in ipairs(Players:GetPlayers()) do
			local thisPing = v:GetNetworkPing()
			self.FiredRemote:FireClient(v, nil, barrelPosition, bulletVelocity, thisPing, easyBulletSettings)
		end

		self:_fireBullet(nil, barrelPosition, bulletVelocity, 0, easyBulletSettings)
	-- Client
	elseif RunService:IsClient() then
		if not self.FiredRemote then
			warn("EasyBullet Remote Event doesn't exist. Did you forget to call EasyBullet.new() on the server?")
			return
		end

		self.FiredRemote:FireServer(barrelPosition, bulletVelocity, easyBulletSettings)

		self:_fireBullet(Players.LocalPlayer, barrelPosition, bulletVelocity, 0, easyBulletSettings)
	end
end

function EasyBullet:BindCustomCast(callback: Bullet.CastCallback)
	self.CustomCastCallback = callback
end

function EasyBullet:_destroyBullet(bullet: Bullet.Bullet)
	for i, v: Bullet.Bullet in ipairs(self.Bullets) do
		if v == bullet then
			table.remove(self.Bullets, i)
			break
		end
	end

	bullet:Destroy()
end

function EasyBullet._fireBullet(self: EasyBullet, shootingPlayer: Player?, barrelPos: Vector3, velocity: Vector3, ping: number, easyBulletSettings: Bullet.EasyBulletSettings)
	
	local bullet = Bullet.new(shootingPlayer, barrelPos, velocity, easyBulletSettings)
		
		local hitConnection, belowFallenParts

		hitConnection = bullet.BulletHit:Connect(function(rayResult: RaycastResult, hitHumanoid: Humanoid | boolean)
			self.BulletHit:Fire(shootingPlayer, rayResult, easyBulletSettings.BulletData)

			if type(hitHumanoid) ~= "boolean" then
				self.BulletHitHumanoid:Fire(shootingPlayer, rayResult, hitHumanoid, easyBulletSettings.BulletData)
			end

			hitConnection:Disconnect()
			belowFallenParts:Disconnect()

			self:_destroyBullet(bullet)
		end)

		belowFallenParts = bullet.BelowFallenParts:Connect(function()
			hitConnection:Disconnect()
			belowFallenParts:Disconnect()

			self:_destroyBullet(bullet)
		end)

		bullet:Start(ping)

		table.insert(self.Bullets, bullet)
end

function EasyBullet:_bindEvents()
	-- Server
	if RunService:IsServer() then
		local firedRemote = ReplicatedStorage:FindFirstChild("EasyBulletFired") :: RemoteEvent

		if not firedRemote then
			self.FiredRemote = Instance.new("RemoteEvent")

			if self.FiredRemote then
				self.FiredRemote.Name = "EasyBulletFired"
				self.FiredRemote.Parent = ReplicatedStorage
			end
		else
			self.FiredRemote = firedRemote
		end

		if not self.FiredRemote then
			return
		end

		self.FiredRemote.OnServerEvent:Connect(function(player: Player, barrelPos: Vector3, velocity: Vector3, easyBulletSettings: Bullet.EasyBulletSettings)
			if typeof(barrelPos) ~= "Vector3" then
				warn(`{player.Name} passed a malformed barrelPosition type to EasyBulletFired RemoteEvent\nExpected: Vector3, got: {typeof(barrelPos)}`)
				return
			end

			if typeof(velocity) ~= "Vector3" then
				warn(`{player.Name} passed a malformed velocity type to EasyBulletFired RemoteEvent\nExpected: Vector3, got: {typeof(velocity)}`)
				return
			end

			local ping = player:GetNetworkPing()

			for _, v in ipairs(Players:GetPlayers()) do
				if v == player then continue end
				
				local thisPing = v:GetNetworkPing()

				self.FiredRemote:FireClient(v, player, barrelPos, velocity, ping + thisPing, easyBulletSettings)
			end

			self:_fireBullet(player, barrelPos, velocity, ping, easyBulletSettings)
		end)

	-- Client
	elseif RunService:IsClient() then
		self.FiredRemote = ReplicatedStorage:WaitForChild("EasyBulletFired") :: RemoteEvent

		if not self.FiredRemote then
			warn("No RemoteEvent named 'EasyBulletFired' found as a child of ReplicatedStorage")
			return
		end
		

		self.FiredRemote.OnClientEvent:Connect(function(shootingPlayer: Player, barrelPos: Vector3, velocity: Vector3, accumulatedPing: number, easyBulletSettings: Bullet.EasyBulletSettings)
			if shootingPlayer == Players.LocalPlayer then
				return
			end
			
			self:_fireBullet(shootingPlayer, barrelPos, velocity, accumulatedPing, easyBulletSettings)
		end)
	end

	-- Both
	RunService.Heartbeat:Connect(function()
		for _, bullet: Bullet.Bullet in ipairs(self.Bullets) do
			local lastPosition, currentPosition = bullet:Update(self.CustomCastCallback)

			-- Update returns nil when bullet drops below workspace.FallenPartsDestroyHeight
			if lastPosition and currentPosition then
				self.BulletUpdated:Fire(lastPosition, currentPosition, bullet.EasyBulletSettings.BulletData)
			end
		end
	end)
end

return EasyBullet