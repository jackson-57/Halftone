import "index"
import "ui/ui"

-- profiling
local pd_file <const> = playdate.file

local file = pd_file.open("log.txt", pd_file.kFileWrite)
if file then
    file:write("pdaudio public demo v0.1\n")
    file:close()
end

function log_time(name)
    local time = playdate.getElapsedTime()
    local str = name .. ": " .. time .. "s"
    print(str)

    local file = pd_file.open("log.txt", pd_file.kFileAppend)
    if file then
        file:write(str .. '\n')
        file:close()
    end
end

playdate.resetElapsedTime()
log_time("test")

-- globals
playing_track = nil

-- setup
playdate.setCrankSoundsDisabled(true)

-- index
local index = load_index()
if not index then
    print("Failed to load index")
    do return end
end

-- init
audio_init()
init_ui(index.tracks)

function playdate.update()
    update_ui()
    playdate.timer:updateTimers()
end