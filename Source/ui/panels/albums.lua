local pd_gfx <const> = playdate.graphics
local font <const> = pd_gfx.getFont()

local properties = {
    section_title = "albums"
}

class("Albums", properties).extends(ListPanel)

local function drawCell(self, section, row, column, selected, x, y, width, height)
    self.drawCellBackground(selected, x, y, width, height)
	pd_gfx.drawTextInRect(self.parent.albums[row].title, x + 5, y + 2, width - 5, height, nil, "...", nil, font)
end

function Albums:init(albums)
    Albums.super.init(self)
    self.albums = albums

    self.listview:setNumberOfRows(#albums)
    self.listview.drawCell = drawCell
end

function Albums:select()
    Tracks(self.albums[self.listview:getSelectedRow()].tracks)
end