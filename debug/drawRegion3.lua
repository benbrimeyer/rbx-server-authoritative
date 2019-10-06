local Debris = game:GetService("Debris")

return function(region, Life, Color, Parent, Size)
	--- Draw's a ray out (for debugging)
	-- Credit to Cirrus for initial code.
	Life = Life or 2

	local boxHandle = Instance.new("BoxHandleAdornment", workspace.Terrain)
	boxHandle.Adornee = workspace.Terrain
	boxHandle.Size = region.Size
	boxHandle.CFrame = region.CFrame
	boxHandle.Transparency = 0.5
	Debris:AddItem(boxHandle, Life)

	return boxHandle
end