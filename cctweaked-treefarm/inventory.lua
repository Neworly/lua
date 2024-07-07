local inventory = {}

local header = {}

local TURTLE_INVENTORY_SIZE = 16

function parse_inventory(fn)
    local result
    
    for i = 1, TURTLE_INVENTORY_SIZE do
        result = fn(i)
        if result then
            break
        end
    end
    
    return result
end

function header.parse(fn)
    return parse_inventory(fn)
end

function track_empty_slot()
    local current = turtle.getSelectedSlot()
    local slot = parse_inventory(function(i)
        turtle.select(i)
        if turtle.getItemCount() == 0 then
            slot = i    
            return slot            
        end
        return false
    end)
    turtle.select(current)
    return slot and slot or 0
end

function header.empty_slot()
    local index = track_empty_slot()
    if index == 0 then
        return false
    end
    turtle.select(index)
    return index
end

function header.add(item_name, many)                 
    local n = inventory[item_name] or 0   
    if 0 ~= turtle.getItemDetail() then
        if n == 0 then
            inventory[item_name] = {slot=turtle.getSelectedSlot(), count=0}
        end
        inventory[item_name].count = inventory[item_name].count + many
        return true, item_name
    end
    
    local slot = track_empty_slot()
    if not slot then
        return false, item_name
    end
    
    turtle.select(slot)
    return header.add(item_name, many)    
end   

function header.equip(blockname)
   local current = turtle.getSelectedSlot()
   local success = parse_inventory(function(i)
        turtle.select(i)
        
        local item = turtle.getItemDetail()
        if not item then
            return false
        end
         
        if (blockname == item.name) then
            print("equal")    
            return true
        end
    end)   
    
    if not success then 
        turtle.select(current)
    end
    return success
end

function header.print()
    for k, v in pairs(inventory) do
        print('['..k..'] s:'..v.slot..' c:'..v.count)
    end
end

function header.get()
   return inventory 
end

return header
