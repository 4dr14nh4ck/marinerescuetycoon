local M = {}

function M.findDeck()
	local pier = workspace:FindFirstChild("Pier")
	return pier and pier:FindFirstChild("Deck") or nil
end

function M.makePart(parent,size,cf,mat,color,anch,coll,name,transp)
	local p = Instance.new("Part")
	p.Size=size; p.CFrame=cf; p.Anchored=anch; p.CanCollide=coll
	p.Material=mat; p.Color=color or Color3.new(1,1,1); p.Name=name or "Part"
	p.Transparency = transp or 0
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow=false; p.Parent=parent; return p
end

function M.makePath(parent,centerCF,size,name)
	return M.makePart(parent,size,centerCF,Enum.Material.WoodPlanks,Color3.fromRGB(163,118,73),true,true,name or "Path")
end

function M.glass(parent,size,cf,name)
	local g = M.makePart(parent,size,cf,Enum.Material.Glass,Color3.fromRGB(170,230,255),true,true,name or "Glass",0.2)
	return g
end

return M