local display_width = playdate.display.getWidth()
local display_height = playdate.display.getHeight()

local cover_size = 233

ui_consts = {
    display_width = display_width,
    display_height = display_height,
    cover_size = cover_size,
    panel_width = display_width - cover_size,
    progress_height = display_height - cover_size
}