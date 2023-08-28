local pd_gfx <const> = playdate.graphics
local ui <const> = UI
local font <const> = pd_gfx.getFont(pd_gfx.font.kVariantBold)

class("DurationSideview").extends(BarSideview)

function DurationSideview:get_elapsed()
    local elapsed = get_playback_status()
    if elapsed == nil then
        elapsed = 0
    end

    return elapsed
end

function DurationSideview:calculate_width(elapsed)
    -- https://stackoverflow.com/a/18313481
    return math.floor((self.width * (elapsed / self.current_duration)) + 0.5)
end

function DurationSideview:calculate_elapsed()
    return math.floor((self.current_duration * (self.seek_width / self.width)) + 0.5)
end

function DurationSideview:draw(x, y, width, height)
    if not ui.track then return end

    local elapsed = nil
    local filled_width = nil
    if self.seek_width then
        elapsed = self:calculate_elapsed()
        filled_width = self.seek_width
    else
        elapsed = self.current_elapsed
        filled_width = self:calculate_width(elapsed)
    end

    pd_gfx.fillRect(x, y, filled_width, height)

    pd_gfx.setImageDrawMode(pd_gfx.kDrawModeNXOR)
    pd_gfx.font.drawText(font, sec_to_hms(elapsed), x + 2, y + 2)
    -- todo: cache?
    pd_gfx.font.drawTextAligned(font, sec_to_hms(self.current_duration), width - 2, y + 2, kTextAlignment.right)
end

function DurationSideview:refresh()
    self.current_elapsed = self:get_elapsed()
    self.current_duration = ui.track.duration
    self:markDirty()
end

function DurationSideview:update()
    local elapsed = self:get_elapsed()
    if self.current_elapsed ~= elapsed then
        self.current_elapsed = elapsed
        self:markDirty()
    end
end