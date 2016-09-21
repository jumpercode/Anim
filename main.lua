-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- SCENE CONFIGURATION

local ip = "res/img/"
local akeys = {a=true, right=true, left=true}
local keys = {a=false, right=false, left=false}
local last = "jump"
local pila = {{"jump", 0}}

local fondo = display.newImageRect(ip.."fondo.png", 800, 600)
fondo.x = display.contentCenterX
fondo.y = display.contentCenterY

local p1 = display.newImageRect(ip.."plataforma.png", 300, 50)
p1.x = 170
p1.y = display.contentCenterY

local p2 = display.newImageRect(ip.."plataforma.png", 300, 50)
p2.x = display.contentWidth-180
p2.y = display.contentHeight-50

local hojaSonicConfig =
{
    width = 40,
    height = 40,
    numFrames = 60
}

local sonicAnim =
{
    {
        name = "esperarDerecha",
        start = 1,
        count = 1,
        time = 16,
        loopCount = 0
    },

    {
        name = "esperarIzquierda",
        start = 11,
        count = 1,
        time = 16,
        loopCount = 0
    },

    {
        name = "correrDerecha",
        start = 21,
        count = 8,
        time = 600,
        loopCount = 0
    },

    {
        name = "correrIzquierda",
        start = 31,
        count = 8,
        time = 600,
        loopCount = 0
    },

    {
        name = "saltarDerecha",
        start = 41,
        count = 10,
        time = 1200,
        loopCount = 1
    },

    {
        name = "saltarIzquierda",
        start = 51,
        count = 10,
        time = 1200,
        loopCount = 1
    },
}

local hojaSonic = graphics.newImageSheet( ip.."sonic.png", hojaSonicConfig )
local sonic = display.newSprite( hojaSonic, sonicAnim )
sonic.x = 170
sonic.y = 0

local debug = display.newText( "", 100, 100, 200, 200, native.systemFont, 8 )
debug:setFillColor( 1, 0, 0 )

local physics = require( "physics" )
physics.start()

physics.addBody( p1, "static", { bounce=0.0 } )
physics.addBody( p2, "static", { bounce=0.0 } )
physics.addBody( sonic, "dynamic", {bounce=0.0 } )

sonic:setSequence("saltarDerecha")
sonic:play()


--- STACK CONTROLLER

local function pop()
    return table.remove(pila, 1)
end

local function tamPila()
    return table.getn(pila)
end

local function getPilaCmd()
    return pila[1][1]
end

local function setPilaCmd(cmd)
    pila[1][1] = cmd
end

local function getPilaTime()
    return pila[1][2]
end

local function apilar(cmd)

    if(tamPila() == 0) then
        table.insert( pila, 1, cmd )
    else
        if(cmd[1] == "clear" and getPilaCmd() ~= "clear") then
            table.insert( pila, 1, cmd )
        else
            if(getPilaCmd() == "jump") then
                if(cmd[1] ~= "D_a") then
                    if(tamPila() == 1) then
                        table.insert( pila, 2, cmd )
                    else
                        if(pila[2][1] ~= cmd[1]) then
                            table.insert( pila, 2, cmd )
                        end
                    end
                end
            else
                if(cmd[1] ~= getPilaCmd()) then
                    table.insert( pila, 1, cmd )
                end
            end
        end
    end

end

local function desapilar(ops)
    idx = 0
    for i,v in ipairs(pila) do
        local stop = false
        for j,o in ipairs(ops) do
            if(v[1] == o) then
                stop = true
                break
            end
        end

        if(stop) then
            idx = i
            break
        end
    end

    if(idx > 0) then
        table.remove( pila, idx )
    end
end

local function verPila()
    dbg = ""
    for i,v in ipairs(pila) do
        dbg = dbg .. v[1].." "..v[2].."\n"
    end
    dbg = dbg .. "===> " .. last .. " <==="
    debug.text = dbg
end


--- SENSORS OF EVENTS

