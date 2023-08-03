-- globals
playing_track = nil

function play_track(track)
    playing_track = track
    set_playback(playing_track.path)

    playdate.resetElapsedTime()
    index_image(playing_track.path)
    log_time("index image")

    setup_playback_ui_timer()
end