local pd_gfx <const> = playdate.graphics
local pd_timer <const> = playdate.timer

-- local font <const> = pd_gfx.getFont()
local consts <const> = ui_consts

class("DurationSideview").extends(pd_gfx.sprite)

function DurationSideview:init()
    Sideview.super.init(self)

    self:setCenter(0, 0)
    self:setBounds(consts.panel_width, consts.cover_size, consts.cover_size, consts.progress_height)
    self:add()

    self:setUpdatesEnabled(false)
end

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
    end
end

function DurationSideview:setup_timer()
    if not self.timer then
        print("A")
        self.timer = pd_timer.new(1000, function()
            self:markDirty()
        end)
        self.timer.repeats = true
    else
        print("B")
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