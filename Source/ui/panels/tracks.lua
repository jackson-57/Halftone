local pd_gfx <const> = playdate.graphics
local font <const> = pd_gfx.getFont()

local properties = {
    section_title = "tracks"
}

class("Tracks", properties).extends(ListPanel)

local function drawCell(self, section, row, column, selected, x, y, width, height)
    self.drawCellBackground(selected, x, y, width, height)
	pd_gfx.drawTextInRect(self.parent.tracks[row].title, x + 5, y + 2, width - 5, height, nil, "...", nil, font)
end

function Tracks:init(tracks)
    Tracks.super.init(self)
    self.tracks = tracks

    self.listview:setNumberOfRows(#tracks)
    self.listview.drawCell = drawCell
end

function Tracks:select()
    set_queue(self.tracks, self.listview:getSelectedRow())
    self:removePanels()
end