local consts <const> = consts
local ui_consts <const> = ui_consts
local pd_img <const> = playdate.graphics.image

class("ArtSideview").extends(playdate.graphics.sprite)

function ArtSideview:init()
    ArtSideview.super.init(self)

    self:setUpdatesEnabled(false)
    self:setCenter(0, 0)
    self:moveTo(ui_consts.panel_width, 0)
    self:setImage(pd_img.new(ui_consts.cover_size_full, ui_consts.cover_size_full))
    self:add()
end

function ArtSideview:set_album(album)
    if self.album ~= album then
        self.album = album
        self:getImage():load(consts.album_art_path .. ui_consts.cover_size_full .. "/" .. album.art_uuid)
    end
end