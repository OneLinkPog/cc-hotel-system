-- Open modem (change side if needed)
rednet.open("top")

local dataFile = "hotel_data"

-- LOAD / SAVE
local function loadData()
    if fs.exists(dataFile) then
        local f = fs.open(dataFile, "r")
        local d = textutils.unserialize(f.readAll())
        f.close()
        return d
    end
    return {rooms = {}}
end

local function saveData(data)
    local f = fs.open(dataFile, "w")
    f.write(textutils.serialize(data))
    f.close()
end

local hotel = loadData()

-- Ensure rooms exist
for i = 1, 10 do
    hotel.rooms[i] = hotel.rooms[i] or {guests = {}}
end

-- SEND ROOM UPDATE
local function updateRoom(room)
    rednet.broadcast({
        type = "update_room",
        room = room,
        guests = hotel.rooms[room].guests
    })
end

-- SHOW ROOMS
local function showRooms()
    print("\n=== ROOM STATUS ===")
    for i, r in pairs(hotel.rooms) do
        if #r.guests > 0 then
            print("Room " .. i .. ": " .. table.concat(r.guests, ", "))
        else
            print("Room " .. i .. ": EMPTY")
        end
    end
end

-- CHECK IN
local function checkIn()
    print("Room number:")
    local room = tonumber(read())
    if not hotel.rooms[room] then
        print("Invalid room")
        return
    end

    print("Guest name:")
    local name = read()

    table.insert(hotel.rooms[room].guests, name)

    saveData(hotel)
    updateRoom(room)

    print("Checked in " .. name)
end

-- CHECK OUT
local function checkOut()
    print("Room number:")
    local room = tonumber(read())
    if not hotel.rooms[room] then
        print("Invalid room")
        return
    end

    hotel.rooms[room].guests = {}

    saveData(hotel)
    updateRoom(room)

    print("Room " .. room .. " cleared")
end

-- FORCE OPEN (20 SECONDS)
local function forceOpenRoom()
    print("Room number to unlock:")
    local room = tonumber(read())

    if not hotel.rooms[room] then
        print("Invalid room")
        return
    end

    rednet.broadcast({
        type = "force_open",
        room = room,
        duration = 20
    })

    print("Room " .. room .. " unlocked for 20 seconds")
end

-- MAIN LOOP
while true do
    print("\n=== HOTEL SYSTEM ===")
    print("1. View Rooms")
    print("2. Check In")
    print("3. Check Out")
    print("4. Force Open Room (20s)")
    print("5. Exit")

    local choice = read()

    if choice == "1" then
        showRooms()
    elseif choice == "2" then
        checkIn()
    elseif choice == "3" then
        checkOut()
    elseif choice == "4" then
        forceOpenRoom()
    elseif choice == "5" then
        print("Goodbye")
        break
    else
        print("Invalid option")
    end
end
