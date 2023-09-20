import { Signal } from "./Signal"

type BulletDataKey = "HitVelocity" | "BulletId"

type BulletData = { [key: BulletDataKey | string]: unknown }

type CastCallback = (
	shootingPlayer: Player | undefined,
	lastFramePosition: Vector3,
	thisFramePosition: Vector3,
	elapsedTime: number,
	bulletData: BulletData,
) => RaycastResult | undefined

type ShouldFireCallback = (
	shooter: Player | undefined,
	barrelPosition: Vector3,
	velocity: Vector3,
	ping: number,
	easyBulletSettings: EasyBulletSettings | undefined,
) => boolean

interface EasyBulletSettings {
	Gravity: boolean
	RenderBullet: boolean
	BulletColor: Color3
	BulletThickness: number
	FilterList: Instance[]
	FilterType: Enum.RaycastFilterType
	BulletPartProps: { [key: string]: unknown }
	BulletData: BulletData
}

interface EasyBullet {
	BulletHit: Signal<(player: Player | undefined, rayResult: RaycastResult, bulletData: BulletData) => void>
	BulletHitHumanoid: Signal<
		(player: Player | undefined, rayResult: RaycastResult, hitHumanoid: Humanoid, bulletData: BulletData) => void
	>
	BulletUpdated: Signal<(lastPosition: Vector3, currentPosition: Vector3, bulletData: BulletData) => void>

	FireBullet: (barrelPosition: Vector3, bulletVelocity: Vector3, easyBulletSettings: EasyBulletSettings) => void
	BindCustomCast: (callback: CastCallback) => void
	BindShouldFire: (callback: ShouldFireCallback) => void
}

declare const EasyBullet: EasyBullet

export = EasyBullet
