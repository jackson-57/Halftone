import "ui/consts"
import "consts"
import "index"
import "playback"
import "ui/ui"

-- profiling
local pd_file <const> = playdate.file
local pd_meta <const> = playdate.metadata

function log_time(name)
    local time = playdate.getElapsedTime()
    log_file(name .. ": " .. time .. "s")
end

function log_file(str, reset)
    print(str)

    local filemode = pd_file.kFileAppend
    if reset then
        filemode = pd_file.kFileWrite
    end

    local file = pd_file.open("log.txt", filemode)
    if file then
        file:write(str .. '\n')
        file:close()
    end
end

log_file(pd_meta.name .. " " .. pd_meta.version .. " (" .. pd_meta.buildNumber .. ")", true)

-- setup
playdate.setCrankSoundsDisabled(true)
pd_file.mkdir(consts.app_dir)

-- index
local index = init_index()
if not index then
    print("Failed to load index")
    do return end
end

-- init
audio_init()
init_ui(index)

function playdate.update()
    audio_update()
    update_ui()
    playdate.timer:updateTimers()
end