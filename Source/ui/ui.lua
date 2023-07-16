import "menu"
import "playback"

local gfx = playdate.graphics

menu_open = true
-- local state_changed = true;

function init_ui(index)
    init_menu(index)
    show_menu()
end

local function clear()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, 160, 240)
end

function update_ui()
    if menu_open then
        update_menu(clear)
    else
        update_playback(clear)
    end
end