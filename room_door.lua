-- Open modem
rednet.open("top")

-- CHANGE THIS PER ROOM
local ROOM_ID = 1

-- Find player detector
local detector = peripheral.find("playerDetector")
if not detector then
    error("Player detector not found!")
end

local allowed = {}
local forceOpenUntil = 0

-- CHECK IF PLAYER ALLOWED
local function isAllowed(player)
    for _, name in ipairs(allowed) do
        if name == player then
            return true
        end
    end
    return false
end

-- LISTEN FOR SERVER UPDATES
local function listen()
    while true do
        local id, msg = rednet.receive()

        if type(msg) == "table" then

            -- Update guest list
            if msg.type == "update_room" and msg.room == ROOM_ID then
                allowed = msg.guests or {}
                print("Guest list updated")

            -- Force open command
            elseif msg.type == "force_open" and msg.room == ROOM_ID then
                forceOpenUntil = os.clock() + (msg.duration or 20)
                print("REMOTE UNLOCK ACTIVE")
            end

        end
    end
end

-- DOOR CONTROL LOOP
local function doorLoop()
    while true do
        local now = os.clock()
        local open = false

        -- Force override
        if now < forceOpenUntil then
            open = true
        else
            local players = detector.getPlayersInRange(3)

            for _, p in ipairs(players) do
                if isAllowed(p) then
                    open = true
                    print("Welcome " .. p)
                    break
                end
            end
        end

        redstone.setOutput("front", open)
        sleep(0.5)
    end
end

print("Room " .. ROOM_ID .. " door system online")

parallel.waitForAny(listen, doorLoop)
