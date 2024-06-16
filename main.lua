local molly = love



    
local bkt = require ("bucket")
local boxes  = {}
local entities = {}
local swings = {}
local world = {}
world.gravity = 9


local fps = 1
local debounce = os.clock()
local dirs = {abs=0, ord=0}
local p = ''


function entities:new()
    
    local temp = {}
    temp.x = 500
    temp.y = 500
    temp.h = 20
    temp.w = 20
    temp.stats = {speed = 10 }
    temp.direction = {x=0,y=0}
    temp.forces = {}
    temp.sprite = function() molly.graphics.rectangle('fill', temp.x, temp.y, 20,20) end
    temp.compute = function() 
        
        local sumx,sumy = bkt:normalize2d(temp.direction.x,temp.direction.y)
        local summag = temp.stats.speed

        for i,force in ipairs(temp.forces) do 
            local x,y = bkt:normalize2d(force.x,force.y)
            sumx = sumx + x
            sumy = sumy + y
            summag = summag + force.mag
        end  
        return {x  = sumx, y   = sumy, mag = summag}
    end
    table.insert(entities,temp)    
    return temp
end

function boxes:new (x,y,w,h)
    local temp = {}
    temp.x = x
    temp.y = y
    temp.h = h
    temp.w = w
    temp.sprite = function() molly.graphics.rectangle('fill', temp.x, temp.y, temp.w,temp.h) end
    table.insert(boxes,temp)    
    return temp
end

function swings:new(x,y,r)
    local temp = {}
    temp.x = x
    temp.y = y
    temp.r = r
    temp.sprite = function() molly.graphics.circle('fill', temp.x, temp.y, temp.r) end
    return temp
end

local player = entities:new() 

function clipY(entity,box)
    if box.y > entity.y then  entity.y = box.y - (box.h/2) - (entity.h)   
    else  entity.y = box.y + (box.h/2) + (entity.h/2)    end    
end

function clipX(entity,box)
    if box.x > entity.x then entity.x = box.x - (box.w/2) - (entity.w)  
    else entity.x = box.x + (box.w/2) + (entity.w/2) end
end

function collisions(entity)
    local direction = entity.compute() 
     
    local toX = entity.x + direction.x*direction.mag
    local toY = entity.y + direction.y*direction.mag
    
    local abs,ord = false,false
    local feetOn = nil
    for i, box in ipairs(boxes) do
        if (toX< box.x + box.w ) and (toX+ entity.w > box.x) and (entity.y < box.y + box.h) and (entity.y + entity.h > box.y )  then  
            abs =true  
            feetOn = box
        end    
        if (entity.x< box.x + box.w ) and (entity.x+ entity.w > box.x) and (toY < box.y + box.h) and (toY + entity.h > box.y )  then  
            ord =true 
            feetOn = box
            
        end    
    end


    if feetOn then
        if abs and (feetOn.h>feetOn.w) then
            clipX(entity,feetOn)
        elseif ord and (feetOn.h<feetOn.w) then
            clipY(entity,feetOn)
        end
    end
    if abs==false then player.x = toX end
    if ord==false then player.y = toY end  
end

function molly.load() 

    molly.window.setMode(1600, 900)
    molly.window.setFullscreen(true) 
    myFont = molly.graphics.newFont(25)

    
    local wh = molly.graphics.getHeight()
    local ww = molly.graphics.getWidth()
 
    boxes:new(0,wh-10,ww,10) 
    boxes:new(0,0,ww,10) 
    boxes:new(ww-10,0,10,wh) 
    boxes:new(0,0,10,wh) 
  --  for i,entity in ipairs(entities) do  table.insert(entity.forces,{x=0,y=-1,mag=-2})  end 
end

function molly.update(dt) 
    if os.time() - debounce > 0.05 then fps = 1 / dt debounce = os.time() end

    if molly.keyboard.isDown('w','up') then player.direction.y = -1
    elseif molly.keyboard.isDown('s','down') then player.direction.y  = 1
    else player.direction.y =  0 end

    if molly.keyboard.isDown('a','left') then player.direction.x = -1
    elseif molly.keyboard.isDown('d','right') then player.direction.x =  1
    else player.direction.x = 0  end 
    
    collisions(player)
    
end 

function molly.draw()
    molly.graphics.setFont(myFont)
    molly.graphics.setColor(0.5, 0.9, 0.5)
    player.sprite()
    molly.graphics.setColor(0.7, 0.7, 1)
    for i, box in ipairs(boxes) do box.sprite() end
    molly.graphics.setColor(0.5, 0.9, 0.5)
    molly.graphics.print('\n'..p)
    molly.graphics.print(tostring(fps)..'\n')
end

function molly.mousepressed()
    local x, y = molly.mouse.getPosition()
    local least = nil
    for i,swing in ipairs(swings) do
        local curr = math.sqrt(x*least.x + y*least.y)
        local dist = math.sqrt(x*swing.x + y*swing.y)
        if dist < curr then least = swing end
    end
end