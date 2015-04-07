local bit = require("bit")
io.stdout:setvbuf("no")
require("AnAL")

function love.load()
	initializeVariables() 
	initializeTimeValues()
	loadMap()

	local img  = love.graphics.newImage("explosion2.png")
   	anim = newAnimation(img, 96, 96, 0.1, 0)
   	anim:setMode("loop")

   	music = love.audio.newSource("bgMusic.mp3")
   	music:play()
   	music:setLooping(loop)

   	sound = love.audio.newSource("Laser_Shoot.wav", "static")
   	hitSound = love.audio.newSource("hit.wav", "static")	
end

function love.update(dt)
	--keep framerate at 30fps
	if dt < 1/frameRate then
      love.timer.sleep(1/frameRate - dt)
   	end
   	
   	stateControl()
   	spawnEnemies()
	
	if (isFiring) then
		changeBeamDrawLocation()
		checkForHitEnemies()
	else
		curColor = checkColor()
	end

	moveEnemies()
	--checkEnemyPlayerCollision()
	anim:update(dt)
end

function love.draw()
	--draw the map
    --love.graphics.setBlendMode('premultiplied')
    love.graphics.draw(canvas)

    love.graphics.draw(Tileset, ColorQuads[curColor], 384, 288)

    drawEnemies()

    
    if isFiring and not gameOver then 
    	--love.graphics.draw(Tileset, ColorQuads[curColor], beamX, beamY)
    	--print(love.graphics.getColor())
    	love.graphics.setColor(colorRGB[curColor].R, colorRGB[curColor].G, colorRGB[curColor].B) 
    	--else love.graphics.setColor(255, 255, 255)
    	--end
    	if currentDirection == UP then
			love.graphics.rectangle("fill", 384, 0, 32, 288)
		elseif currentDirection == DOWN then
			love.graphics.rectangle("fill", 384, 320, 32, 288)
		elseif currentDirection == LEFT then
			love.graphics.rectangle("fill", 0, 288, 384, 32)
		elseif currentDirection == RIGHT then
			love.graphics.rectangle("fill", 416, 288, 384, 32)
		else
			
		end
    end
    love.graphics.setColor(255, 255, 255)

    drawAnim()

   	love.graphics.print(gameTimeSeconds, 0, 0, 0, 3, 3)
end

function love.keypressed(key)
	if (gameOver == false and isFiring == false) then
		if key == "up" then
			sound:play()
			currentDirection = UP
			isFiring = true
	        --print(colorTable[curColor+1] .. " " .. directionTable[currentDirection])
	    elseif key == "down" then
	    	sound:play()
	    	currentDirection = DOWN
	    	isFiring = true
	        --print(colorTable[curColor+1] .. " " .. directionTable[currentDirection])
	    elseif key == "left" then
	    	sound:play()
	    	currentDirection = LEFT
	    	isFiring = true
	        --print(colorTable[curColor+1] .. " " .. directionTable[currentDirection])
	    elseif key == "right" then
	    	sound:play()
	    	currentDirection = RIGHT
	    	isFiring = true
	        --print(colorTable[curColor+1] .. " " .. directionTable[currentDirection])
	    else
	    	currentDirection = NODIRECT
	    end
	end

	if key == "a" then
		redValue = RED 
	end
	if key == "s" then
		greenValue = GREEN 
	end
	if key == "d" then 
		blueValue = BLUE 
	end 

	if key == "escape" then
    	 love.event.push('quit')
    end
end

function love.keyreleased(key)
	if key == "a" then
		redValue = 0 
	end
	if key == "s" then
		greenValue = 0 
	end
	if key == "d" then 
		blueValue = 0 
	end 

	if key == "up" or key == "down" or key == "left" or key == "right" then
		isFiring = false
	end
end 

--------------------------------------------
-----------------FUNCTIONS------------------
--------------------------------------------

-------------Loading Functions--------------

function initializeVariables()
	RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE = 1, 2, 3, 4, 5, 6, 7 
	NODIRECT, UP, DOWN, LEFT, RIGHT = 0, 1, 2, 3, 4
	colorTable = {
		"none",
		"red",
		"green",
		"yellow",
		"blue",
		"magenta",
		"cyan",
		"white"
	}
	directionTable = {
		"up",
		"down",
		"left",
		"right"
	}
	upStart = {
		{384, 0},
		{384, 576},
		{0, 288},
		{768, 288}
	} 
	colorRGB = {
		{R = 231,G = 76,B = 60},
		{R = 46,G = 204,B = 113},
		{R = 241,G = 196,B = 15},
		{R = 52,G = 152,B = 219},
		{R = 255,G = 0,B = 220},
		{R = 0,G = 255,B = 255},
		{R = 255,G = 255,B = 255}

	}

	frameCount = 0
	gameTimeSeconds = 0

	currentDirection = 0
	curColor = 8
	isFiring = false
	beamX = 0
	beamY = 0
	gameOver = false

	--these hold the values of the three color buttons
	--based on whether they are pressed down or not
	--
	--they are or'd together to get the current color
	redValue = 0
	greenValue = 0
	blueValue = 0

	frameRate = 30
	respawnTimeLimit = 5
	numColorsToSpawn = 4

	enemies = {
		{  },
		{  },
		{  },
		{  }
	}

	animLocations = {}
