local pd <const> = playdate
local timer_new <const> = pd.timer.new
local pd_input <const> = pd.inputHandlers
local ui <const> = UI
local playback <const> = Playback
local engine <const> = Engine

local seek_hold_delay <const> = 300
local seek_amount <const> = 2

local seek_timer = nil
local seek_direction = nil

local seeking = {}
ui.seeking = seeking

function seeking.start_seek_timer(direction)
    if seek_direction or not ui.track then return end
    seek_direction = direction

    seek_timer = timer_new(seek_hold_delay, function ()
        playback.toggle_playing(false)
        seek_timer = nil
        local durationsv = ui.durationsideview
        durationsv.seek_width = durationsv:calculate_width(durationsv:get_elapsed())
    end)

    local seeking_input_handlers = {
        leftButtonUp = seeking.end_seeking,
        rightButtonUp = seeking.end_seeking
    }
    -- Disable other input during seeking
    pd_input.push(seeking_input_handlers, true)
end

function seeking.seek_update()
    if not seek_direction or seek_timer then return end
    local durationsv = ui.durationsideview

    if seek_direction == pd.kButtonLeft then
        durationsv.seek_width -= seek_amount
        if durationsv.seek_width <= 0 then
            durationsv.seek_width = 0
            seeking.end_seeking()
        end
    else
        durationsv.seek_width += seek_amount
        if durationsv.seek_width >= durationsv.width then
            durationsv.seek_width = durationsv.width
            seeking.end_seeking()
        end
    end

    durationsv:markDirty()
end

function seeking.end_seeking()
    if seek_timer then
        seek_timer:remove()
        seek_timer = nil

        if seek_direction == pd.kButtonLeft then
            playback.play_previous()
        else
            playback.play_next()
        end
    else
        engine.seek_playback(ui.durationsideview:calculate_elapsed())
        ui.durationsideview.seek_width = nil
        playback.toggle_playing(true)
    end

    pd_input.pop()
    seek_direction = nil
end