local pd_file <const> = playdate.file

function index_files(dir, index)
    for k, file in pairs(pd_file.listFiles(dir)) do
        if pd_file.isdir(file) then
            index_files(dir .. file, index)
        elseif string.match(file, "[^.]+$") == "opus" then
            track = {path=dir .. file}
            track.duration, track.title, track.album, track.artist, track.album_artist, track.year, track.track_number = index_file(dir .. file)
            if track.duration then
                table.insert(index, track)
            end
        end
    end
end