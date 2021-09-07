-- Turtle control program made for making large holes at a certain layer underground, and controlled remotely by a central computer
-- Created by StarNinga

local mineWidth = 20
local mineLength = 40

local unloaded = 0
local collected = 0
local xPos,zPos = 0,0
local xDir,zDir = 0,1
local stop = false
local offline = false

peripheral.find("modem", rednet.open)
local nControllerID = 0
local name = ""
if rednet.isOpen() then
	rednet.host("turtleName", ""..os.getComputerID())
	nControllerID, name = rednet.receive("turtleName")
	os.setComputerLabel( name )
else
	printError("Turtle is not connected to rednet.")
	os.setComputerLabel("Offline miner")
	name = "Offline miner"
	offline = true
end

-- Filled in further down:
local GoTo 
local turnRight
local turnLeft
local tryForwards

-- implement for refueling as well later
local function getItem( _item )
	local b
	for n=1,16 do
		local item = turtle.getItemDetail(n)
		if item == nil then
		elseif item.name == _item then
			turtle.select(n)

			break
		end
	end
end

-- currently unimplemented, I need to be able to get a 2D array of where to place torches
local function placeTorch()
	if turtle.inspectDown() == false then
		turtle.down()
		local selected = turtle.getSelectedSlot()
		local there, meta = turtle.inspectDown()
		if there and meta.state.level == nil then
			turtle.up()
			getItem("minecraft:torch")
			turtle.placeDown()
			turtle.select(selected)
		elseif there and meta.state.level ~= nil then
			there, meta = turtle.inspectUp()
			if there and meta.state.level ~= nil then
				printError("Could not place torch due to liquid present.")
				turtle.up()
			else
				getItem("minecraft:cobblestone")
				turtle.placeDown()
				turtle.up()
				getItem("minecraft:torch")
				turtle.placeDown()
				turtle.select(selected)
			end
		else
			getItem("minecraft:cobblestone")
			turtle.placeDown()
			turtle.up()
			getItem("minecraft:torch")
			turtle.placeDown()
			turtle.select(selected)
		end
	else
		printError("Could not place torch due to liquid present.")
	end
end

local function unload( _KeepOneFuelStack )
	print( name .. " is unloading items..." )
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
	print( name .. " is returning to chest..." )
	GoTo( 0,0,0,-1 )

	unload( true )

	print( name .. " is resuming mining..." )
	GoTo( x,z,xd,zd )
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
			print( name .." mined "..(collected + unloaded).." items." )
		end
	end
	
	if bFull then
		print( name .." has no empty slots left." )
		return false
	end
	return true
end

local function tryForwards()
	local nFuelLevel = turtle.getFuelLevel()
	if nFuelLevel <= 1 then
		local selected = turtle.getSelectedSlot()
		turtle.select(1)
		turtle.refuel(1)
		turtle.select(selected)
	end
	turtle.digUp() 
	local there, meta = turtle.inspectDown()
	if there and meta.name ~= "minecraft:torch" then
		turtle.digDown()
	end
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

function GoTo( x, z, xd, zd )

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

local function MineLayer()
	local nExistingFuelLevel = turtle.getFuelLevel()
	local nFuelReadyToLoad = turtle.getItemCount(1)
	local nFullFuelLevel = (nExistingFuelLevel + nFuelReadyToLoad * 80) -- assuming that we're using coal, change 80 if another fuel souce is added
	-- change 15 in the following equation for needed fuel to 14 once torches are implemented (as that's the amount of free slots)
	-- or if the option to turn off torches is implemented then have it switch between 15 and 14 depending on if it's off or on
	local nNeededFuel = mineWidth * mineLength + (mineWidth * mineLength * 3) / (15*64) * 2 * (mineWidth+mineLength)
	if nFullFuelLevel > nNeededFuel then
		print( name .. " starting..." )
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
		print( name .. " returning to base..." )
		GoTo( 0,0,0,-1 )
		unload( false )
		GoTo( 0,0,0,1 )
		print( "Mined "..(collected + unloaded).." items total." )
	else
		error("Not enough fuel to start. (Add a minimum of 39 coal in the first slot)", 0)
	end
	stop = true
end

local function controls()
	local event, key, held = os.pullEvent("key")
	if key == keys.k then
		stop = true
		print("K pressed, stopping program...")
	end
end

-- save location to the turtle (next thing to do)
local function saveLocation()
	sleep(10)
	local status = {xPos, zPos, xDir, zDir}
end

local function untilStopped(func)
	while not stop do
		func()
	end
end

-- Main loop
parallel.waitForAny(
	function()
		untilStopped(controls)
	end,
	function()
		untilStopped(MineLayer)
	end
)