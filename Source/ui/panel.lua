local pd_gfx <const> = playdate.graphics
local pd_img <const> = pd_gfx.image

local consts <const> = ui_consts

local properties = {
    panel_x = 0,
    panel_y = 0,
    panel_width = consts.panel_width,
    panel_height = consts.display_height
}

class("Panel", properties).extends(pd_gfx.sprite)

function Panel:init()
    Panel.super.init(self)

    self:setCenter(0, 0)
    self:moveTo(self.panel_x, self.panel_y)
    self:setImage(pd_img.new(self.panel_width, self.panel_height))
    self:add()
end