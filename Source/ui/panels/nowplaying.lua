local pd_gfx <const> = playdate.graphics
local font <const> = pd_gfx.getFont(pd_gfx.font.kVariantBold)
local consts <const> = ui_consts

local height <const> = 20
local horizontal_padding <const> = 10
local vertical_padding <const> = 5

class("NowPlaying").extends(Panel)

function NowPlaying:init()
    NowPlaying.super.init(self)

    -- self:setZIndex(-32768)
    -- self:setIgnoresDrawOffset(true)
    self:setUpdatesEnabled(false)
end

local vertical_center <const> = (consts.display_height - height) / 2
local padded_height <const> = height + vertical_padding
local width <const> = consts.panel_width - (horizontal_padding * 2)

function NowPlaying:update()
    if self.track then
        pd_gfx.pushContext(self:getImage())
        pd_gfx.clear()

        pd_gfx.drawTextInRect(self.track.title, horizontal_padding, vertical_center - padded_height, width, height, nil, "...", nil, font)
        pd_gfx.drawTextInRect(self.track.album.title, horizontal_padding, vertical_center, width, height, nil, "...", nil, font)
        pd_gfx.drawTextInRect(self.track.artist, horizontal_padding, vertical_center + padded_height, width, height, nil, "...", nil, font)

        pd_gfx.popContext()
    end
end