local pd_file <const> = playdate.file

local saved_index_path <const> = app_dir .. "library.idx"

local function scan_files(dir, callback)
    for _, file in pairs(pd_file.listFiles(dir)) do
        if pd_file.isdir(file) then
            scan_files(dir .. file, callback)
        elseif string.match(file, "[^.]+$") == "opus" then
            callback(dir .. file)
        end
    end
end

local function count_bytes()
    local total = 0

    scan_files("", function (path)
---@diagnostic disable-next-line: cast-local-type
        total += pd_file.getSize(path)
    end)

    return total
end

local function index_files()
    local index = {artists={}}
    local named_index = {}

    local cb = function (path)
        local meta_duration, meta_title, meta_album, meta_artist, meta_album_artist, meta_year, meta_track_number = parse_metadata(path)
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

    scan_files("", cb)

    return index
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

local function load_saved_index(byte_count)
    -- If index file exists, open, and compare byte counts
    if not pd_file.exists(saved_index_path) then return end
    local file = pd_file.open(saved_index_path)
    if not file then return end

    -- Byte count is stored on the first line of the saved index file
    local saved_byte_count = tonumber(file:readline())
    if saved_byte_count ~= byte_count then return end

    -- Read JSON from remainder of file, then close file
    local index = json.decodeFile(file)
    file:close()

    return index
end

local function save_index(index, byte_count)
    -- Create new index file
    local file = pd_file.open(saved_index_path, pd_file.kFileWrite)
    if not file then return end

    -- Write byte count and JSON
    file:write(byte_count .. "\n")
    json.encodeToFile(file, false, index)
    file:close()
end

function init_index()
    -- Get total size of all audio files
    playdate.resetElapsedTime()
    local byte_count = count_bytes()
    log_time("byte count")

    -- Attempt to load saved index
    playdate.resetElapsedTime()
    local index = load_saved_index(byte_count)
    log_time("loading saved index")

    -- Build the index if the returned index is nil, save
    if not index then
        playdate.resetElapsedTime()
        index = index_files()
        log_time("building index")

        playdate.resetElapsedTime()
        save_index(index, byte_count)
        log_time("saving index")
    end

    -- Add references
    playdate.resetElapsedTime()
    link_index(index)
    log_time("linking index")

    return index
end