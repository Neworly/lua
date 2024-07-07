local inventory = require("inventory")

local module = {} 
local private = {}

function module.meta()
    local offv3 = {x=0,y=0,z=0}
    return setmetatable({
        space = offv3,
        engine = {
            current_fuel = turtle.getFuelLevel(),
            max_fuel = turtle.getFuelLimit(),
        },
        angle = 0,
        task = {trees = {}}
    }, { 
        __index = private
    })
end

function private:refuel()
    local base = turtle.getSelectedSlot()
    local code = inventory.parse(function(slot)
        turtle.select(slot)
        local ok, err = turtle.refuel()
        if ok then
            self.engine.current = turtle.getFuelLevel()
            return true
        end
        return false
    end)
    turtle.select(base) 
    return code
end

function _ensure_fuel(engine, fn)
    if 0 == engine.current_fuel then
        private:refuel()
    else
        fn()    
        return
    end
    _ensure_fuel(fn)
end

function private:dig(at)
    _ensure_fuel(self.engine, function()
        if "front" == at then
            turtle.dig()
        elseif "back" == at then
            self:rotate("back")
            turtle.dig()
        elseif "right" == at then
            self:rotate("right")
            turtle.dig()
        elseif "left" == at then
            self:rotate("left")
            turtle.dig()
        end
    end)
end

function private:rotate(k)
    local function turn_right_until(x)
        while self.angle ~= x do
            if (k == "left") then
                self.angle = -self.angle
            elseif (k == "front") then
                if self.angle == -90 then
                    self.angle = self.angle + 90
                else
                    self.angle = self.angle - 90
                end
            else
                self.angle = (self.angle + 90) % (180 + 1)
            end
            turtle.turnRight()
        end
    end
    if "front" == k and self.angle == 0 then
        return
    elseif "right" == k then
        turn_right_until(90)
    elseif "back" == k then
        turn_right_until(180)
    elseif "left" == k then
        turn_right_until(-90)
    elseif "front" == k then
        turn_right_until(0)
    end
end

function private:step_forward()
    _ensure_fuel(self.engine, function()
        self.space.z = self.space.z + 1
        turtle.forward()        
    end)
end

function private:step_toright()
    _ensure_fuel(self.engine, function()
        self.space.x = self.space.x + 1
        self:rotate("right")
        turtle.forward()        
    end)
end

function private:step_tolef()
    _ensure_fuel(self.engine, function()
        self.space.x = self.space.x - 1
        self:rotate("left")
        turtle.forward()
    end)
end

function private:step_up()
    _ensure_fuel(self.engine, function()
        self.space.y = self.space.y + 1
        turtle.up()
    end)   
end

function private:step_down()
    _ensure_fuel(self.engine, function()
        self.space.y = self.space.y - 1
        turtle.down()
    end)
end


function private:step_backward()
    _ensure_fuel(self.engine, function()
        self.space.z = self.space.z - 1
        self:rotate("back")
        turtle.forward()
    end)
end

return module.meta()