local function onKeyEvent( event )
    if(akeys[event.keyName]) then
        if(keys[event.keyName]) then
            apilar({"U_" .. event.keyName, system.getTimer()})
        else
            apilar({"D_" .. event.keyName, system.getTimer()})
        end

        keys[event.keyName] = not(keys[event.keyName])

    end
end

Runtime:addEventListener( "key", onKeyEvent )

local function onLocalCollision( self, event )
    if(tamPila() > 0) then
        if(getPilaCmd() == "jump" and (system.getTimer()-getPilaTime()) > 300) then
            apilar({"clear", system.getTimer()})
        end
    end
end

p1.collision = onLocalCollision
p1:addEventListener( "collision" )

p2.collision = onLocalCollision
p2:addEventListener( "collision" )


--- MIAN GAME LOOP (CONTROLLER & ACTUATORS)

local function gameLoop()
    local time = system.getTimer()

    verPila()

    if(tamPila() > 0) then

        if(getPilaCmd() == "clear") then
            sonic:setLinearVelocity(0, 0)

            if(sonic.sequence == "saltarIzquierda") then
                sonic:setSequence("esperarIzquierda")
            else
                sonic:setSequence("esperarDerecha")
            end

            sonic:play()

            pop()
            pop()
            last = "clear"

        elseif(getPilaCmd() == "D_left" and last ~= "D_left") then
            setPilaCmd("esperarIzquierda")
            sonic:setSequence(getPilaCmd())
            sonic:play()
            last = "D_left"

        elseif(getPilaCmd() == "esperarIzquierda" and (time - getPilaTime()) > 100 and last ~= "esperarIzquierda") then
            setPilaCmd("correrIzquierda")
            last = "esperarIzquierda"

        elseif(getPilaCmd() == "correrIzquierda" and last ~= "correrIzquierda") then
            sonic:setLinearVelocity(0,0)
            sonic:applyLinearImpulse(-0.05, 0, sonic.x, sonic.y)
            sonic:setSequence(getPilaCmd())
            sonic:play()
            last = "correrIzquierda"

        elseif(getPilaCmd() == "U_left" and last ~= "U_left") then

            if(sonic.sequence == "correrIzquierda") then
                sonic:setLinearVelocity(0, 0)
                sonic:setSequence("esperarIzquierda")
                sonic:play()
            end

            desapilar({"D_left", "esperarIzquierda", "correrIzquierda"})
            pop()

        elseif(getPilaCmd() == "D_right" and last ~= "D_right") then
            setPilaCmd("esperarDerecha")
            sonic:setSequence(getPilaCmd())
            sonic:play()
            last = "D_right"

        elseif(getPilaCmd() == "esperarDerecha" and (time - getPilaTime()) > 100 and last ~= "esperarDerecha") then
            setPilaCmd("correrDerecha")
            last = "esperarDerecha"

        elseif(getPilaCmd() == "correrDerecha" and last ~= "correrDerecha") then
            sonic:setLinearVelocity(0,0)
            sonic:applyLinearImpulse(0.05, 0, sonic.x, sonic.y)
            sonic:setSequence(getPilaCmd())
            sonic:play()
            last = "correrDerecha"

        elseif(getPilaCmd() == "U_right" and last ~= "U_right") then
            if(sonic.sequence == "correrDerecha") then
                sonic:setLinearVelocity(0, 0)
                sonic:setSequence("esperarDerecha")
                sonic:play()
            end

            desapilar({"D_right", "esperarDerecha", "correrDerecha"})
            pop()

        elseif(getPilaCmd() == "D_a" and last ~= "D_a") then
            setPilaCmd("jump")
            last = "D_a"

        elseif(getPilaCmd() == "jump" and last ~= "jump") then
            if(sonic.sequence == "esperarIzquierda" or sonic.sequence == "correrIzquierda") then
                sonic:setSequence("saltarIzquierda")
            else
                sonic:setSequence("saltarDerecha")
            end
            sonic:play()

            sonic:applyLinearImpulse(0, -0.1, sonic.x, sonic.y)
            last = "jump"

        elseif(getPilaCmd() == "U_a" and last ~= "U_a") then
            pop()
        end

    end

end

gameTimer = timer.performWithDelay(16, gameLoop, 0)
