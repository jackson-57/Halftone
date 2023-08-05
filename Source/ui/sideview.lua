-- TODO: Switch to local track instances

class("Sideview").extends()

function Sideview:init()
    Sideview.super.init(self)

    self.art = ArtSideview()
    self.duration = DurationSideview()
end

function Sideview:remove()
    self.art:remove()
    self.duration:remove()
end