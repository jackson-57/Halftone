local ui_panels <const> = UI.panels
local playback_set_queue <const> = Playback.set_queue

local properties = {
    section_title = "tracks"
}

class("Tracks", properties, ui_panels).extends(ui_panels.ListPanel)

function ui_panels.Tracks:get_row_text(row)
    return self.tracks[row].title
end

function ui_panels.Tracks:init(tracks)
    ui_panels.Tracks.super.init(self)
    self.tracks = tracks

    self.listview:setNumberOfRows(#tracks)
end

function ui_panels.Tracks:select()
    playback_set_queue(self.tracks, self.listview:getSelectedRow())
    self:remove_all_panels()
end