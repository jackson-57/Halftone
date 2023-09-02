import "CoreLibs/string"

local pd_file <const> = playdate.file
local pd_datastore <const> = playdate.datastore
local pd_uuid <const> = playdate.string.UUID
local pd_display <const> = playdate.display

local consts <const> = consts

local saved_index_path <const> = consts.app_dir .. "library.idx"
local album_art_path <const> = consts.app_dir .. "art_cache/"
local uuid_length <const> = 10

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
                album = {title = meta_album, year = meta_year, tracks = {}, art_uuid=pd_uuid(uuid_length)}
                named_artist.albums[meta_album] = album
                table.insert(artist.albums, album)
            end

            -- table.insert(album.tracks, meta_track_number, track)
            table.insert(album.tracks, track)

            coroutine.yield()
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

local function check_art()
    -- Check album art presence
    local clean = false

    for _, size in pairs(consts.cover_art_sizes) do
        if not pd_file.isdir(album_art_path .. size) then
            clean = true
            break
        end
    end

    return clean
end

local function index_art(index)
    -- Clear directory
    pd_file.delete(album_art_path, true)

    -- Recreate directories
    for _, size in pairs(consts.cover_art_sizes) do
        pd_file.mkdir(album_art_path .. size)
    end

    for _, album in pairs(index.albums) do
        -- (Hack) Write art to disk from Lua
        local art_batch = {process_art(album.tracks[1].path, table.unpack(consts.cover_art_sizes))}

        for i, art in pairs(art_batch) do
            pd_datastore.writeImage(art, album_art_path .. consts.cover_art_sizes[i] .. "/" .. album.art_uuid .. ".pdi")
        end

        coroutine.yield()
    end
end

function init_index()
    -- Optimize yielding
    local normal_refresh_rate = pd_display.getRefreshRate()
    pd_display.setRefreshRate(0)

    -- Get total size of all audio files
    playdate.resetElapsedTime()
    local byte_count = count_bytes()
    log_time("byte count")

    -- Attempt to load saved index
    playdate.resetElapsedTime()
    local clean_index = false
    local index = load_saved_index(byte_count)
    log_time("loading saved index")

    -- Build the index if the returned index is nil, save
    if not index then
        clean_index = true

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

    -- Process album art if missing or a clean index
    if clean_index or check_art() then
        playdate.resetElapsedTime()
        index_art(index)
        log_time("processing album art")
    end

    -- Reset yielding optimization
    pd_display.setRefreshRate(normal_refresh_rate)

    return index
end