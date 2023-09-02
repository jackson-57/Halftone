local properties = {
    section_title = "tracks"
}

class("Tracks", properties).extends(ListPanel)

function Tracks:getText(row)
    return self.tracks[row].title
end

function Tracks:init(tracks)
    Tracks.super.init(self)
    self.tracks = tracks

    self.listview:setNumberOfRows(#tracks)
end

function Tracks:select()
    set_queue(self.tracks, self.listview:getSelectedRow())
    self:removePanels()
end