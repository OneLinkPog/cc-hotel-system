rednet.open("top")

local ROOM_ID = 1 -- CHANGE PER ROOM
local SAVE_FILE = "room_" .. ROOM_ID .. "_data"
local redstoneSide = "top"

local detector = peripheral.find("playerDetector")
if not detector then
    error("Player detector not found!")
end

local allowed = {}
local forceOpenUntil = 0

-- LOAD DATA
local function loadData()
    if fs.exists(SAVE_FILE) then
        local f = fs.open(SAVE_FILE, "r")
        local data = textutils.unserialize(f.readAll())
        f.close()
        return data or {}
    end
    return {}
end

-- SAVE DATA
local function saveData()
    local f = fs.open(SAVE_FILE, "w")
    f.write(textutils.serialize(allowed))
    f.close()
end

-- Initialize from disk
allowed = loadData()

-- CHECK ACCESS
local function isAllowed(player)
    for _, name in ipairs(allowed) do
        if name == player then
            return true
        end
    end
    return false
end

-- LISTEN FOR SERVER
local function listen()
    while true do
        local id, msg = rednet.receive()

        if type(msg) == "table" then

            -- Update guest list
            if msg.type == "update_room" and msg.room == ROOM_ID then
                allowed = msg.guests or {}
                saveData()
                print("Guest list updated & saved")

            -- Force open
            elseif msg.type == "force_open" and msg.room == ROOM_ID then
                forceOpenUntil = os.clock() + (msg.duration or 20)
                print("REMOTE UNLOCK ACTIVE")
            end

        end
    end
end

-- DOOR LOOP
local function doorLoop()
    while true do
        local now = os.clock()
        local open = false

        if now < forceOpenUntil then
            open = true
        else
            local players = detector.getPlayersInRange(2)

            for _, p in ipairs(players) do
                if isAllowed(p) then
                    open = true
                    print("Welcome " .. p)
                    break
                end
            end
        end

        redstone.setOutput(redstoneSide, open)
        sleep(0.5)
    end
end

print("Room " .. ROOM_ID .. " door system online (persistent)")

parallel.waitForAny(listen, doorLoop)
