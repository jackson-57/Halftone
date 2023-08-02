import "index"
import "ui/ui"

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