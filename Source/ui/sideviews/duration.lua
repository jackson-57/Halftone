local pd_gfx <const> = playdate.graphics
local pd_timer <const> = playdate.timer
local pd_input <const> = playdate.inputHandlers

local font <const> = pd_gfx.getFont(pd_gfx.font.kVariantBold)

local seek_hold_delay <const> = 300
local seek_amount <const> = 2

class("DurationSideview").extends(BarSideview)

function DurationSideview:init()
    DurationSideview.super.init(self)

    self.update_timer = pd_timer.new(1000, function()
        self:markDirty()
    end)
    self.update_timer.repeats = true
    self.update_timer:pause()
end

function DurationSideview:get_elapsed()
    local elapsed = get_playback_status()
    if elapsed == nil then
        elapsed = 0
    end

    return elapsed
end

function DurationSideview:calculate_width(elapsed, duration)
    -- https://stackoverflow.com/a/18313481
    return math.floor((self.width * (elapsed / duration)) + 0.5)
end

function DurationSideview:calculate_elapsed(duration)
    return math.floor((duration * (self.seek_width / self.width)) + 0.5)
end

function DurationSideview:draw(x, y, width, height)
    if not self.track then return end

    local duration = self.track.duration

    local elapsed = nil
    local filled_width = nil
    if not self.seek_width then
        elapsed = self:get_elapsed()
        filled_width = self:calculate_width(elapsed, duration)
    else
        elapsed = self:calculate_elapsed(duration)
        filled_width = self.seek_width
    end

    pd_gfx.fillRect(x, y, filled_width, height)

    pd_gfx.setImageDrawMode(pd_gfx.kDrawModeNXOR)
    pd_gfx.font.drawText(font, sec_to_hms(elapsed), x + 2, y + 2)
    -- todo: cache?
    pd_gfx.font.drawTextAligned(font, sec_to_hms(duration), width - 2, y + 2, kTextAlignment.right)
end

function DurationSideview:reset_update_timer()
    self.update_timer:reset()
    self.update_timer:start()

    self:markDirty()
end

function DurationSideview:remove()
    self.update_timer:remove()

    DurationSideview.super.remove(self)
end

function DurationSideview:start_seek_timer(direction)
    if self.seek_direction or not self.track then return end
    self.seek_direction = direction

    self.seek_timer = pd_timer.new(seek_hold_delay, function ()
        toggle_playing(false)
        self.seek_timer = nil
        self.seek_width = self:calculate_width(self:get_elapsed(), self.track.duration)
        self:setUpdatesEnabled(true)
    end)

    local seekingInputHandlers = {
        leftButtonUp = function ()
            self:end_seeking(playdate.kButtonLeft)
        end,
        rightButtonUp = function ()
            self:end_seeking(playdate.kButtonRight)
        end
    }
    pd_input.push(seekingInputHandlers)
end

function DurationSideview:end_seeking(direction)
    if direction ~= self.seek_direction then return end

    self.seek_direction = nil
    pd_input.pop()

    if self.seek_timer then
        self.seek_timer:remove()
        self.seek_timer = nil

        if direction == playdate.kButtonLeft then
            play_previous()
        else
            play_next()
        end
    else
        self:setUpdatesEnabled(false)
        seek_playback(self:calculate_elapsed(self.track.duration))
        self.seek_width = nil
        self.update_timer:reset()
        toggle_playing(true)
    end
end

function DurationSideview:update()
    if self.seek_direction == playdate.kButtonLeft then
        self.seek_width -= seek_amount

        if self.seek_width <= 0 then
            self.seek_width = 0
            self:end_seeking(self.seek_direction)
        end
    else
        self.seek_width += seek_amount

        if self.seek_width >= self.width then
            self.seek_width = self.width
            self:end_seeking(self.seek_direction)
        end
    end

    self:markDirty()
end