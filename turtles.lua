-- Heavily modified form of the Excavate turtle built-in program, made for making large holes at a certain layer underground
-- Created by StarNinga

local name = os.getComputerLabel()
if name == nil then
	name = "miner"..math.random(0, 1000)
	os.setComputerLabel(name) -- change this to being assigned by the central computer once the rednet system is in place
end

-- not fully configurable yet, as the fueling system assumes it requires a maximum of 2 coal to go to the chest and back
local mineWidth = 20
local mineLength = 40

local unloaded = 0
local collected = 0

local xPos,zPos = 0,0
local xDir,zDir = 0,1

-- Filled in further down:
local goTo 
local turnRight
local turnLeft
local tryForwards

local function unload( _KeepOneFuelStack )
	print( name.." is unloading items..." )
	for n=1,16 do
		local nCount = turtle.getItemCount(n)
		if nCount > 0 then
			turtle.select(n)
			local bDrop = true
			if _KeepOneFuelStack then
				bDrop = false
				_KeepOneFuelStack = false
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

	unload( true )

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

local function tryForwards()
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel <= 1 then
		local selected = turtle.getSelectedSlot()
		turtle.select(1)
		turtle.refuel(1)
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

	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel <= 121 then
		local selected = turtle.getSelectedSlot()
		turtle.select(1)
		turtle.refuel(2)
		turtle.select(selected)
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

	while zDir ~= zd or xDir ~= xd do
		turnLeft()
	end
end

-- What is actually executed --

local fuelLevel = turtle.getFuelLevel()
local fuelReady = turtle.getItemCount(1)
if (fuelLevel + fuelReady * 80) > (mineWidth * mineLength + (mineWidth * mineLength * 3) / 64) * (mineWidth+mineLength) then
	print( "Starting..." )
	local alternate = 0
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
	end
	print( name.." returning to base..." )

	-- Return to where we started
	goTo( 0,0,0,-1 )
	unload( false )
	goTo( 0,0,0,1 )

	print( "Mined "..(collected + unloaded).." items total." )
else
	print("Not enough fuel to start. (Add a minimum of 39 coal in the first slot)")
end