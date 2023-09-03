local ui_panels <const> = UI.panels

local properties = {
    section_title = "albums"
}

class("Albums", properties, ui_panels).extends(ui_panels.ListPanel)

function ui_panels.Albums:get_row_text(row)
    return self.albums[row].title
end

function ui_panels.Albums:init(albums)
    ui_panels.Albums.super.init(self)
    self.albums = albums

    self.listview:setNumberOfRows(#albums)
end

function ui_panels.Albums:select()
    local album = self.albums[self.listview:getSelectedRow()]
    local tracks = ui_panels.Tracks(album.tracks)
    tracks.section_title = album.title
end