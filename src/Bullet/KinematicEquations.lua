--!strict

-- COPYRIGHT 2023 Zach Curtis
-- Distrubted under the MIT License

local KinematicEquations = {}

function KinematicEquations:GetDisplacementFromTime(initialVelocity: Vector3, acceleration: Vector3, time: number): Vector3
    local vi = initialVelocity
    local a = acceleration
    local t = time

    return vi * t + .5 * a * math.pow(t, 2)
end

function KinematicEquations:GetDisplacementFromFinalVelocity(initialVelocity: Vector3, finalVelocity: Vector3, time: number): Vector3
    local vi = initialVelocity
    local vf = finalVelocity
    local t = time

    return ((vi + vf) / 2) * t
end

function KinematicEquations:GetFinalVelocityFromTime(initialVelocity: Vector3, acceleration: Vector3, time: number): Vector3
    local vi = initialVelocity
    local a = acceleration
    local t = time

    return vi + a * t
end

function KinematicEquations:GetFinalVelocityFromDisplacement(initialVelocity: Vector3, acceleration: Vector3, displacement: Vector3): Vector3
    local vi = initialVelocity
    local a = acceleration
    local d = displacement

    local squaredVF = Vector3.new(vi.X^2, vi.Y^2, vi.Z^2) + 2 * a * d

    return Vector3.new(math.sqrt(squaredVF.X), math.sqrt(squaredVF.Y), math.sqrt(squaredVF.Z))
end

return KinematicEquations