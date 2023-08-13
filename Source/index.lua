local pd_file <const> = playdate.file
-- local pd_datastore <const> = playdate.datastore
-- local pd_metadata <const> = playdate.metadata

local debug_track_count = 0

local function index_files(dir, index, named_index)
    if not named_index then
        named_index = {}
    end

    for _, file in pairs(pd_file.listFiles(dir)) do
        if pd_file.isdir(file) then
            index_files(dir .. file, index, named_index)
        elseif string.match(file, "[^.]+$") == "opus" then
            local path = dir .. file
            local meta_duration, meta_title, meta_album, meta_artist, meta_album_artist, meta_year, meta_track_number = index_file(path)
            if meta_duration then
                local track = {path=path, title=meta_title, artist=meta_artist, duration = meta_duration}

                local artist = nil
                local named_artist = named_index[meta_album_artist]
                -- create artist if not present
                if not named_artist then
                    artist = {name = meta_album_artist, albums = {}}
                    named_artist = {artist = artist, albums = {}}
                    named_index[meta_album_artist] = named_artist
                    table.insert(index.artists, artist)
                else
                    artist = named_artist.artist
                end

                local album = named_artist.albums[meta_album]
                -- create album if not present
                if not album then
                    album = {title = meta_album, year = meta_year, tracks = {}}
                    named_artist.albums[meta_album] = album
                    table.insert(artist.albums, album)
                end

                -- table.insert(album.tracks, meta_track_number, track)
                table.insert(album.tracks, track)
            end
        end
    end
end

local function link_index(index)
    -- Add references to index
    index.albums = {}
    index.tracks = {}
    for _, artist in pairs(index.artists) do
        for _, album in pairs(artist.albums) do
            album.artist = artist
            table.insert(index.albums, album)

            for _, track in pairs(album.tracks) do
                track.album = album
                table.insert(index.tracks, track)
                debug_track_count += 1
            end
        end
    end
end

function load_index()
    local index = {artists={}}

    playdate.resetElapsedTime()
    index_files("", index)
    log_time("index")

    -- playdate.resetElapsedTime()
    -- ---@diagnostic disable-next-line: redundant-parameter
    -- pd_datastore.write(index, "index", false)
    -- print(playdate.getElapsedTime())

    link_index(index)

    log_file("indexed " .. debug_track_count .. " tracks")

    return index
end