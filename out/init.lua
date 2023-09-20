--!strict

-- COPYRIGHT 2023 Zach Curtis
-- Distrubted under the MIT License
-- VERSION 1.0.0

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Bullet = require(script:WaitForChild("Bullet"))
local Signal = require(script:WaitForChild("Signal"))

export type ShouldFireCallback = (shooter: Player?, barrelPosition: Vector3, velocity: Vector3, ping: number, easyBulletSettings: Bullet.EasyBulletSettings?) -> boolean

type EasyBulletProps = {
	EasyBulletSettings: Bullet.EasyBulletSettings,

	BulletHit: Signal.Signal<Player?, RaycastResult, Bullet.BulletData>,
	BulletHitHumanoid: Signal.Signal<Player?, RaycastResult, Humanoid, Bullet.BulletData>,
	BulletUpdated: Signal.Signal<Vector3, Vector3, Bullet.BulletData>,

	Bullets: {[string]: Bullet.Bullet},
	HitConnections: {[string]: Signal.SignalConnection},
	BelowFallenPartsConnections: {[string]: Signal.SignalConnection},

	FiredRemote: RemoteEvent?,
	CanceledRemote: RemoteEvent?,

	CustomCastCallback: Bullet.CastCallback?, --(Player?, Vector3, Vector3, number, Bullet.BulletData) -> ()?,
	ShouldFireCallback: ShouldFireCallback?
}

