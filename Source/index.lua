local pd_file <const> = playdate.file
local pd_datastore <const> = playdate.datastore
local pd_metadata <const> = playdate.metadata

local function index_files(dir, index)
    for _, file in pairs(pd_file.listFiles(dir)) do
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
                    album = {title = meta.album, year = meta.year, tracks = {}}
                    artist.albums[meta.album] = album
                end

                -- table.insert(album.tracks, meta.track_number, track)
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
            end
        end
    end
end

function load_index()
    local index = {artists={}}

    index_files("", index)

    -- ---@diagnostic disable-next-line: redundant-parameter
    -- pd_datastore.write(index, "index", false)
    link_index(index)

    return index
end