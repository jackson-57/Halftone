class("Menu").extends(ListPanel)

function Menu:getText(row)
    return self.menuOptions[row].name
end

function Menu:init(index)
    Menu.super.init(self)
    self.index = index

    self.menuOptions = {
        {
            name = "albums",
            select = function () Albums(self.index.albums) end
        },
        {
            name = "artists",
            select = function () Artists(self.index.artists) end
        },
        {
            name = "tracks",
            select = function () Tracks(self.index.tracks) end
        }
    }

    self.listview:setNumberOfRows(#self.menuOptions)
end

function Menu:select()
    self.menuOptions[self.listview:getSelectedRow()].select()
end