local consts <const> = ui_consts
local ui_sideviews <const> = UI.sideviews

class("BarSideview", nil, ui_sideviews).extends(playdate.graphics.sprite)

function ui_sideviews.BarSideview:init()
    ui_sideviews.BarSideview.super.init(self)

    self:setUpdatesEnabled(false)
    self:setCenter(0, 0)
    self:setBounds(consts.panel_width, consts.cover_size_full, consts.cover_size_full, consts.progress_height)
    self:add()
end