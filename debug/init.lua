local returnTable = {}
for _, object in ipairs(script:GetChildren()) do
	returnTable[object.Name] = require(object)
end

return returnTable