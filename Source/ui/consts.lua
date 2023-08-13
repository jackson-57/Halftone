local display_width = playdate.display.getWidth()
local display_height = playdate.display.getHeight()

local cover_size_full = 220;

ui_consts = {
    display_width = display_width,
    display_height = display_height,
    cover_size_full = cover_size_full,
    panel_width = display_width - cover_size_full,
    progress_height = display_height - cover_size_full
}