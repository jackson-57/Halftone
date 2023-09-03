local consts <const> = consts
local ui_consts <const> = ui_consts
local ui_sideviews <const> = UI.sideviews
local pd_gfx <const> = playdate.graphics

class("ArtSideview", nil, ui_sideviews).extends(pd_gfx.sprite)

function ui_sideviews.ArtSideview:init()
    ui_sideviews.ArtSideview.super.init(self)

    self:setUpdatesEnabled(false)
    self:setCenter(0, 0)
    self:moveTo(ui_consts.panel_width, 0)
    self:setImage(pd_gfx.image.new(ui_consts.cover_size_full, ui_consts.cover_size_full))
    self:setRedrawsOnImageChange(false)
    self:setOpaque(true)
    self:add()
end

function ui_sideviews.ArtSideview:set_album(album)
    if self.album ~= album then
        self.album = album
        self:getImage():load(consts.album_art_path .. ui_consts.cover_size_full .. "/" .. album.art_uuid)
        self:markDirty()
    end
end