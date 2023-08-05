local pd_gfx <const> = playdate.graphics
local pd_timer <const> = playdate.timer
local consts <const> = ui_consts

local font = pd_gfx.getFont()

local playback_ui_timer = nil

redraw_track_info = true

function update_track_info(clear)
    if redraw_track_info then
        clear()

        if playing_track then
            pd_gfx.drawTextInRect(playing_track.title, 10, 85, 147, 20, nil, "...", nil, font)
            pd_gfx.drawTextInRect(playing_track.album.title, 10, 110, 147, 20, nil, "...", nil, font)
            pd_gfx.drawTextInRect(playing_track.artist, 10, 135, 147, 20, nil, "...", nil, font)
        end

        redraw_track_info = false
    end
end

local function update_playback_ui()
local progress_height = consts.display_height - consts.cover_size
    local duration = playing_track.duration
    local elapsed = get_playback_status()
    if not elapsed then
        elapsed = 0
    end

    local percentage_complete = elapsed / duration
    -- https://stackoverflow.com/a/18313481
    local filled_width = math.floor((consts.cover_size * percentage_complete) + 0.5)
    local unfilled_width = consts.cover_size - filled_width
    pd_gfx.setColor(pd_gfx.kColorBlack)
    pd_gfx.fillRect(consts.panel_width, consts.cover_size, filled_width, progress_height)
    pd_gfx.setColor(pd_gfx.kColorWhite)
    pd_gfx.fillRect(consts.panel_width + filled_width, consts.cover_size, unfilled_width, progress_height)
end

function setup_playback_ui_timer()
    if not playback_ui_timer then
        playback_ui_timer = pd_timer.new(1000, update_playback_ui)
        playback_ui_timer.repeats = true
    else
        playback_ui_timer:reset()
    end

    update_playback_ui()
end

function destroy_playback_ui_timer()
    if playback_ui_timer then
        playback_ui_timer:remove()
    end
end

playdate.BButtonUp = show_menu