local Debris = game:GetService("Debris")

return function(Position, Life, Color, Parent, Size)
	--- Draw's a ray out (for debugging)
	-- Credit to Cirrus for initial code.
	Life = Life or 2

	Parent = Parent or workspace.Terrain

	local NewPart = Instance.new("SphereHandleAdornment", Parent)

	NewPart.Adornee = workspace.Terrain
	NewPart.Radius       = Size or 0.5

	NewPart.CFrame     = CFrame.new(Position)
	NewPart.Transparency = 0.5
	NewPart.Color3 = (Color or BrickColor.new("Bright blue")).Color
	NewPart.Name = "DrawnPoint"

	Debris:AddItem(NewPart, Life)

	return NewPart
end