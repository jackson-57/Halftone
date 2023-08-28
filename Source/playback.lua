local ui <const> = UI

local queue = nil
local queue_position = nil

function set_queue(tracks, pos)
    queue = tracks
    queue_position = pos

    play_track(tracks[pos])
end

function play_track(track)
    set_playback(track.path)

    ui.set_track(track)
end

function toggle_playing(playing)
    local playing_result = toggle_playback(playing)
    if playing_result == nil then return end
    ui.toggle_playing(playing_result)
end

function play_previous()
    if not queue then return end

    if get_playback_status() < 5 and queue[queue_position - 1] then
        queue_position -= 1
        play_track(queue[queue_position])
    else
        seek_playback(0)
    end
end

function play_next()
    if not queue then return end

    if queue[queue_position + 1] then
        queue_position += 1
        play_track(queue[queue_position])
    else
        toggle_playing(false)
    end
end