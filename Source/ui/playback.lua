

local gfx = playdate.graphics

redraw_track_info = true

function update_playback(clear)
    if redraw_track_info then
        clear()

        if playing_track then
            gfx.drawTextInRect(playing_track.title, 10, 85, 140, 20, nil, "...", nil)
            gfx.drawTextInRect(playing_track.album, 10, 110, 140, 20, nil, "...", nil)
            gfx.drawTextInRect(playing_track.artist, 10, 135, 140, 20, nil, "...", nil)
        end

        redraw_track_info = false
    end
end

playdate.BButtonUp = show_menu