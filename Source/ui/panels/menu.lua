local pd_gfx <const> = playdate.graphics
local font <const> = pd_gfx.getFont()

class("Menu").extends(ListPanel)

local function drawCell(self, section, row, column, selected, x, y, width, height)
    self.drawCellBackground(selected, x, y, width, height)
	pd_gfx.drawTextInRect(self.parent.menuOptions[row].name, x + 5, y + 2, width - 5, height, nil, "...", nil, font)
end

function Menu:init(index)
    Menu.super.init(self)
    self.index = index

    self.menuOptions = {
        {
            name = "tracks",
            select = function ()
                Tracks(self.index.tracks)
            end
        }
    }

    self.listview:setNumberOfRows(#self.menuOptions)
    self.listview.drawCell = drawCell
end

function Menu:select()
    self.menuOptions[self.listview:getSelectedRow()].select()
end