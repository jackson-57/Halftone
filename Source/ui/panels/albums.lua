local properties = {
    section_title = "albums"
}

class("Albums", properties).extends(ListPanel)

function Albums:getText(row)
    return self.albums[row].title
end

function Albums:init(albums)
    Albums.super.init(self)
    self.albums = albums

    self.listview:setNumberOfRows(#albums)
end

function Albums:select()
    local album = self.albums[self.listview:getSelectedRow()]
    local tracks = Tracks(album.tracks)
    tracks.section_title = album.title
end