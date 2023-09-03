local pd <const> = playdate
local pd_gfx <const> = pd.graphics

local display_width <const> = pd.display.getWidth()
local display_height <const> = pd.display.getHeight()
local margin <const> = 8
local spacer <const> = 5
local splash_header <const> = "*Your library is empty.*"
local splash_message <const> = "Welcome to " .. pd.metadata.name .. "! Let's get you set up.\nTo add tracks to your library, put your Playdate in Data Disk mode, and place .opus files in the Data/" .. pd.metadata.bundleID .. "/ directory."
local qr_message <const> = "For conversion instructions and a setup guide, please scan the\nQR code, or visit github.com/jackson-57/Halftone/."
local qr <const> = pd_gfx.image.new("resources/setupguide")

function empty_library_splash()
    local qr_size = qr:getSize()

    local splash_header_x = margin
    local splash_header_y = margin
    local splash_header_width = display_width - margin * 2
    local splash_header_height = pd_gfx.getSystemFont(pd_gfx.font.kVariantBold):getHeight()

    local splash_message_x = margin
    local splash_message_y = splash_header_y + splash_header_height + margin
    local splash_message_width = splash_header_width
    local splash_message_height = display_height - splash_message_y - qr_size - margin * 2

    local qr_x = margin
    local qr_y = display_height - margin - qr_size

    local qr_message_x = qr_x + qr_size + margin
    local qr_message_y = qr_y + spacer
    local qr_message_width = display_width - qr_message_x - margin
    local qr_message_height = qr_size - spacer

    pd_gfx.drawTextInRect(splash_header, splash_header_x, splash_header_y, splash_header_width, splash_header_height)
    -- pd_gfx.fillRect(splash_header_x, splash_header_y, splash_header_width, splash_header_height)

    pd_gfx.drawTextInRect(splash_message, splash_message_x, splash_message_y, splash_message_width, splash_message_height)
    -- pd_gfx.fillRect(splash_message_x, splash_message_y, splash_message_width, splash_message_height)

    qr:draw(qr_x, qr_y)
    -- pd_gfx.fillRect(qr_x, qr_y, qr_size, qr_size)

    pd_gfx.drawTextInRect(qr_message, qr_message_x, qr_message_y, qr_message_width, qr_message_height)
    -- pd_gfx.fillRect(qr_message_x, qr_message_y, qr_message_width, qr_message_height)
end