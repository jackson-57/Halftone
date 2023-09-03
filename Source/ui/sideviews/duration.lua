local pd_gfx <const> = playdate.graphics
local ui <const> = UI
local engine <const> = Engine
local font <const> = pd_gfx.getFont(pd_gfx.font.kVariantBold)
local textAlignment <const> = kTextAlignment
local math_floor <const> = math.floor

class("DurationSideview", nil, ui.sideviews).extends(ui.sideviews.BarSideview)

function ui.sideviews.DurationSideview:get_elapsed()
    local elapsed = engine.get_playback_status()
    if elapsed == nil then
        elapsed = 0
    end

    return elapsed
end

function ui.sideviews.DurationSideview:calculate_width(elapsed)
    -- https://stackoverflow.com/a/18313481
    return math_floor((self.width * (elapsed / self.current_duration)) + 0.5)
end

function ui.sideviews.DurationSideview:calculate_elapsed()
    return math_floor((self.current_duration * (self.seek_width / self.width)) + 0.5)
end

function ui.sideviews.DurationSideview:draw(x, y, width, height)
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
    pd_gfx.font.drawText(font, ui.sec_to_hms(elapsed), x + 2, y + 2)
    -- todo: cache?
    pd_gfx.font.drawTextAligned(font, ui.sec_to_hms(self.current_duration), width - 2, y + 2, textAlignment.right)
end

function ui.sideviews.DurationSideview:refresh()
    self.current_elapsed = self:get_elapsed()
    self.current_duration = ui.track.duration
    self:markDirty()
end

function ui.sideviews.DurationSideview:update()
    local elapsed = self:get_elapsed()
    if self.current_elapsed ~= elapsed then
        self.current_elapsed = elapsed
        self:markDirty()
    end
end