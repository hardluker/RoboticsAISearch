-- Imports for utilizing simulation-related functions
sim=require'sim'
simUI=require'simUI'

-- Initialization function upon creation of the object
function sysCall_init()


    -- Defining the parts of the bot
    disasterBotBase=sim.getObject('.')
    leftMotor=sim.getObject("./leftMotor")
    rightMotor=sim.getObject("./rightMotor")
    leftSensor=sim.getObject("./leftSensor")
    rightSensor=sim.getObject("./rightSensor")
    upSensor=sim.getObject("./upSensor")
    downSensor=sim.getObject("./downSensor")
    
    -- Creating an array of people sensors
    peopleSensors = {}
    peopleSensors[1] = sim.getObject("./peopleSensor[0]")
    peopleSensors[2] = sim.getObject("./peopleSensor[1]")
    
    -- Performing initial sensor check
    upRes = sim.readProximitySensor(upSensor)
    downRes = sim.readProximitySensor(downSensor)
    leftRes = sim.readProximitySensor(leftSensor)
    rightRes = sim.readProximitySensor(rightSensor)
    
    --Robot Speed
    speed = 3
    
    -- Creating an array for the human found flag initializing all to false
    humanFound = {}
    for i = 1, #peopleSensors do
        humanFound[i] = false
    end
    
    -- GoalFound variable to terminate the search
    goalFound = false
    
    -- Robot Direction it is facing
    robotDirection = "unknown"
    
    -- Last move the robot has done
    lastMove = "unknown"
    
    -- Stack for storing backtrack data
    moveStack = {}
    
    -- Flag to determine if the bot is backtracking or not.
    backtracking = false
    
    -- World Grid
    worldGrid = {}
    for i = 1, 15 do
        worldGrid[i] = {}
        for j = 1, 15 do
            worldGrid[i][j] = 0
        end
    end
    
    -- Robot position in world grid
    -- This is where the robot starts in the gridMap.
    robotGridPos = {}
    robotGridPos[1] = 10
    robotGridPos[2] = 2
    worldGrid[robotGridPos[1]][robotGridPos[2]] = 1
    
    -- Euler angle for 
    eulerUp = {-0.0, 0.0, -0.0}
    eulerLeft = {-0.0, 0.0, 1.570796326795}
    eulerDown = {-0.0, 0.0, -3.1415926535896}
    eulerRight = {-0.0, 0.0, -1.5707963267946}
    
    -- Robot initial position
    botInitPos = sim.getObjectPosition(disasterBotBase)
    
    
end

-- Function for the sensors to continually update
function sysCall_sensing()
    upRes = sim.readProximitySensor(upSensor)
    downRes = sim.readProximitySensor(downSensor)
    leftRes = sim.readProximitySensor(leftSensor)
    rightRes = sim.readProximitySensor(rightSensor)
    detectHumans()
end

-- MAIN FUNCTION --
function sysCall_thread()
    depthSearch()
    print("Humans Found, Mission Accomplished")
    print(string.format("Robot's Coordinates: X=%.2f, Y=%.2f, Z=%.2f", getPos("x"), getPos("y"), getPos("z")))
    
end

