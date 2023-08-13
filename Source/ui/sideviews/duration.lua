local pd_gfx <const> = playdate.graphics
local pd_timer <const> = playdate.timer

local font <const> = pd_gfx.getFont(pd_gfx.font.kVariantBold)

class("DurationSideview").extends(BarSideview)

function DurationSideview:draw(x, y, width, height)
    if self.track then
        local duration = self.track.duration
        local elapsed = get_playback_status()
        if not elapsed then
            elapsed = 0
        end

        -- https://stackoverflow.com/a/18313481
        local filled_width = math.floor((width * (elapsed / duration)) + 0.5)
        pd_gfx.fillRect(x, y, filled_width, height)

        pd_gfx.setImageDrawMode(pd_gfx.kDrawModeNXOR)
        pd_gfx.font.drawText(font, sec_to_hms(elapsed), x + 2, y + 2)
        -- todo: cache?
        pd_gfx.font.drawTextAligned(font, sec_to_hms(duration), width - 2, y + 2, kTextAlignment.right)
    end
end

function DurationSideview:setup_timer()
    if not self.timer then
        self.timer = pd_timer.new(1000, function()
            self:markDirty()
        end)
        self.timer.repeats = true
    else
        self.timer:reset()
    end

    self:markDirty()
end

function DurationSideview:destroy_timer()
    if self.timer then
        self.timer:remove()
    end
end

function DurationSideview:remove()
    self:destroy_timer()

    DurationSideview.super.remove(self)
end

function DurationSideview:start_seeking()

end

function DurationSideview:end_seeking()

end