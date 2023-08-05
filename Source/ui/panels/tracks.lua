local pd_gfx <const> = playdate.graphics
local font <const> = pd_gfx.getFont()

class("Tracks").extends(ListPanel)

local function drawCell(self, section, row, column, selected, x, y, width, height)
    self.drawCellBackground(selected, x, y, width)
	pd_gfx.drawTextInRect(self.parent.tracks[row].title, x, y+2, width, height+10, nil, "...", kTextAlignment.center, font)
end

function Tracks:init(tracks)
    Tracks.super.init(self)
    self.tracks = tracks

    self.listview:setNumberOfRows(#tracks)
    self.listview.drawCell = drawCell
end

function Tracks:select()
    play_track(self.tracks[self.listview:getSelectedRow()])
end