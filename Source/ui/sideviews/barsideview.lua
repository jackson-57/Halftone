local consts <const> = ui_consts

class("BarSideview").extends(playdate.graphics.sprite)

function BarSideview:init()
    BarSideview.super.init(self)

    self:setUpdatesEnabled(false)
    self:setCenter(0, 0)
    self:setBounds(consts.panel_width, consts.cover_size_full, consts.cover_size_full, consts.progress_height)
    self:add()
end