import "CoreLibs/string"

local pd <const> = playdate
local pd_file <const> = pd.file
local pd_datastore <const> = pd.datastore
local pd_uuid <const> = pd.string.UUID
local logging <const> = Logging
local engine <const> = Engine
local tbl <const> = table
local coro_yield <const> = coroutine.yield

local consts <const> = consts

local saved_index_path <const> = consts.app_dir .. "library.idx"
local album_art_path <const> = consts.app_dir .. "art_cache/"
local uuid_length <const> = 10
local unknown_album <const> = "Unknown Album"
local unknown_artist <const> = "Unknown Artist"

local function scan_files(dir, callback)
    for _, file in pairs(pd_file.listFiles(dir)) do
        if pd_file.isdir(file) then
            scan_files(dir .. file, callback)
        elseif file:match("[^.]+$") == "opus" then
            callback(dir, file)
        end
    end
end

local function count_bytes()
    local total = 0

    scan_files("", function (dir, file)
---@diagnostic disable-next-line: cast-local-type
        total += pd_file.getSize(dir .. file)
    end)

    return total
end

local function index_files()
    local index = {artists={}}
    local named_index = {}

    local cb = function (dir, file)
        local path = dir .. file
        local meta_duration, meta_title, meta_album, meta_artist, meta_album_artist, meta_year, meta_track_number = engine.parse_metadata(path)
        if meta_duration then
            -- substitute missing required metadata
            if not meta_title then meta_title = file:match("(.+)%..+") end
            if not meta_album then meta_album = unknown_album end
            if not meta_artist then meta_artist = unknown_artist end
            if not meta_album_artist then meta_album_artist = unknown_artist end

            local track = {path=path, title=meta_title, artist=meta_artist, duration = meta_duration, number=meta_track_number}

            local artist = nil
            local named_artist = named_index[meta_album_artist]
            -- create artist if not present
            if not named_artist then
                artist = {name = meta_album_artist, albums = {}}
                named_artist = {artist = artist, albums = {}}
                named_index[meta_album_artist] = named_artist
                tbl.insert(index.artists, artist)
            else
                artist = named_artist.artist
            end

            local album = named_artist.albums[meta_album]
            -- create album if not present
            if not album then
                album = {title = meta_album, year = meta_year, tracks = {}, art_uuid=pd_uuid(uuid_length)}
                named_artist.albums[meta_album] = album
                tbl.insert(artist.albums, album)
            end

            tbl.insert(album.tracks, track)

            coro_yield()
        end
    end

    scan_files("", cb)

    return index
end

local function compare_artist_names(artist_1, artist_2)
    return artist_1.name < artist_2.name
end

local function compare_album_titles(album_1, album_2)
    return album_1.title < album_2.title
end

local function compare_track_numbers(track_1, track_2)
    return track_1.number < track_2.number
end

local function compare_track_titles(track_1, track_2)
    return track_1.title < track_2.title
end

local function sort_index(index)
    tbl.sort(index.artists, compare_artist_names)

    for _, artist in pairs(index.artists) do
        tbl.sort(artist.albums, compare_album_titles)

        for _, album in pairs(artist.albums) do
            tbl.sort(album.tracks, compare_track_numbers)
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
            tbl.insert(index.albums, album)

            for _, track in pairs(album.tracks) do
                track.album = album
                tbl.insert(index.tracks, track)
            end
        end
    end
end

local function sort_index_links(index)
    tbl.sort(index.albums, compare_album_titles)
    tbl.sort(index.tracks, compare_track_titles)
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
        -- Skip indexing art for unknown album
        if album.title == unknown_album then return end

        -- (Hack) Write art to disk from Lua
        local art_batch = {engine.process_art(album.tracks[1].path, tbl.unpack(consts.cover_art_sizes))}

        for i, art in pairs(art_batch) do
            pd_datastore.writeImage(art, album_art_path .. consts.cover_art_sizes[i] .. "/" .. album.art_uuid .. ".pdi")
        end

        coro_yield()
    end
end

function init_index()
    -- Optimize yielding
    local normal_refresh_rate = pd.display.getRefreshRate()
    pd.display.setRefreshRate(0)

    -- Get total size of all audio files
    logging.reset_time()
    local byte_count = count_bytes()
    logging.log_time("byte count")

    -- Attempt to load saved index
    logging.reset_time()
    local clean_index = false
    local index = load_saved_index(byte_count)
    logging.log_time("loading saved index")

    -- Build the index if the returned index is nil, sort, and save
    if not index then
        clean_index = true

        logging.reset_time()
        index = index_files()
        logging.log_time("building index")

        logging.reset_time()
        sort_index(index)
        logging.log_time("sorting index")

        logging.reset_time()
        save_index(index, byte_count)
        logging.log_time("saving index")
    end

    -- Add references, then sort them
    logging.reset_time()
    link_index(index)
    logging.log_time("linking index")

    logging.reset_time()
    sort_index_links(index)
    logging.log_time("sorting index links")

    -- Process album art if missing or a clean index
    if clean_index or check_art() then
        logging.reset_time()
        index_art(index)
        logging.log_time("processing album art")
    end

    -- Reset yielding optimization
    pd.display.setRefreshRate(normal_refresh_rate)

    return index
end