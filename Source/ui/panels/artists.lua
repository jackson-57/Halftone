local properties = {
    section_title = "artists"
}

class("Artists", properties).extends(ListPanel)

function Artists:getText(row)
    return self.artists[row].name
end

function Artists:init(artists)
    Artists.super.init(self)
    self.artists = artists

    self.listview:setNumberOfRows(#artists)
end

function Artists:select()
    local artist = self.artists[self.listview:getSelectedRow()]
    local albums = Albums(artist.albums)
    albums.section_title = artist.name
end