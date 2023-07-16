import "index"
import "ui/ui"

-- globals
playing_track = nil

-- setup
playdate.setCrankSoundsDisabled(true)

-- index
local index = {}
index_files("", index)

-- init
audio_init()
init_ui(index)

function playdate.update()
    update_ui()
    playdate.timer:updateTimers()
end