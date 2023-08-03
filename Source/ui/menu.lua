import "CoreLibs/ui/gridview"
import "CoreLibs/nineslice"

local index = nil

local pd_gfx <const> = playdate.graphics
local font = pd_gfx.getFont()
local keyTimer = nil
local listview = playdate.ui.gridview.new(0, 10)
listview:setCellPadding(10, 10, 10, 0)

function listview:drawCell(section, row, column, selected, x, y, width, height)
	if selected then
		pd_gfx.setColor(pd_gfx.kColorBlack)
		pd_gfx.fillRoundRect(x, y, width, 20, 4)
		pd_gfx.setImageDrawMode(pd_gfx.kDrawModeInverted)
	else
		pd_gfx.setImageDrawMode(pd_gfx.kDrawModeCopy)
	end
	pd_gfx.drawTextInRect(index[row].title, x, y+2, width, height+10, nil, "...", kTextAlignment.center, font)
end

local function addKeyRepeat(callback)
    keyTimer = playdate.timer.keyRepeatTimerWithDelay(300, 50, callback)
end

local function removeKeyRepeat()
    keyTimer:remove()
end

function init_menu(i)
	index = i
	listview:setNumberOfRows(#index)
end

function update_menu(clear)
    if listview.needsDisplay then
        clear()
        listview:drawInRect(0, 0, 167, 240)
    end
end


function hide_menu()
    playdate.inputHandlers.pop()
    menu_open = false
    redraw_track_info = true
end

local menuInputHandlers = {
    AButtonUp = function()
        play_track(index[listview:getSelectedRow()])

        hide_menu()
    end,

    upButtonDown = function ()
        addKeyRepeat(function()
            listview:selectPreviousRow(true)
        end)
    end,
    downButtonDown = function ()
        addKeyRepeat(function()
            listview:selectNextRow(true)
        end)
    end,

    upButtonUp = removeKeyRepeat,
    downButtonUp = removeKeyRepeat,

    BButtonUp = hide_menu
}

function show_menu()
    playdate.inputHandlers.push(menuInputHandlers)
    menu_open = true
    listview.needsDisplay = true
end