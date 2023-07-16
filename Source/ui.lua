import "CoreLibs/ui/gridview"
import "CoreLibs/nineslice"

local index = nil
local playback

local gfx = playdate.graphics
local listview = playdate.ui.gridview.new(0, 10)
listview:setCellPadding(10, 10, 10, 0)

function listview:drawCell(section, row, column, selected, x, y, width, height)
	if selected then
		gfx.setColor(gfx.kColorBlack)
		gfx.fillRoundRect(x, y, width, 20, 4)
		gfx.setImageDrawMode(gfx.kDrawModeInverted)
	else
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
	end
	gfx.drawTextInRect(index[row].title, x, y+2, width, height+10, nil, "...", kTextAlignment.center)
end

function playdate.AButtonUp()
	playback = index[listview:getSelectedRow()]
	set_playback(playback.path)
	index_image(playback.path)
end

function playdate.upButtonUp()
    listview:selectPreviousRow(true)
end

function playdate.downButtonUp()
    listview:selectNextRow(true)
end

function updateUI()
    if listview.needsDisplay and index then
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(0, 0, 160, 240)
        listview:drawInRect(0, 0, 160, 240)
    end
end

function init_track_ui(i)
	index = i
	listview:setNumberOfRows(#index)
end