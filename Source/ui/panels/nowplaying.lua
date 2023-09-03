local pd_gfx <const> = playdate.graphics
local ui <const> = UI
local normal_font <const> = pd_gfx.getFont()
local bold_font <const> = pd_gfx.getFont(pd_gfx.font.kVariantBold)
local consts <const> = ui_consts

local text_padding <const> = 5
local panel_padding <const> = 10

local padded_width <const> = consts.panel_width - (panel_padding * 2)
local padded_height <const> = consts.display_height - panel_padding - consts.progress_height

class("NowPlaying", nil, ui.panels).extends(pd_gfx.sprite)

function ui.panels.NowPlaying:init()
    ui.panels.NowPlaying.super.init(self)

    self:setCenter(0, 0)
    self:setBounds(0, 0, consts.panel_width, consts.display_height)
    -- self:setOpaque(true)

    self.canvas = pd_gfx.image.new(padded_width, padded_height)

    self:setUpdatesEnabled(false)
    self:add()
end

local function draw_text(text, height, font)
    return height + select(2, pd_gfx.drawTextInRect(text, 0, height, padded_width, padded_height - height, nil, "...", nil, font))
end

function ui.panels.NowPlaying:refresh()
    if ui.track then
        local height = 0

        pd_gfx.pushContext(self.canvas)
        pd_gfx.clear()

        height = draw_text(ui.track.title, height, bold_font) + text_padding
        height = draw_text(ui.track.album.title, height, normal_font) + text_padding
        height = draw_text(ui.track.artist, height, normal_font)

        pd_gfx.popContext()

        self.rendered_height = height
        self:markDirty()
    end
end

function ui.panels.NowPlaying:draw(x, y, width, height)
    -- pd_gfx.setColor(pd_gfx.kColorBlack)
    -- pd_gfx.fillRect(x, y, width, height)

    if self.rendered_height then
        local vertical_center = consts.display_height - consts.progress_height - self.rendered_height

        -- pd_gfx.setImageDrawMode(pd_gfx.kDrawModeNXOR)
        self.canvas:draw(x + panel_padding, vertical_center, nil, 0, 0, padded_width, self.rendered_height)
    end
end