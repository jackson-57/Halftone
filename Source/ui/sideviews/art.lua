local consts <const> = ui_consts

class("ArtSideview").extends(playdate.graphics.sprite)

function ArtSideview:init()
    ArtSideview.super.init(self)

    self:setUpdatesEnabled(false)
    self:setCenter(0, 0)
    self:moveTo(consts.panel_width, 0)
    self:add()
end