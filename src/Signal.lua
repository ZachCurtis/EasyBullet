--!strict

-- closure scoping reimplement of https://github.com/LPGhatguy/lemur/blob/master/lib/Signal.lua
-- does not defer events

type SignalCallback = (...unknown) -> ()

type SignalConnection = {
	Disconnect: (self: SignalConnection) -> ()
}

type Signal = {
	Fire: (self: Signal, ...unknown) -> (),
	Destroy: (self: Signal) -> (),
	Connect: (self: Signal, callback: SignalCallback) -> (SignalConnection)
}

export type SignalConstructor = {
	new: () -> Signal,
}

local Signal = {}

local function listInsert(list, callback)
	local newList = {}
	local listLen = #list
		
	for i = 1, listLen do
		newList[i] = list[i]
	end

	table.insert(newList, callback)
		
	return newList
end
	
local function listValueRemove(list, value)
	local newList = {}

	for i = 1, #list do
		if list[i] ~= value then
			table.insert(newList, list[i])
		end
	end
		
	return newList
end

function Signal.new(): Signal
	local signal = {} :: Signal
	
	local boundCallbacks = {}
	
	function signal:Connect(callback: SignalCallback): SignalConnection

		boundCallbacks = listInsert(boundCallbacks, callback)

		local SignalConnection = {} :: SignalConnection

        function SignalConnection.Disconnect()
            boundCallbacks = listValueRemove(boundCallbacks, callback)
        end
		
		return SignalConnection
	end
	
	--#region fire
	function signal:Fire(...)

		for _, callback in ipairs(boundCallbacks) do
            task.spawn(callback, ...)
		end
	end
	--#endregion
	
	function signal:Destroy()
		boundCallbacks = {}
	end

	return signal
end

return Signal :: SignalConstructor