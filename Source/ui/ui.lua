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

playback_panel = nil
sideview = nil

function init_ui(index)
    playback_panel = NowPlaying()
    sideview = Sideview()
    Tracks(index.tracks)

    playdate.BButtonUp = function ()
        Tracks(index.tracks)
    end
end

function update_ui()
    pd_sprite.update()
end

function set_track_ui(track)
    playback_panel.track = track
    sideview.duration.track = track

    playdate.resetElapsedTime()
    sideview.art:setImage(index_art(track.path))
    log_time("index art")

    playback_panel:update()
    sideview.duration:setup_timer()
end