local ui_panels <const> = UI.panels

local properties = {
    section_title = "artists"
}

class("Artists", properties, ui_panels).extends(ui_panels.ListPanel)

function ui_panels.Artists:get_row_text(row)
    return self.artists[row].name
end

function ui_panels.Artists:init(artists)
    ui_panels.Artists.super.init(self)
    self.artists = artists

    self.listview:setNumberOfRows(#artists)
end

function ui_panels.Artists:select()
    local artist = self.artists[self.listview:getSelectedRow()]
    local albums = ui_panels.Albums(artist.albums)
    albums.section_title = artist.name
end