type EasyBulletMethods = {
	FireBullet: (self: EasyBullet, barrelPosition: Vector3, bulletVelocity: Vector3, easyBulletSettings: Bullet.EasyBulletSettings?) -> (),
	BindCustomCast: (self: EasyBullet, callback: Bullet.CastCallback) -> (),
	BindShouldFire: (self: EasyBullet, callback: ShouldFireCallback) -> (),
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
				assert(dataKey ~= "BulletId", `Cannot use key "BulletId" in provided BulletData table. "BulletId" is a reserved key string used by EasyBullet`)
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

	self.Bullets = {} :: {[string]: Bullet.Bullet}
	self.HitConnections = {} :: {[string]: Signal.SignalConnection}
	self.BelowFallenPartsConnections = {} :: {[string]: Signal.SignalConnection}

	self.FiredRemote = nil
	self.CanceledRemote = nil

	self.CustomCastCallback = nil
	self.ShouldFireCallback = nil

	self:_bindEvents()

	constructedEasyBullet = self

	return self
end

function EasyBullet:FireBullet(barrelPosition: Vector3, bulletVelocity: Vector3, easyBulletSettings: Bullet.EasyBulletSettings?)
	assert(barrelPosition, `EasyBullet:FireBullet requires 2 parameters: a Vector3 position to start the bullet from, and a Velocity Vector3 of the direction to fire the bullet, with a magnitude of the initial velocity`)
	assert(bulletVelocity, `EasyBullet:FireBullet requires 2 parameters: a Vector3 position to start the bullet from, and a Velocity Vector3 of the direction to fire the bullet, with a magnitude of the initial velocity`)
	
	assert(typeof(barrelPosition) == "Vector3", "The first parameter to EasyBullet:FireBullet must be a Vector3")
	assert(typeof(bulletVelocity) == "Vector3", "The second parameter to EasyBullet:FireBullet must be a Vector3")

	local thisEasyBulletSettings = optionalTableMerge(easyBulletSettings or {} :: Bullet.EasyBulletSettings, self.EasyBulletSettings)

	-- Create a UUID linked to this bullet so it can be referenced over the network later
	local bulletId = HttpService:GenerateGUID()

	thisEasyBulletSettings.BulletData.BulletId = bulletId

	-- Server; only used for non player bullets.
	if RunService:IsServer() then
		for _, v in ipairs(Players:GetPlayers()) do
			local thisPing = v:GetNetworkPing()
			self.FiredRemote:FireClient(v, nil, barrelPosition, bulletVelocity, thisPing, thisEasyBulletSettings)
		end

		self:_fireBullet(nil, barrelPosition, bulletVelocity, 0, thisEasyBulletSettings)
	
	-- Client
	elseif RunService:IsClient() then
		if not self.FiredRemote then
			warn("EasyBullet Remote Event doesn't exist. Did you forget to call EasyBullet.new() on the server?")
			return
		end

		self.FiredRemote:FireServer(barrelPosition, bulletVelocity, thisEasyBulletSettings)

		self:_fireBullet(Players.LocalPlayer, barrelPosition, bulletVelocity, 0, thisEasyBulletSettings)
	end
end

function EasyBullet:BindCustomCast(callback: Bullet.CastCallback)
	assert(typeof(callback) == "function", `The callback passed to EasyBullet:BindCustomCast must be a function. Passed type is {typeof(callback)}`)

	self.CustomCastCallback = callback
end

function EasyBullet:BindShouldFire(callback: ShouldFireCallback)
	assert(typeof(callback) == "function", `The callback passed to EasyBullet:BindShouldFire must be a function. Passed type is {typeof(callback)}`)

	self.ShouldFireCallback = callback
end

function EasyBullet:_destroyBullet(bulletToDestroy: Bullet.Bullet | string)
	local bulletId: string
	local bullet: Bullet.Bullet

	if type(bulletToDestroy) == "string" then
		bulletId = bulletToDestroy
		bullet = self.Bullets[bulletId]
	else
		local tryBulletId = bulletToDestroy.EasyBulletSettings.BulletData.BulletId
		assert(type(tryBulletId) == "string", "Cannot destroy bullet as EasyBullet did not assign a BulletId for this bullet.")
		
		bulletId = tryBulletId
		bullet = bulletToDestroy
	end

	self.Bullets[bulletId] = nil

	if self.HitConnections[bulletId] ~= nil then
		self.HitConnections[bulletId].Disconnect()

		self.HitConnections[bulletId] = nil
	end

	if self.BelowFallenPartsConnections[bulletId] ~= nil then
		self.BelowFallenPartsConnections[bulletId].Disconnect()

		self.BelowFallenPartsConnections[bulletId] = nil
	end

	-- Obscure bug most likely caused by external library caused this to nil member error
	if bullet then
		bullet:Destroy()
	end
end

function EasyBullet._fireBullet(self: EasyBullet, shootingPlayer: Player?, barrelPos: Vector3, velocity: Vector3, ping: number, easyBulletSettings: Bullet.EasyBulletSettings)

	local bulletId = easyBulletSettings.BulletData.BulletId
	assert(type(bulletId) == "string", "EasyBullet did not assign a BulletId for this bullet.")
	
	-- Let users filter bullets being fired
	if self.ShouldFireCallback then
		local shouldFire = self.ShouldFireCallback(shootingPlayer, barrelPos, velocity, ping, easyBulletSettings)
		
		assert(type(shouldFire) == "boolean", `The callback bound by EasyBullet:BindShouldFire must return a boolean, shouldFireCallback returned: {typeof(shouldFire)}`)
		
		if shouldFire == false then
			
			assert(self.CanceledRemote ~= nil, "self.CanceledRemote does not reference ReplicatedStorage.EasyBulletCanceled")

			if RunService:IsServer() then
				self.CanceledRemote:FireAllClients(bulletId)
			elseif RunService:IsClient() then
				self.CanceledRemote:FireServer(bulletId)
			end

			return
		end
	end

	local bullet = Bullet.new(shootingPlayer, barrelPos, velocity, easyBulletSettings)

	self.HitConnections[bulletId] = bullet.BulletHit:Connect(function(rayResult: RaycastResult, hitHumanoid: Humanoid | boolean)
		self.BulletHit:Fire(shootingPlayer, rayResult, easyBulletSettings.BulletData)

		if type(hitHumanoid) ~= "boolean" then
			self.BulletHitHumanoid:Fire(shootingPlayer, rayResult, hitHumanoid, easyBulletSettings.BulletData)
		end

		self:_destroyBullet(bullet)
	end)

	self.BelowFallenPartsConnections[bulletId] = bullet.BelowFallenParts:Connect(function()
		self:_destroyBullet(bullet)
	end)

	bullet:Start(ping)

	self.Bullets[bulletId] = bullet
end

function EasyBullet:_bindEvents()
	-- Server
	if RunService:IsServer() then

		-- Look for existing EasyBulletFired RemoteEvent. Create one if it does not exist.
		self.FiredRemote = self:_findOrCreateRemote("EasyBulletFired")
		assert(self.FiredRemote ~= nil, "self.FiredRemote cannot be nil.")

		self.FiredRemote.OnServerEvent:Connect(function(player: Player, barrelPos: Vector3, velocity: Vector3, easyBulletSettings: Bullet.EasyBulletSettings)
			-- Sanity check params
			if typeof(barrelPos) ~= "Vector3" then
				warn(`{player.Name} passed a malformed barrelPosition type to EasyBulletFired RemoteEvent\nExpected: Vector3, got: {typeof(barrelPos)}`)
				return
			end

			if typeof(velocity) ~= "Vector3" then
				warn(`{player.Name} passed a malformed velocity type to EasyBulletFired RemoteEvent\nExpected: Vector3, got: {typeof(velocity)}`)
				return
			end

			-- Use shooter's ping to account for network desync.
			local ping = player:GetNetworkPing()

			-- Replicate shot to all other clients
			for _, v in ipairs(Players:GetPlayers()) do
				if v == player then continue end
				
				local thisPing = v:GetNetworkPing()

				self.FiredRemote:FireClient(v, player, barrelPos, velocity, ping + thisPing, easyBulletSettings)
			end

			-- Start handling the shot on the server
			self:_fireBullet(player, barrelPos, velocity, ping, easyBulletSettings)
		end)

		-- Look for existing EasyBulletCanceled RemoteEvent. Create one if it does not exist.
		self.CanceledRemote = self:_findOrCreateRemote("EasyBulletCanceled")
		assert(self.CanceledRemote ~= nil, "self.CanceledRemote cannot be nil.")

		-- Handle the CanceledRemote
		self.CanceledRemote.OnServerEvent:Connect(function(cancelingPlayer: Player, bulletId: string)
			local bullet = self.Bullets[bulletId]

			if not bullet then
				warn(`No Bullet with a BulletId of {bulletId} was found`)
				return
			end

			if not bullet.Shooter then
				warn(`{cancelingPlayer.Name} cannot cancel a bullet owned by the server. BulletId: {bulletId}`)
				return
			end

			if bullet.Shooter and bullet.Shooter ~= cancelingPlayer then
				warn(`{cancelingPlayer.Name} cannot cancel a bullet owned by {bullet.Shooter.Name}. BulletId: {bulletId}`)
				return
			end

			self:_destroyBullet(bulletId)
		end)


	-- Client
	elseif RunService:IsClient() then
		-- Make references to our remotes
		self.FiredRemote = ReplicatedStorage:WaitForChild("EasyBulletFired") :: RemoteEvent
		self.CanceledRemote = ReplicatedStorage:WaitForChild(("EasyBulletCanceled")) :: RemoteEvent

		if not self.FiredRemote then
			warn("No RemoteEvent named 'EasyBulletFired' found as a child of ReplicatedStorage")
			return
		end

		if not self.CanceledRemote then
			warn("No RemoteEvent named 'EasyBulletCanceled' found as a child of ReplicatedStorage")
			return
		end
		
		-- Handle the FiredRemote
		self.FiredRemote.OnClientEvent:Connect(function(shootingPlayer: Player, barrelPos: Vector3, velocity: Vector3, accumulatedPing: number, easyBulletSettings: Bullet.EasyBulletSettings)
			-- The server shouldn't ever replicate back a shot this client fired, but check that just to be safe.
			if shootingPlayer == Players.LocalPlayer then
				return
			end
			
			self:_fireBullet(shootingPlayer, barrelPos, velocity, accumulatedPing, easyBulletSettings)
		end)

		-- Handle the CanceledRemote
		self.CanceledRemote.OnClientEvent:Connect(function(bulletId: string)
			self:_destroyBullet(bulletId)
		end)

	end

	-- Both
	RunService.Heartbeat:Connect(function()
		for _, bullet: Bullet.Bullet in pairs(self.Bullets) do
			local lastPosition, currentPosition = bullet:Update(self.CustomCastCallback)

			-- Update returns nil when bullet drops below workspace.FallenPartsDestroyHeight
			if lastPosition and currentPosition then
				self.BulletUpdated:Fire(lastPosition, currentPosition, bullet.EasyBulletSettings.BulletData)
			end
		end
	end)
end

function EasyBullet:_findOrCreateRemote(remoteName: string): RemoteEvent
	local foundRemote = ReplicatedStorage:FindFirstChild(remoteName)

	if foundRemote == nil then
		foundRemote = Instance.new("RemoteEvent")
		foundRemote.Name = remoteName
		foundRemote.Parent = ReplicatedStorage

		return foundRemote
	elseif foundRemote:IsA("RemoteEvent") then
		return foundRemote
	else
		error(`Instance named {remoteName} is of type {foundRemote.ClassName}, not RemoteEvent`)
	end
end

return EasyBullet