local pd <const> = playdate

-- global tables
UI = {}
Logging = {}
Playback = {}

-- font override
pd.graphics.setFont(pd.graphics.font.new("resources/Asheville Ayu"))
pd.graphics.setFont(pd.graphics.font.new("resources/Asheville Ayu Bold"), pd.graphics.font.kVariantBold)

-- imports
import "logging"
import "ui/consts"
import "consts"
import "splash/empty"
import "index"
import "playback"
import "ui/ui"

-- consts
local pd_updatetimers <const> = pd.timer.updateTimers
local ui <const> = UI
local logging <const> = Logging
local engine <const> = Engine

-- update
local function post_initialization_update()
    engine.audio_update()
    ui.update()
    pd_updatetimers()
end

-- initialization
function pd.update()
    -- setup
    logging.log_file(pd.metadata.name .. " " .. pd.metadata.version .. " (" .. pd.metadata.buildNumber .. ")", true)
    pd.setCrankSoundsDisabled(true)
    pd.file.mkdir(consts.app_dir)

    -- index
    local index = init_index()
    if not index then
        error("Failed to load index")
        pd.stop()
        return
    end

    -- empty library splash
    if #index.tracks == 0 then
        empty_library_splash()
        print("Library is empty, stopping initialization")
        pd.stop()
        return
    end

    -- subsystem initialization
    engine.audio_init()
    ui.init(index)

    -- set post-initialization update loop
    pd.update = post_initialization_update
end