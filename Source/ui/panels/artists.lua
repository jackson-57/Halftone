local pd_gfx <const> = playdate.graphics
local font <const> = pd_gfx.getFont()

local properties = {
    section_title = "artists"
}

class("Artists", properties).extends(ListPanel)

local function drawCell(self, section, row, column, selected, x, y, width, height)
    self.drawCellBackground(selected, x, y, width, height)
	pd_gfx.drawTextInRect(self.parent.artists[row].name, x + 5, y + 2, width - 5, height, nil, "...", nil, font)
end

function Artists:init(artists)
    Artists.super.init(self)
    self.artists = artists

    self.listview:setNumberOfRows(#artists)
    self.listview.drawCell = drawCell
end

function Artists:select()
    local artist = self.artists[self.listview:getSelectedRow()]
    local albums = Albums(artist.albums)
    albums.section_title = artist.name
end