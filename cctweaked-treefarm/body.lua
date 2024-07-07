local inventory = require("inventory")
local bot = require("bot")
local breakable = require("breakables")
local sapling = require("saplings")

function inspect()
    local _, retval = turtle.inspect()
    if type(retval) ~= "table" then
        return false
    end
    
    return retval
end

function can_break_this(blockname)    
    local block = false
    
    if blockname:len() > 0 then    
        local k = blockname:gsub(":", "_")
        if breakable[k] then
            block = blockname
        end 
    end   
    
    return block
end

local automata = peripheral.wrap("left")

function bot_task()
    local block = inspect()
    if block and block.name == "minecraft:redstone_block" then
        return "home"
    end
    return "work", block
end

local newtask = function()
    bot.state = bot_task()
end

local gohome = function()
    bot:rotate("back")
    local function walking()    
        return 
        bot.space.x ~= 0
            or bot.space.y ~= 0
        or bot.space.z ~= 0
    end
    
    while walking() do
        unstuck()
        print(bot.space.x,bot.space.y,bot.space.z)
        if bot.space.z > 0 then         
            bot:step_backward()
        elseif bot.space.z < 0 then
            bot:step_forward()              
        elseif bot.space.y > 0 then
            bot:step_down()
        elseif bot.space.y < 0 then
            bot:step_up()
        elseif bot.space.x > 0 then
            bot:step_toleft()
        elseif bot.space.x < 0 then
            bot:step_toright()
        end        
    end
    bot:rotate("front")
    bot.state = nil
end

function are_equal(t, t2)
    local result = true
    for kt, vt in pairs(t) do
        local equal = false
        for kt2, vt2 in pairs(t2) do
            if kt2 == kt
                and vt == vt2
            then
                equal = true
                print(kt2, kt, "are equal")
            else
                print(kt2, kt, "are unequal due to", vt2, vt)
            end
        
        end
        
        if not equal then
            return false
        end
    end
    return true
end

function unstuck()
    local fblock = inspect()
    if fblock then
        if (not can_break_this(fblock.name)) and fblock.name ~= "minecraft:redstone_block" then
            if bot.space.y <= 0 then
                bot:dig("up")
                bot:step_up()
            end
        elseif can_break_this(fblock.name) then
            if bot.space.y ~= 0 then
                local ok, t = turtle.inspectDown()
                if ok and t.name ~= "minecraft:dirt" then
                    bot:dig("down")
                end
                bot:step_down()
            end
        end
        
        if bot.state == "home" or fblock.name ~= "minecraft:oak_log" and fblock.name ~= "minecraft:redstone_block" then
            bot:dig("front")
        end
    end
end


function cycle()
    local task, block = bot_task()
    bot.state = task
    
    if "home" == bot.state then
        gohome() 
        bot:rotate("back")
        inventory.parse(function(i)
            local item = turtle.getItemDetail(i)
            if item and not sapling[item.name] then
                turtle.select(i)
                turtle.drop()
            end
            
            sleep(1)
            return false
        end)
        bot:rotate("front")
        return
    end
        
    if block and can_break_this(block.name) then
        bot:dig("front")
        table.insert(bot.task.trees, {sapling={x=bot.space.x,y=bot.space.y,z=bot.space.z+1},bot={x=bot.space.x,y=bot.space.y,z=bot.space.z-1}})
        if inventory.empty_slot() then
            automata.useOnBlock()
        end
        
        for i = 1, 10 do
            automata.collectItems()
        end
    else
        bot:step_forward()
        local ok, t = turtle.inspectDown()
        local n = #bot.task.trees
        
        if n > 0 then
            if ok and "minecraft:dirt" == t.name then
                for k, is_allowed in pairs(sapling) do               
                    if true == is_allowed and inventory.equip("minecraft:oak_sapling") then
                        bot:rotate("back")
                        local s = turtle.place()
                        bot:rotate("front")
                        if s then
                            bot.task.trees[n] = nil
                        end
                        break
                    end    
                end
            else
                print("non-cultural block")               
            end    
        else
            -- print("no sapling were supplied or found")                         
        end
        
        unstuck()
    end
        
    do cycle() end   
end

cycle()

