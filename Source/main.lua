-- global tables
UI = {}

-- imports
import "ui/consts"
import "consts"
import "splash/empty"
import "index"
import "playback"
import "ui/ui"

-- consts
local pd_file <const> = playdate.file
local pd_meta <const> = playdate.metadata
local pd_timer <const> = playdate.timer
local pd_getelapsed <const> = playdate.getElapsedTime
local ui <const> = UI

-- profiling
function log_time(name)
    local time = pd_getelapsed()
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

-- update
local function post_initialization_update()
    audio_update()
    ui.update()
    pd_timer.updateTimers()
end

-- initialization
function playdate.update()
    -- setup
    log_file(pd_meta.name .. " " .. pd_meta.version .. " (" .. pd_meta.buildNumber .. ")", true)
    playdate.setCrankSoundsDisabled(true)
    pd_file.mkdir(consts.app_dir)

    -- index
    local index = init_index()
    if not index then
        error("Failed to load index")
        playdate.stop()
        return
    end

    -- empty library splash
    if #index.tracks == 0 then
        empty_library_splash()
        print("Library is empty, stopping initialization")
        playdate.stop()
        return
    end

    -- subsystem initialization
    audio_init()
    ui.init(index)

    -- set post-initialization update loop
    playdate.update = post_initialization_update
end