-- Implementation of depth-first search algorithm
function depthSearch()
    unexplored = 0
    explored = 2
    while robotDirection ~= "up" do
        turn("up")
    end
    
    while goalFound == false do
        sysCall_sensing()
        scan()
        options = {}
        if isTableNotEmpty(searchLocalMap(unexplored)) then
            backtracking = false
            options = searchLocalMap(unexplored)
            local randomOption = math.random(1, #options)
            move(options[randomOption])
        elseif isTableNotEmpty(searchLocalMap(explored)) then
            backtracking = true
            -- Pop the last move from the stack
            local mv = popMove()
            -- Move in the opposite direction of the last move
            if mv == "up" then
                move("down")
            elseif mv == "down" then
                move("up")
            elseif mv == "left" then
                move("right")
            elseif mv == "right" then
                move("left")
            end
        end
    end
end

--Function to check if a table is not empty
function isTableNotEmpty(tbl)
    return next(tbl) ~= nil
end

function searchLocalMap(value)
    local directions = {} -- Initialize an empty array to store directions
    -- Iterate over the localMap table
    for direction, tileValue in pairs(localMap) do
        -- Check if the current tile value matches the specified value
        if tileValue == value then
            -- Add the direction to the array
            table.insert(directions, direction)
        end
    end
    return directions -- Return the array of directions
end

-- Function to push a move onto the stack
function pushMove(move)
    table.insert(moveStack, move)
end

-- Function to pop a move from the stack
function popMove()
    return table.remove(moveStack)
end

-- Function to check if the stack is empty
function isStackEmpty()
    return #moveStack == 0
end


-- A function for scanning the surrounding tiles for obstactles
function scan()
    
    if robotDirection == "up" then
        if upRes == 1 then
            updateGrid("up")
        end
        if rightRes == 1 then
            updateGrid("right")
        end
        if leftRes == 1 then
            updateGrid("left")
        end
        if downRes == 1 then
            updateGrid("down")
        end
    elseif robotDirection == "left" then
        if upRes == 1 then
            updateGrid("left")
        end
        if rightRes == 1 then
            updateGrid("up")
        end
        if leftRes == 1 then
            updateGrid("down")
        end
        if downRes == 1 then
            updateGrid("right")
        end
    elseif robotDirection == "right" then
        if upRes == 1 then
            updateGrid("right")
        end
        if rightRes == 1 then
            updateGrid("down")
        end
        if leftRes == 1 then
            updateGrid("up")
        end
        if downRes == 1 then
            updateGrid("left")
        end
    elseif robotDirection == "down" then
        if upRes == 1 then
            updateGrid("down")
        end
        if rightRes == 1 then
            updateGrid("left")
        end
        if leftRes == 1 then
            updateGrid("right")
        end
        if downRes == 1 then
            updateGrid("up")
        end
    end
    updateLocalMap()
    
end

-- A function for updating blocked tiles in relation to the bot
function updateGrid(dir)
    local blocked = 3
    local posToUpdate
        
        -- Updating the corresponding tile in the worldGrid
        if dir == "up" then 
            posToUpdate = robotGridPos[2] + 1
            worldGrid[robotGridPos[1]][posToUpdate] = blocked
        elseif dir == "down" then
            posToUpdate = robotGridPos[2] - 1
            worldGrid[robotGridPos[1]][posToUpdate] = blocked
        elseif dir == "left" then 
            posToUpdate = robotGridPos[1] - 1
            worldGrid[posToUpdate][robotGridPos[2]] = blocked
        elseif dir == "right" then
            posToUpdate = robotGridPos[1] + 1 
            worldGrid[posToUpdate][robotGridPos[2]] = blocked
        end
end

-- Function for updating a map that contains the current adjacent tile information.
function updateLocalMap()
    localMap = { up = worldGrid[robotGridPos[1]][robotGridPos[2] + 1], 
                left = worldGrid[robotGridPos[1] - 1][robotGridPos[2]],
                down = worldGrid[robotGridPos[1]][robotGridPos[2] - 1], 
                right =  worldGrid[robotGridPos[1] + 1][robotGridPos[2]]}
end

-- Function for moving 1 tile a specific direction
function move(dir)

    -- function scope variables
    squareSize = 0.5
    botX = getPos("x")
    botY = getPos("y")
    
    -- Setting euler angles for stablity update
    if dir == "up" then euler = eulerUp end
    if dir == "down" then euler = eulerDown end
    if dir == "left" then euler = eulerLeft end
    if dir == "right" then euler = eulerRight end
    
    --Turning the robot the direction
    while robotDirection ~= dir do
        turn(dir)
    end
    
    --Updating the orientation for stability and accuracy
    sim.setObjectOrientation(disasterBotBase, euler, sim.handle_world)
    
    -- Move direction until 1 square has been traversed
    if dir == "up" then
        moveToPos = botX + squareSize
        while botX < moveToPos do
            botX = getPos("x")
            moveForward(speed)
        end
    elseif dir == "down" then
        moveToPos = botX - squareSize
        while botX > moveToPos do
            botX = getPos("x")
            moveForward(speed)
        end
    elseif dir == "left" then
        moveToPos = botY + squareSize
        while botY < moveToPos do
            botY = getPos("y")
            moveForward(speed)
        end
    elseif dir == "right" then
        moveToPos = botY - squareSize
        while botY > moveToPos do
            botY = getPos("y")
            moveForward(speed)
        end
    end
    
    stopMovement()
    updateBotOnGrid(dir)
    updatePos(dir)
    lastMove = dir
    if backtracking == false then pushMove(dir) end
    
end

-- Updates the bots position in the worldGrid for tracking.
function updateBotOnGrid(dir)
    unexplored = 0
    occupied = 1
    explored = 2
    blocked = 3
    
    -- Updating robot pos in grid based on direction.
    if dir == "up" then robotGridPos[2] = robotGridPos[2] + 1 end
    if dir == "down" then robotGridPos[2] = robotGridPos[2] - 1 end
    if dir == "left" then robotGridPos[1] = robotGridPos[1] - 1 end
    if dir == "right" then robotGridPos[1] = robotGridPos[1] + 1 end
    
    -- Iterating through through the world grid
    -- Any tiles occupied by the robot are marked as explored.
    local breakOuterLoop = false
    for i = 1, 10 do
        for j = 1, 10 do
            if worldGrid[i][j] == occupied then
                worldGrid[i][j] = explored
                breakOuterLoop = true
                break
            end
            if breakOuterLoop then break end
        end
    end
    
    -- Adding robot position to the world grid
    worldGrid[robotGridPos[1]][robotGridPos[2]] = occupied
    
end

-- Function to update robot position for stability after each move.
function updatePos(dir)
    x = 1
    y = 2
    tileSize = 0.5
    if dir == "up" then
        botInitPos[x] = botInitPos[x] + tileSize
        sim.setObjectPosition(disasterBotBase, botInitPos)
    elseif dir == "down" then
        botInitPos[x] = botInitPos[x] - tileSize
        sim.setObjectPosition(disasterBotBase, botInitPos)
    elseif dir == "left" then
        botInitPos[y] = botInitPos[y] + tileSize
        sim.setObjectPosition(disasterBotBase, botInitPos)
    elseif dir == "right" then
        botInitPos[y] = botInitPos[y] - tileSize
        sim.setObjectPosition(disasterBotBase, botInitPos)
    end
    
end

-- Function for getting the robot's position
function getPos(axis)
    botPos=sim.getObjectPosition(disasterBotBase)
    botPosX=botPos[1]
    botPosY=botPos[2]
    botPosZ=botPos[3]
    if axis == "x" then
        return botPosX
    elseif axis == "y" then
        return botPosY
    elseif axis == "z" then
        return botPosZ
    else
        return nil
    end
    
end

-- Function for turning the robot and ramping down the speed as it gets closer.
function turn(direction)
    local orientation = getOrientation()
    local maxSpeed = 5
    local angleMap = { up = 0, left = 90, down = 180, right = 270 }
    
    local desiredAngle = angleMap[direction]
    if not desiredAngle then
        print("Invalid direction")
        return
    end
    
    -- Calculate the difference between the current orientation and the desired angle
    local angleDifference = desiredAngle - orientation
    
    -- Set a minimum speed reduction factor %
    local minReductionFactor = 0.1 
    
    -- Calculate the progress of the turn
    local progress = math.abs(angleDifference) / 360
    
    -- Calculate the speed reduction factor based on the progress
    local reductionFactor = 1
    if progress <= 0.1 then
        reductionFactor = math.min(math.exp(-math.abs(angleDifference) / 180), 0.1)
    end
    
    -- Adjust the speed based on the reduction factor
    local adjustedSpeed = maxSpeed * reductionFactor + minReductionFactor
    
    -- Checking if the bot is within the tolerance for the turn
    if direction == "left" then
        if orientation < desiredAngle - 0.25 then
            rotateCounterClockwise(adjustedSpeed)
        elseif orientation > desiredAngle + 0.25 then
            rotateClockwise(adjustedSpeed)
        else
            robotDirection = "left"
            stopMovement()
        end
            
    elseif direction == "right" then
        if orientation > desiredAngle + 0.25 and orientation < 180 then
            rotateClockwise(adjustedSpeed)
        elseif orientation < desiredAngle - 0.25 and orientation < 360 then
            rotateCounterClockwise(adjustedSpeed)
        else
            robotDirection = "right"
            stopMovement()
        end
            
    elseif direction == "up" then
        if orientation > 0.5 and orientation < 180 then
            rotateClockwise(adjustedSpeed)
        elseif orientation < 359.5 and orientation > 180 then
            rotateCounterClockwise(adjustedSpeed)
        else
            robotDirection = "up"
            stopMovement()
        end
            
    elseif direction == "down" then
        if orientation > 180.5 then
            rotateClockwise(adjustedSpeed)
        elseif orientation < 179.5 then
            rotateCounterClockwise(adjustedSpeed)
        else
            robotDirection = "down"
            stopMovement()
        end
            
    else
        print("Invalid direction")
    end
    return robotDirection
end

-- Function for returning the rotation degree of the robot.
function getOrientation()
    orient = sim.getObjectOrientation(disasterBotBase + sim.handleflag_reljointbaseframe, sim.handle_world)
    local orientation = math.deg(orient[3])
    
    -- Ensure the orientation is in the range 0-360
    if orientation < 0 then
        orientation = orientation + 360
    end
    
    return orientation
end

-- Function for moving the robot forward
function moveForward(speed)
    sim.setJointTargetVelocity(leftMotor,speed)
    sim.setJointTargetVelocity(rightMotor,speed)
end

-- Function to rotate robot clockwise.
function rotateClockwise(speed)
    sim.setJointTargetVelocity(leftMotor,speed)
    sim.setJointTargetVelocity(rightMotor,-speed)
end

-- Function to rotate the robot counter-clockwise
function rotateCounterClockwise(speed)
    sim.setJointTargetVelocity(leftMotor,-speed)
    sim.setJointTargetVelocity(rightMotor,speed)
end

-- Function to stop rotation/movement
function stopMovement()
    sim.setJointTargetVelocity(leftMotor,0)
    sim.setJointTargetVelocity(rightMotor,0)
end


-- Function for detecting humans with the people sensors
function detectHumans()
-- Iterating through the sensors checking if humans are found.
    for i = 1, #peopleSensors do
        -- Gathering further info from peopleSensor to get the obj that is detected.
        res, dist, point, obj, n = sim.readProximitySensor(peopleSensors[i])
        if (res > 0 and not humanFound[i]) then
            objAlias = sim.getObjectAlias(obj)
            if (objAlias == "human") then
                humanFound[i] = true
                stopMovement()
                goalFound = true
                print(string.format("Human Found! Sensor: %d", i))
                
            end
        elseif (res <= 0) then
            humanFound[i] = false
        end
    end
end