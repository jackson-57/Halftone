import "ui"
import "index"
import "ui"

-- setup
playdate.setCrankSoundsDisabled(true)

-- index
local index = {}
index_files("", index)

-- init
audio_init()
init_track_ui(index)


function playdate.update()
    updateUI()
    playdate.timer:updateTimers()
end