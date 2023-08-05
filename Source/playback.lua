-- globals
-- playing_track = nil

function play_track(track)
    -- playing_track = track
    set_playback(track.path)

    set_track_ui(track)
end