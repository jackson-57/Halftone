import "index"
import "ui/ui"

-- globals
playing_track = nil

-- setup
playdate.setCrankSoundsDisabled(true)

-- index
local index = {tracks = {}, albums = {}, artists={}}
index_files("", index)
link_index(index)

-- init
audio_init()
init_ui(index.tracks)

function playdate.update()
    update_ui()
    playdate.timer:updateTimers()
end