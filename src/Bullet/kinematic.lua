--!strict
local function kinematic(initialVelocity: Vector3, acceleration: Vector3, time: number): Vector3
    local vi = initialVelocity
    local a = acceleration
    local t = time

    return vi * t + .5 * a * math.pow(t, 2)
end

return kinematic