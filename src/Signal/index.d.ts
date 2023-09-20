export class Connection {
	Disconnect(): void
}

export class Signal<T extends Callback = Callback> {
	constructor()

	Fire(...args: Parameters<T>): void
	Connect(handler: T): Connection
	Destroy(): void
}
