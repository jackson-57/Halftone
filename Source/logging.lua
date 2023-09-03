local pd <const> = playdate
local pd_file <const> = pd.file
local pd_getelapsed <const> = pd.getElapsedTime
local logging <const> = Logging

logging.reset_time = pd.resetElapsedTime

function logging.log_time(name)
    local time = pd_getelapsed()
    logging.log_file(name .. ": " .. time .. "s")
end

function logging.log_file(str, reset)
    print(str)

    local filemode = pd_file.kFileAppend
    if reset then
        filemode = pd_file.kFileWrite
    end

    local file = pd_file.open("log.txt", filemode)
    if file then
        file:write(str .. '\n')
        file:close()
    end
end