end

function initializeTimeValues()
	math.randomseed(os.time())
	upTimeLimit = math.random(respawnTimeLimit)*30
	downTimeLimit = math.random(respawnTimeLimit)*30
	leftTimeLimit = math.random(respawnTimeLimit)*30
	rightTimeLimit = math.random(respawnTimeLimit)*30 
	print (upTimeLimit .. " " .. downTimeLimit .. " " .. leftTimeLimit .. " " .. rightTimeLimit)
	upTime = 0--math.random(150)
	downTime = 0--math.random(150)
	leftTime = 0--math.random(150)
	rightTime = 0--math.random(150)
end

function loadMap() 
	Tileset = love.graphics.newImage('bgs.png')
	TileW, TileH = 32,32

	map = {
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
	    { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
	}

    local tilesetW, tilesetH = Tileset:getWidth(), Tileset:getHeight()

    local quadInfo = {
        {  0,  0 }, -- 0 = grey 
        { 32,  0 }, -- 1 = dark blue
        {  0,  0 }, -- 2 = grey 
        { 32, 32 }, -- 3 = red
        {  0, 32 }, -- 4 = green
        { 64, 32 }, -- 5 = yellow
        { 64,  0 }, -- 6 = blue
        {  0, 64 }, -- 7 = magenta 
        { 32, 64 }, -- 8 = cyan 
        { 64, 64 }  -- 9 = white 
    }

    local colorQuadInfo = {
    	{ 32, 32 }, -- 1 = red
        {  0, 32 }, -- 2 = green
        { 64, 32 }, -- 3 = yellow
        { 64,  0 }, -- 4 = blue
        {  0, 64 }, -- 5 = magenta 
        { 32, 64 }, -- 6 = cyan 
        { 64, 64 },  -- 7 = white 
        {  0,  0 } -- 8 = grey
	}

    Quads = {}
    for i,info in ipairs(quadInfo) do
        Quads[i] = love.graphics.newQuad(info[1], info[2], TileW, TileH, tilesetW, tilesetH)
    end

    ColorQuads = {}
    for i,info in ipairs(colorQuadInfo) do
        ColorQuads[i] = love.graphics.newQuad(info[1], info[2], TileW, TileH, tilesetW, tilesetH)
    end

    --setup the board as a canvas
    canvas = love.graphics.newCanvas(800, 600)
    love.graphics.setCanvas(canvas)
        canvas:clear()
        --love.graphics.setBlendMode('alpha')
        for rowIndex,row in ipairs(map) do
            for columnIndex,number in ipairs(row) do
                local x,y = (columnIndex-1)*TileW, (rowIndex-1)*TileH
                love.graphics.draw(Tileset, Quads[number+1], x, y)
            end
        end
    love.graphics.setCanvas()
end

-------------Gameplay Functions-------------

function stateControl()
	--count game time and increase spawn rate
   	frameCount = frameCount + 1
   	if frameCount == frameRate  and not gameOver then 
   		gameTimeSeconds = gameTimeSeconds + 1
   		print(gameTimeSeconds)
   		frameCount = 0
   		if gameTimeSeconds % 30 == 0  and respawnTimeLimit > 1 then 
   			respawnTimeLimit = respawnTimeLimit - 1
   			print("Respawn: " .. respawnTimeLimit)
   		end
   		if gameTimeSeconds % 30 == 0  and numColorsToSpawn < 8 then
   			numColorsToSpawn = numColorsToSpawn + 1
   		end
   	end 
end

function checkColor()
	local tempColor = 0
	tempColor = bit.bor(tempColor, redValue, greenValue, blueValue)
	if tempColor == 0 then
		tempColor = 8
	end
	return tempColor
end

function checkForHitEnemies()
	--for dirIndex, direction in ipairs(enemies) do
	if(enemies[currentDirection] ~= null) then
		for enemyIndex, enemy in ipairs(enemies[currentDirection]) do
			--print("enemy: " .. enemy[1] .. "  curColor " .. curColor)
			if(enemy[1] == curColor) then 
				hitSound:play()
				--table.insert(animLocations, {enemy[2]-16, enemy[3]-16, 0})
				--table.remove(enemies[currentDirection], enemyIndex)
				enemies[currentDirection][enemyIndex][4] = true
			end
		end
	end
end

function moveEnemies()
	for enemyIndex, enemy in ipairs(enemies[1]) do
		if enemy[4] == true then 
			enemy[2] = enemy[2] + 25
			enemy[3] = enemy[3] - 25
			enemy[5] = (enemy[5]+0.4)
		else 
			enemy[3] = enemy[3] + 2
		end
	end
	for enemyIndex, enemy in ipairs(enemies[2]) do
		if enemy[4] == true then 
			enemy[2] = enemy[2] + 25
			enemy[3] = enemy[3] - 25
			enemy[5] = (enemy[5]+0.4)
		else 
			enemy[3] = enemy[3] - 2
		end
	end
	for enemyIndex, enemy in ipairs(enemies[3]) do
		if enemy[4] == true then 
			enemy[2] = enemy[2] - 25
			enemy[3] = enemy[3] - 25
			enemy[5] = (enemy[5]+0.4)
		else 
			enemy[2] = enemy[2] + 2
		end
	end
	for enemyIndex, enemy in ipairs(enemies[4]) do
		if enemy[4] == true then 
			enemy[2] = enemy[2] + 25
			enemy[3] = enemy[3] - 25
			enemy[5] = (enemy[5]+0.4)
		else 
			enemy[2] = enemy[2] - 2
		end
	end
end

function spawnEnemies()
	if(upTime < upTimeLimit) then
		upTime = upTime + 1
	else
		--math.randomseed(os.time())
									--{color, x, y, isHit, orientation(radians)}
		table.insert(enemies[1], 1, {math.random(numColorsToSpawn), 384, 0, false, 0})
		upTime = 0
		upTimeLimit = math.random(respawnTimeLimit)*30
	end
	if(downTime < downTimeLimit) then
		downTime = downTime + 1
	else
		--math.randomseed(os.time())
		table.insert(enemies[2], 1, {math.random(numColorsToSpawn), 384, 576, false, 0})
		downTime = 0
		downTimeLimit = math.random(respawnTimeLimit)*30
	end
	if(leftTime < leftTimeLimit) then
		leftTime = leftTime + 1
	else
		--math.randomseed(os.time())
		table.insert(enemies[3], 1, {math.random(numColorsToSpawn), 0, 288, false, 0})
		leftTime = 0
		leftTimeLimit = math.random(respawnTimeLimit)*30
	end
	if(rightTime < rightTimeLimit) then
		rightTime = rightTime + 1
	else
		--math.randomseed(os.time())
		table.insert(enemies[4], 1, {math.random(numColorsToSpawn), 768, 288, false, 0})
		rightTime = 0
		rightTimeLimit = math.random(respawnTimeLimit)*30
	end
end

function checkEnemyPlayerCollision()
	for enemyIndex, enemy in ipairs(enemies[1]) do
		if(enemy[3] > 256) then
			--print("GAME OVER")
			currentDirection = 0
			gameOver = true
		end
	end
	for enemyIndex, enemy in ipairs(enemies[2]) do
		if(enemy[3] < 320) then
			--print("GAME OVER")
			currentDirection = 0
			gameOver = true
		end
	end
	for enemyIndex, enemy in ipairs(enemies[3]) do
		if(enemy[2] > 352) then
			--print("GAME OVER")
			currentDirection = 0
			gameOver = true
		end
	end
	for enemyIndex, enemy in ipairs(enemies[4]) do
		if(enemy[2] < 416) then
			--print("GAME OVER")
			currentDirection = 0
			gameOver = true
		end
	end
end

---------------Draw Functions---------------

function changeBeamDrawLocation()
	if currentDirection == UP then
		beamX = 384
		beamY = 256
	elseif currentDirection == DOWN then
		beamX = 384
		beamY = 320
	elseif currentDirection == LEFT then
		beamX = 352
		beamY = 288
	elseif currentDirection == RIGHT then
		beamX = 416
		beamY = 288
	else
		beamX = 0
		beamY = 0
	end
end

function drawEnemies()
	for dirIndex, direction in ipairs(enemies) do
		for enemyIndex, enemy in ipairs(direction) do
			--love.graphics.draw( image, quad, x, y, r, sx, sy, ox, oy, kx, ky )
			love.graphics.draw(Tileset, ColorQuads[enemy[1]], enemy[2], enemy[3], enemy[5])
		end
	end
end

function drawAnim()
	for animIndex, exAnim in ipairs(animLocations) do
		anim:draw(exAnim[1], exAnim[2])
		exAnim[3] = exAnim[3] + 1
		if anim:getCurrentFrame() == anim:getSize() then
			table.remove(animLocations, animIndex)    		
    	end
	end 
end

--------------Utility Fuctions--------------

function isArrowKeyPressed()
	if love.keyboard.isDown("up")
	or love.keyboard.isDown("down")
	or love.keyboard.isDown("left")
	or love.keyboard.isDown("right") then
		return true
	else
		return false
	end
end