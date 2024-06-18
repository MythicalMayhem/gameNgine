local molly = love


 
local game = require ('config')
local bkt = require ("libs/bucket") 
local cam = require ("libs/cam")

local boxes  = {}
local entities = {}
local swings = {}
 
 


local fps = 1
local debounce = os.clock() 
local p = ''

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
 

function entities:new()
    
    local temp = {}
    temp.x = 500
    temp.y = 500
    temp.h = 20
    temp.w = 10
    temp.mass = 55
    temp.stats = { speed = 5 }
    temp.direction = { x = 0 , y = 0 ,mag = temp.stats.speed}
    temp.impulses = {}
    temp.linearforces   = {}
    temp.sprite = function() molly.graphics.rectangle('fill', temp.x, temp.y, temp.w,temp.h) end
    temp.compute = function()
        local sumx,sumy = 0,0
        local forces = bkt.concattabs(temp.linearforces,{temp.direction},temp.impulses)

        for i,force in ipairs(forces) do 
            local x,y = bkt:normalize2d(force.x,force.y)
            sumx = sumx + x*force.mag
            sumy = sumy + y*force.mag        
        end   
        local x,y = bkt:normalize2d(sumx,sumy)
        local summag = bkt:magnitude(sumx,sumy)

        return {x  =x, y   = y, mag = summag}
    end
    table.insert(entities,temp)    
    return temp
end




function clipY(entity,box)
    if box.y > entity.y then   entity.y = box.y - (entity.h)    
    else  entity.y = box.y + (box.h)  end    
end

function clipX(entity,box)
    if box.x > entity.x then  entity.x = box.x -  (entity.w)             
    else entity.x = box.x + (box.w)   end
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
        if abs   then clipX(entity,feetOn)
        elseif ord   then clipY(entity,feetOn) end
    end
    if abs==false then entity.x = toX end
    if ord==false then entity.y = toY end  
end

function molly.load() 
    molly.window.setMode(game.screenwidth, game.screenheight)
    molly.window.setFullscreen(false) 
    molly.graphics.setFont(molly.graphics.newFont( 25 ))
    
    local wh = game.vh
    local ww = game.vw


 
    boxes:new(0,wh-10,ww,10) 
    boxes:new(0,0,ww,10) 
    boxes:new(ww-10,0,10,wh) 
    boxes:new(0,0,10,wh) 
    
    boxes:new(400,500,100,200) 


    for i,entity in ipairs(entities) do  table.insert(entity.linearforces,{x=0,y=1,mag=game.gravity})  end 
end


local player = entities:new()   
local camera = cam()
function molly.update(dt) 
    if os.time() - debounce > 0.05 then fps = 1 / dt debounce = os.time() end
    
    for ind, entity in ipairs(entities) do
        
        local i = 0
        while entity.impulses and  (i < #entity.impulses) do 
            i = i + 1
            local mag = entity.impulses[i].mag - entity.impulses[i].resistance 
            if mag < 0 then table.remove(entity.impulses,i)
            else entity.impulses[i].mag = mag  end           
        end
    end 
 

    if molly.keyboard.isDown('w','up') then player.direction.y = -1
    elseif molly.keyboard.isDown('s','down') then player.direction.y  = 1
    else player.direction.y =  0 end

    if molly.keyboard.isDown('a','left') then player.direction.x = -1
    elseif molly.keyboard.isDown('d','right') then player.direction.x =  1
    else player.direction.x = 0  end 
    

    collisions(player)  
end 

function molly.draw() 
    camera:attach(player.x, player.y)
    molly.graphics.setColor(0.5, 0.9, 0.5)
    player.sprite()
    
    molly.graphics.setColor(0.7, 0.7, 1)
    for i, box in ipairs(boxes) do box.sprite() end
    
    camera:detach()

    molly.graphics.setColor(0.5, 0.9, 0.5)
    molly.graphics.print('\n'..p)
    molly.graphics.print(tostring(fps)..'\n')  
 
end

function molly.keypressed(key)
    if key=='space' then
        local  a = {x=0,y=-1,mag=15,resistance = game.resistance }
        table.insert(player.impulses,a)  
    end
end
 