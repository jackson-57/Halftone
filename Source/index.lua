local pd_file <const> = playdate.file

function index_files(dir, index)
    for k, file in pairs(pd_file.listFiles(dir)) do
        if pd_file.isdir(file) then
            index_files(dir .. file, index)
        elseif string.match(file, "[^.]+$") == "opus" then
            local path = dir .. file
            local meta = {}
            meta.duration, meta.title, meta.album, meta.artist, meta.album_artist, meta.year, meta.track_number = index_file(path)
            if meta.duration then
                local track = {path=path, title=meta.title, artist=meta.artist}

                local artist = index.artists[meta.album_artist]
                -- create artist if not present
                if not artist then
                    artist = {name = meta.album_artist, albums = {}}
                    index.artists[meta.album_artist] = artist
                end

                local album = artist.albums[meta.album]
                -- create album if not present
                if not album then
                    album = {title = meta.album, artist = artist, year = meta.year, tracks = {}}
                    artist.albums[meta.album] = album
                    table.insert(index.albums, album)
                end

                -- add references
                track.album = album
                -- table.insert(album.tracks, meta.track_number, track)
                table.insert(album.tracks, track)
                table.insert(index.tracks, track)
            end
        end
    end
end