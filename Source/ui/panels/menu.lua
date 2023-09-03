local ui_panels <const> = UI.panels

class("Menu", nil, ui_panels).extends(ui_panels.ListPanel)

function ui_panels.Menu:get_row_text(row)
    return self.menuOptions[row].name
end

function ui_panels.Menu:init(index)
    ui_panels.Menu.super.init(self)
    self.index = index

    self.menuOptions = {
        {
            name = "albums",
            select = function () ui_panels.Albums(self.index.albums) end
        },
        {
            name = "artists",
            select = function () ui_panels.Artists(self.index.artists) end
        },
        {
            name = "tracks",
            select = function () ui_panels.Tracks(self.index.tracks) end
        }
    }

    self.listview:setNumberOfRows(#self.menuOptions)
end

function ui_panels.Menu:select()
    self.menuOptions[self.listview:getSelectedRow()].select()
end