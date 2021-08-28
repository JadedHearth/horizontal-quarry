-- Derived from the Excavate turtle built-in program, made for stripmining (computercraft)
-- Created by StarNinga

local name = os.getComputerLabel()
if type(name) == nil then
	os.setComputerLabel("miner"..math.random(0, 1000)) -- change this to being assigned by the central computer once the rednet system is in place
end

local mineWidth = 20
local mineLength = 40 -- to be removed once I get the wireless deactivation/activation in place

local unloaded = 0
local collected = 0

local xPos,zPos = 0,0
local xDir,zDir = 0,1

-- Filled in further down:
local goTo 
local refuel
local turnRight
local turnLeft
local tryForwards

local function unload( _bKeepOneFuelStack )
	print( name.." is unloading items..." )
	for n=1,16 do
		local nCount = turtle.getItemCount(n)
		if nCount > 0 then
			turtle.select(n)			
			local bDrop = true
			if _bKeepOneFuelStack and turtle.refuel(0) then
				bDrop = false
				_bKeepOneFuelStack = false
			end			
			if bDrop then
				turtle.drop()
				unloaded = unloaded + nCount
			end
		end
	end
	collected = 0
	turtle.select(1)
end

local function returnSupplies()
	local x,z,xd,zd = xPos,zPos,xDir,zDir
	print( name.." is returning to chest..." )
	goTo( 0,0,0,-1 )
	
	local fuelNeeded = 2*(x+z) + 1
	if not refuel( fuelNeeded ) then
		unload( true )
		print( name.." waiting for fuel" )
		while not refuel( fuelNeeded ) do
			os.pullEvent( "turtle_inventory" )
		end
	else
		unload( true )	
	end
	
	print( name.." is resuming mining..." )
	goTo( x,z,xd,zd )
end

local function collect()	
	local bFull = true
	local nTotalItems = 0
	for n=1,16 do
		local nCount = turtle.getItemCount(n)
		if nCount == 0 then
			bFull = false
		end
		nTotalItems = nTotalItems + nCount
	end
	
	if nTotalItems > collected then
		collected = nTotalItems
		if math.fmod(collected + unloaded, 50) == 0 then
			print( name.." mined "..(collected + unloaded).." items." )
		end
	end
	
	if bFull then
		print( name.." has no empty slots left." )
		return false
	end
	return true
end

function refuel( amount )
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" then
		return true
	end
	
	local needed = amount or (xPos + zPos + 2)
	if turtle.getFuelLevel() < needed then
		local fueled = false
		for n=1,16 do
			if turtle.getItemCount(n) > 0 then
				turtle.select(n)
				if turtle.refuel(1) then
					while turtle.getItemCount(n) > 0 and turtle.getFuelLevel() < needed do
						turtle.refuel(1)
					end
					if turtle.getFuelLevel() >= needed then
						turtle.select(1)
						return true
					end
				end
			end
		end
		turtle.select(1)
		return false
	end
	
	return true
end

local function tryForwards()
	if not refuel() then
		print( name.." doesn't have enough fuel" )
		returnSupplies()
	end
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel <= 1 then
		local selected = turtle.getSelectedSlot()
		turtle.select(1)
		turtle.refuel()
		turtle.select(selected)
	end
    turtle.digUp() 
    turtle.digDown()
	while not turtle.forward() do
		if not (turtle.attack() and turtle.attackUp() and turtle.attackDown()) then
            turtle.dig() 
			if not collect() then
				returnSupplies()
			end
		else
			sleep( 0.5 )
		end
	end

	
	xPos = xPos + xDir
	zPos = zPos + zDir
	return true
end

local function turnLeft()
	turtle.turnLeft()
	xDir, zDir = -zDir, xDir
end

local function turnRight()
	turtle.turnRight()
	xDir, zDir = zDir, -xDir
end

function goTo( x, z, xd, zd )

	local goToFuelNeeded = math.abs(xPos-x)+math.abs(zPos-z)
	if turtle.getFuelLevel() <= goToFuelNeeded then
		refuel(goToFuelNeeded)
	end

	if xPos > x then
		while xDir ~= -1 do
			turnLeft()
		end
		while xPos > x do
			if turtle.forward() then
				xPos = xPos - 1
			elseif turtle.dig() or turtle.attack() then
				collect()
			else
				sleep( 0.5 )
			end
		end
	elseif xPos < x then
		while xDir ~= 1 do
			turnLeft()
		end
		while xPos < x do
			if turtle.forward() then
				xPos = xPos + 1
			elseif turtle.dig() or turtle.attack() then
				collect()
			else
				sleep( 0.5 )
			end
		end
	end
	
	if zPos > z then
		while zDir ~= -1 do
			turnLeft()
		end
		while zPos > z do
			if turtle.forward() then
				zPos = zPos - 1
			elseif turtle.dig() or turtle.attack() then
				collect()
			else
				sleep( 0.5 )
			end
		end
	elseif zPos < z then
		while zDir ~= 1 do
			turnLeft()
		end
		while zPos < z do
			if turtle.forward() then
				zPos = zPos + 1
			elseif turtle.dig() or turtle.attack() then
				collect()
			else
				sleep( 0.5 )
			end
		end	
	end
	
	while zDir ~= zd or xDir ~= xd do
		turnLeft()
	end
end

if not refuel() then
	print( name.." is out of fuel" )
	return
end

-- Actual Excavation bit, the hard bit --

print( "Excavating..." )

local alternate = 0
local off = false

while not off do
    turnLeft()
	for n=1,mineLength do
        for r=1,mineWidth-1 do
            tryForwards()
        end
        if alternate == 0 then
            turnRight()
            tryForwards()
            turnRight()
            alternate = 1
        elseif alternate == 1 then
            turnLeft()
            tryForwards()
            turnLeft()
            alternate = 0
        end
        if off then -- to be used when I can remotely turn the miners off
			break
		end
	end
    off = true -- delete when I can remotely turn the miners off
end

print( name.."Returning to base..." )

-- Return to where we started
goTo( 0,0,0,-1 )
unload( false )
goTo( 0,0,0,1 )

print( "Mined "..(collected + unloaded).." items total." )