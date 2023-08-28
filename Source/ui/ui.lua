import "CoreLibs/ui/gridview"
import "CoreLibs/nineslice"
import "CoreLibs/sprites"
import "CoreLibs/object"

import "consts"
import "seeking"

import "sideviews/barsideview"
import "sideviews/art"
import "sideviews/duration"

import "panel"
import "panels/listpanel"
import "panels/nowplaying"
import "panels/menu"
import "panels/artists"
import "panels/albums"
import "panels/tracks"
import "panels/settings"

local pd_gfx <const> = playdate.graphics
local pd_sprite <const> = pd_gfx.sprite
local ui <const> = UI

function ui.init(index)
    ui.artsideview = ArtSideview()
    ui.playback_panel = NowPlaying()
    ui.durationsideview = DurationSideview()
    Menu(index)

    playdate.AButtonUp = toggle_playing
    playdate.BButtonUp = function ()
        Menu(index)
    end
    playdate.leftButtonDown = function ()
        ui.seeking.start_seek_timer(playdate.kButtonLeft)
    end
    playdate.rightButtonDown = function ()
        ui.seeking.start_seek_timer(playdate.kButtonRight)
    end
end

function ui.update()
    ui.seeking.seek_update()
    pd_sprite.update()
end

function ui.set_track(track)
    ui.track = track

    ui.artsideview:set_album(track.album)
    ui.playback_panel:refresh()
    ui.durationsideview:refresh()

    ui.toggle_playing(true)
end

function ui.toggle_playing(playing)
    ui.durationsideview:setUpdatesEnabled(playing)
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