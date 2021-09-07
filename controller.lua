-- Accompanying code for the monitoring system of turtles.lua, for the central computer.
-- Created by StarNinga

local turtleLocations = {}

local stop = false
peripheral.find("modem", rednet.open)
if rednet.isOpen() == false then 
   error("Control comupter requires a modem.", 0) 
end

local function assignNames()
   local aOldTurtles = Turtles
   Turtles = { rednet.lookup("turtleName") }
   if Turtles ~= aOldTurtles then
      for key,value in ipairs(Turtles) do
         rednet.send(value, "turtle"..key, "turtleName")
      end
   end
   sleep(4)
end

local function controls()
   local event, key, held = os.pullEvent("key")
    if key == keys.k then
      stop = true
      print("K pressed, stopping program...")
    end
end

local function untilKill(func)
   while not stop do
       func()
   end
end

parallel.waitForAny(
   function() 
      untilKill(assignNames)
   end,
   function() 
      untilKill(controls)
   end
)