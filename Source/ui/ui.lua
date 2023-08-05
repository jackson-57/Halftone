import "CoreLibs/ui/gridview"
import "CoreLibs/nineslice"
import "CoreLibs/object"

import "consts"
import "menu"
import "playback"

local pd_gfx <const> = playdate.graphics
local consts <const> = ui_consts

menu_open = true
-- local state_changed = true;

function init_ui(index)
    init_menu(index)
    show_menu()
end

local function clear()
    pd_gfx.setColor(pd_gfx.kColorWhite)
    pd_gfx.fillRect(0, 0, consts.panel_width, consts.display_height)
end

function update_ui()
    if menu_open then
        update_menu(clear)
    else
        update_track_info(clear)
    end
end