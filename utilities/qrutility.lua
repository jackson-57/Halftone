-- Setup:
if not playdate.isSimulator then
    error("Simulator only.")
    return
end

import "CoreLibs/timer"
import "CoreLibs/qrcode"

playdate.graphics.drawText("*Open the console to use this utility.*", 10, 10)

-- Usage:
print("Run save_qr(string, [size, filename, path]) to generate a QR code for `string` and save it as `filename`.png in `path`. If `filename` is nil, then the current time (in seconds since the epoch) is used instead. If `path` is nil, the home directory is used. Set `path` to \"\" to save to the working directory. \n\nAdapted from the Playdate SDK docs:\n`size` lets you specify an approximate edge dimension in pixels for the desired QR code, though the generator has limited flexibility in sizing QR codes, based on the amount of information to be encoded, and the restrictions of a 1-bit screen. The generator will attempt to generate a QR code smaller than `size` if possible. (Note that QR codes always have the same width and height.)\n\nIf you specify nil for `size`, the saved image will balance small size with easy readability. If you specify 0, the saved image will be the smallest possible QR code for the specified string.")

function save_qr(str, size, name, path)
    local callback = function (image, err)
        if err then
            error(err)
            return
        end

        if not name then
            name = playdate.getSecondsSinceEpoch()
        end

        if not path then
            path = "~"
        end

        playdate.simulator.writeToFile(image, path .. "/" .. name .. ".png")
        print("QR code generated and saved in " .. playdate.getElapsedTime() .. " seconds.")
    end

    print("Generating...")
    playdate.resetElapsedTime()
    playdate.graphics.generateQRCode(str, size, callback)
end

function playdate.update()
    playdate.timer.updateTimers()
end