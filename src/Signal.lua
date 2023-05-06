--!strict

-- closure scoping reimplement of https://github.com/LPGhatguy/lemur/blob/master/lib/Signal.lua
-- does not defer events

type SignalConnection = {
	Disconnect: (self: SignalConnection) -> ()
}

export type Signal<T...> = {
	Fire: (self: Signal<T...>, T...) -> (),
	Destroy: (self: Signal<T...>) -> (),
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> (SignalConnection)
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

function Signal.new<T...>(): Signal<T...>
	local signal = {} :: Signal<T...>
	
	local boundCallbacks = {}
	
	function signal:Connect(callback: (T...) -> ()): SignalConnection

		boundCallbacks = listInsert(boundCallbacks, callback)

		local SignalConnection = {} :: SignalConnection

        function SignalConnection.Disconnect()
            boundCallbacks = listValueRemove(boundCallbacks, callback)
        end
		
		return SignalConnection
	end
	
	function signal:Fire(...: T...)

		for _, callback in ipairs(boundCallbacks) do
			task.spawn(callback, ...)
		end
	end
	
	function signal:Destroy()
		boundCallbacks = {}
	end

	return signal
end

return Signal
