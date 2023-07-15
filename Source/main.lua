import "ui"
import "index"
import "ui"

-- setup
playdate.setCrankSoundsDisabled(true)

local index = {}
index_files("", index)
init_track_ui(index)


function playdate.update()
    updateUI()
    playdate.timer:updateTimers()
end