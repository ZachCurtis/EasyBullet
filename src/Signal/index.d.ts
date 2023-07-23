interface SignalConnection {
	/**
	 * A connected signal object. Mirrors RBXScriptConnection, but only provides a Disconnect() method.
	 */
	Disconnect: () => void
}

interface Signal {
	/**
	 * Fires the event represented by this Signal object. Calls all connected callbacks.
	 * @param args variadic arguments passed to all connected callbacks
	 */
	Fire(...args: unknown[]): void

	/**
	 * Connect a callback function to the event represented by this Signal object.
	 * @param callback Callback function that is passed the variadic arguments passed to Fire() when it is called.
	 */
	Connect(callback: (...args: unknown[]) => void): SignalConnection

	/**
	 * Disconnect all SignalConnection's currently made to the event represented by this Signal object.
	 */
	Destroy(): void
}

interface SignalConstructor {
	new (): Signal
}

declare const Signal: SignalConstructor

export = Signal
