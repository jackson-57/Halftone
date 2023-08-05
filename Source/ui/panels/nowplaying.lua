local pd_gfx <const> = playdate.graphics
local font <const> = pd_gfx.getFont()

class("NowPlaying").extends(Panel)

function NowPlaying:init()
    NowPlaying.super.init(self)

    -- self:setZIndex(-32768)
    -- self:setIgnoresDrawOffset(true)
    self:setUpdatesEnabled(false)
end

function NowPlaying:update()
    if self.track then
        pd_gfx.pushContext(self:getImage())
        pd_gfx.clear()

        pd_gfx.drawTextInRect(self.track.title, 10, 85, 147, 20, nil, "...", nil, font)
        pd_gfx.drawTextInRect(self.track.album.title, 10, 110, 147, 20, nil, "...", nil, font)
        pd_gfx.drawTextInRect(self.track.artist, 10, 135, 147, 20, nil, "...", nil, font)

        pd_gfx.popContext()
    end
end