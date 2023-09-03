local ui <const> = UI
local playback <const> = Playback
local engine <const> = Engine

local queue = nil
local queue_position = nil

function playback.set_queue(tracks, pos)
    queue = tracks
    queue_position = pos

    playback.play_track(tracks[pos])
end

function playback.play_track(track)
    engine.set_playback(track.path)

    ui.set_track(track)
end

function playback.toggle_playing(playing)
    local playing_result = engine.toggle_playback(playing)
    if playing_result == nil then return end
    ui.toggle_playing(playing_result)
end

function playback.play_previous()
    if not queue then return end

    if engine.get_playback_status() < 5 and queue[queue_position - 1] then
        queue_position -= 1
        playback.play_track(queue[queue_position])
    else
        engine.seek_playback(0)
    end
end

function playback.play_next()
    if not queue then return end

    if queue[queue_position + 1] then
        queue_position += 1
        playback.play_track(queue[queue_position])
    else
        playback.toggle_playing(false)
    end
end