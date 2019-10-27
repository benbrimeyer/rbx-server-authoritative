local CAST_RAY = workspace.FindPartOnRayWithIgnoreList

local debug = require(game.ReplicatedStorage.Packages.debug)

local AIR_FRICTION = 0.05

local WALK_HEIGHT = 2.0

---

-- object space offsets to base floor casting from (magnitude matters)
local FLOOR_CAST_OFFSET_VECTORS = {
	Vector3.new(0, 0, 0),
	Vector3.new(1, 0, 0.5),
	Vector3.new(1, 0, -0.5),
	Vector3.new(-1, 0, 0.5),
	Vector3.new(-1, 0, -0.5),
}

local IGNORE_LIST = {}

-- default is incase of something???
local function normalize(vec)
	local default = Vector3.new()
	local unit = vec.unit

	if unit.X ~= unit.X then --NANANANANANANNANAN
		return default
	else
		return unit
	end
end

-- parses list, returns the thing that it encounters the most
local function findMostOccurring(list, earlyQuit)
	earlyQuit = earlyQuit or math.huge

	local object;

	for part, count in next, list do
		if count == earlyQuit then
			object = part
			break
		elseif list[object or part] >= count then
			object = part
		end
	end

	return object
end

local function castRay(origin, direction, recursive)
	local ray = recursive or Ray.new(origin, direction)
	local hit, pos, norm = CAST_RAY(workspace, ray, IGNORE_LIST)

	debug.drawRay(ray)
	--print("origin", origin)
	if hit and not hit.CanCollide then
		table.insert(IGNORE_LIST, hit)
		return castRay(origin, direction, ray)
	end

	return hit, pos, norm
end

local function getGround(position, direction)
	local impactList = {}
	local ground;

	local normal = Vector3.new()
	local finalPosition = Vector3.new()
	local velocity = Vector3.new()
	local friction = 0
	local hitCount = 0

	local originCF = CFrame.new(position, direction.magnitude > 0 and (position + direction) or Vector3.new())

	for _, vector in next, FLOOR_CAST_OFFSET_VECTORS do
		local origin = originCF:pointToWorldSpace(vector)
		local hit, pos, norm = castRay(origin, Vector3.new(0, -WALK_HEIGHT * 2, 0))

		if hit then
			impactList[hit] = (impactList[hit] or 0) + 1
			velocity = velocity + hit.Velocity
			friction = friction + hit.Friction

			finalPosition = finalPosition + pos
			normal = normal + norm

			hitCount = hitCount + 1
		end
	end

	ground = findMostOccurring(impactList, #FLOOR_CAST_OFFSET_VECTORS)
	friction = hitCount == 0 and AIR_FRICTION or friction / math.max(hitCount, 1)
	velocity = hitCount == 0 and Vector3.new() or velocity / math.max(hitCount, 1)
	finalPosition = finalPosition/math.max(hitCount, 1)

	return ground, finalPosition, normalize(normal), velocity, friction
end

return getGround