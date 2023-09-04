local consts <const> = consts
local ui_consts <const> = ui_consts
local ui_sideviews <const> = UI.sideviews
local pd <const> = playdate
local pd_gfx <const> = pd.graphics
local pd_file_exists <const> = pd.file.exists

local default_art = pd_gfx.image.new("resources/halftone_cover")

class("ArtSideview", nil, ui_sideviews).extends(pd_gfx.sprite)

function ui_sideviews.ArtSideview:init()
    ui_sideviews.ArtSideview.super.init(self)

    self.art = pd_gfx.image.new(ui_consts.cover_size_full, ui_consts.cover_size_full)

    self:setUpdatesEnabled(false)
    self:setCenter(0, 0)
    self:moveTo(ui_consts.panel_width, 0)
    self:setImage(default_art)
    self:setRedrawsOnImageChange(false)
    self:setOpaque(true)
    self:add()
end

function ui_sideviews.ArtSideview:set_album(album)
    if self.album ~= album then
        self.album = album

        local path = consts.album_art_path .. ui_consts.cover_size_full .. "/" .. album.art_uuid .. ".pdi"
        if pd_file_exists(path) then
            -- album art is present: load into image, set, and mark dirty
            self.art:load(path)
            self:setImage(self.art)
            self:markDirty()
        elseif self:getImage() ~= default_art then
            -- only set and mark dirty if not already set to default art
            self:setImage(default_art)
            self:markDirty()
        end
    end
end