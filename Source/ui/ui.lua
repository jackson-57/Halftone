import "CoreLibs/ui/gridview"
import "CoreLibs/nineslice"
import "CoreLibs/sprites"
import "CoreLibs/object"

import "consts"

import "sideview"
import "sideviews/art"
import "sideviews/duration"

import "panel"
import "listpanel"
import "panels/nowplaying"
import "panels/menu"
import "panels/artists"
import "panels/albums"
import "panels/tracks"
import "panels/settings"

local pd_gfx <const> = playdate.graphics
local pd_sprite <const> = pd_gfx.sprite
local consts <const> = ui_consts

playback_panel = nil
sideview = nil

function init_ui(index)
    playback_panel = NowPlaying()
    sideview = Sideview()
    Menu(index)

    playdate.BButtonUp = function ()
        Menu(index)
    end
end

function update_ui()
    pd_sprite.update()
end

function set_track_ui(track)
    playback_panel.track = track
    sideview.duration.track = track

    playdate.resetElapsedTime()
    sideview.art:setImage(index_art(track.path, consts.cover_size_full))
    log_time("index art")

    playback_panel:update()
    sideview.duration:setup_timer()
end

-- https://chat.openai.com/share/9baf2769-261c-4051-be8c-b17c7c722973
function sec_to_hms(sec)
    local hours = math.floor(sec / 3600)
    local minutes = math.floor((sec % 3600) / 60)
    local seconds = sec % 60

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, seconds)
    else
        return string.format("%d:%02d", minutes, seconds)
    end
end