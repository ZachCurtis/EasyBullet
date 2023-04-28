local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Bullet = require(script:WaitForChild("Bullet"))
local Signal = require(script:WaitForChild("Signal"))

export type EasyBulletSettings = {
	Gravity: boolean?,
	RenderBullet: boolean?,
	BulletColor: Color3?,
	BulletThickness: number?
}

local function overrideDefaults(newEasyBulletSettings: EasyBulletSettings)
	local defaultSettings = {
		Gravity = true,
		RenderBullet = true,
		BulletColor = Color3.new(0.945098, 0.490196, 0.062745),
		BulletThickness = .1
	}

	for key, value in pairs(newEasyBulletSettings) do
		if defaultSettings[key] == nil then
			warn(`{key} does not exist in type EasyBulletSettings`)
			continue
		end

		defaultSettings[key] = value
	end

	return defaultSettings
end

local hasConstructed = false

local EasyBullet = {}
EasyBullet.__index = EasyBullet

function EasyBullet.new(easyBulletSettings)
	if hasConstructed then
		error("Only call EasyBullet.new() once per environment")
	end

	hasConstructed = true

	local self = setmetatable({}, EasyBullet)

	self.EasyBulletSettings = overrideDefaults(easyBulletSettings or {})

	self.BulletHit = Signal.new()
	self.BulletHitHumanoid = Signal.new()

	self.Bullets = {}

	self.FiredRemote = nil

	self:_bindEvents()

	return self
end

function EasyBullet:FireBullet(barrelPosition: Vector3, bulletVelocity: Vector3, easyBulletSettings: EasyBulletSettings?)
	-- Server; only used for non player bullets.
	if RunService:IsServer() then
		for _, v in ipairs(Players:GetPlayers()) do
			local thisPing = v:GetNetworkPing()
			self.FiredRemote:FireClient(v, nil, barrelPosition, bulletVelocity, thisPing, easyBulletSettings)
		end

		self:_fireBullet(nil, barrelPosition, bulletVelocity, 0)
	-- Client
	elseif RunService:IsClient() then
		if not self.FiredRemote then
			warn("EasyBullet Remote Event doesn't exist. Did you forget to call EasyBullet.new() on the server?")
			return
		end

		self.FiredRemote:FireServer(barrelPosition, bulletVelocity)

		self:_fireBullet(Players.LocalPlayer, barrelPosition, bulletVelocity, 0)
	end
end

function EasyBullet:_destroyBullet(bullet)
	for i, v in ipairs(self.Bullets) do
		if v == bullet then
			table.remove(self.Bullets, i)
			break
		end
	end

	bullet:Destroy()
end

function EasyBullet:_fireBullet(shootingPlayer: Player, barrelPos: Vector3, velocity: Vector3, ping: number, easyBulletSettings: EasyBulletSettings?)
	local bullet = Bullet.new(barrelPos, velocity, easyBulletSettings or self.EasyBulletSettings)
		
		local hitConnection, belowFallenParts

		hitConnection = bullet.BulletHit:Connect(function(rayResult: RaycastResult, hitHumanoid: Humanoid | boolean)
			self.BulletHit:Fire(shootingPlayer, rayResult)

			if hitHumanoid then
				self.BulletHitHumanoid:Fire(shootingPlayer, rayResult, hitHumanoid)
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
		self.FiredRemote = ReplicatedStorage:FindFirstChild("EasyBulletFired") :: RemoteEvent

		if not self.FiredRemote then
			self.FiredRemote = Instance.new("RemoteEvent")
			self.FiredRemote.Name = "EasyBulletFired"
			self.FiredRemote.Parent = ReplicatedStorage
		end

		self.FiredRemote.OnServerEvent:Connect(function(player: Player, barrelPos: Vector3, velocity: Vector3)
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

				self.FiredRemote:FireClient(v, player, barrelPos, velocity, ping + thisPing)
			end

			self:_fireBullet(player, barrelPos, velocity, ping)
		end)

	-- Client
	elseif RunService:IsClient() then
		self.FiredRemote = ReplicatedStorage:WaitForChild("EasyBulletFired") :: RemoteEvent

		self.FiredRemote.OnClientEvent:Connect(function(shootingPlayer: Player, barrelPos: Vector3, velocity: Vector3, accumulatedPing: number, easyBulletSettings: EasyBulletSettings)
			if shootingPlayer == Players.LocalPlayer then
				return
			end
			
			self:_fireBullet(shootingPlayer, barrelPos, velocity, accumulatedPing, easyBulletSettings)
		end)
	end

	RunService.Heartbeat:Connect(function()
		for _, bullet in ipairs(self.Bullets) do
			bullet:Update()
		end
	end)
end

return EasyBullet