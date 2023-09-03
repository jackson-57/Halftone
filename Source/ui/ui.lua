import "CoreLibs/ui/gridview"
import "CoreLibs/nineslice"
import "CoreLibs/sprites"
import "CoreLibs/object"

import "consts"
import "seeking"

local ui <const> = UI
ui.sideviews = {}
ui.panels = {}

import "sideviews/barsideview"
import "sideviews/art"
import "sideviews/duration"

import "panels/listpanel"
import "panels/nowplaying"
import "panels/menu"
import "panels/artists"
import "panels/albums"
import "panels/tracks"
import "panels/settings"

local pd <const> = playdate
local pd_gfx <const> = pd.graphics
local pd_sprite <const> = pd_gfx.sprite
local math_floor <const> = math.floor
local string_format <const> = string.format

function ui.init(index)
    ui.artsideview = ui.sideviews.ArtSideview()
    ui.playback_panel = ui.panels.NowPlaying()
    ui.durationsideview = ui.sideviews.DurationSideview()
    ui.panels.Menu(index)

    pd.AButtonUp = Playback.toggle_playing
    pd.BButtonUp = function () ui.panels.Menu(index) end
    pd.leftButtonDown = function () ui.seeking.start_seek_timer(pd.kButtonLeft) end
    pd.rightButtonDown = function () ui.seeking.start_seek_timer(pd.kButtonRight) end
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
    pd.setAutoLockDisabled(playing)
end

-- https://chat.openai.com/share/9baf2769-261c-4051-be8c-b17c7c722973
function ui.sec_to_hms(sec)
    local hours = math_floor(sec / 3600)
    local minutes = math_floor((sec % 3600) / 60)
    local seconds = sec % 60

    if hours > 0 then
        return string_format("%d:%02d:%02d", hours, minutes, seconds)
    else
        return string_format("%d:%02d", minutes, seconds)
    end
end