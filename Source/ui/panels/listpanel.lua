local pd_gfx <const> = playdate.graphics
local pd_gridview <const> = playdate.ui.gridview
local pd_input <const> = playdate.inputHandlers

local consts <const> = ui_consts
local font <const> = pd_gfx.getFont(pd_gfx.font.kVariantBold)

local panel_list = {}

local properties = {
    panel_width = consts.panel_width,
    panel_height = consts.display_height,
    cell_width = 0,
    cell_height = 20,
    section_title = "menu"
}

class("ListPanel", properties).extends(pd_gfx.sprite)

local function drawCellBackground(selected, x, y, width, height)
    if selected then
        pd_gfx.setColor(pd_gfx.kColorBlack)
		pd_gfx.setImageDrawMode(pd_gfx.kDrawModeInverted)
	else
        pd_gfx.setColor(pd_gfx.kColorWhite)
		pd_gfx.setImageDrawMode(pd_gfx.kDrawModeCopy)
	end

    pd_gfx.fillRect(x, y, width, height)
end

local function drawSectionHeader(self, section, x, y, width, height)
    pd_gfx.setColor(pd_gfx.kColorBlack)
    pd_gfx.fillRect(x, y, width, height)
    pd_gfx.setImageDrawMode(pd_gfx.kDrawModeInverted)
    pd_gfx.drawTextInRect(self.parent.section_title, x + 10, y + 1, width, height, nil, "...", nil, font)
end

function ListPanel:init()
    ListPanel.super.init(self)
    table.insert(panel_list, self)

    self:setCenter(0, 0)
    self:moveTo(0, 0)
    self:setImage(pd_gfx.image.new(self.panel_width, self.panel_height))
    self:setRedrawsOnImageChange(false)
    self:setOpaque(true)

    self.listview = pd_gridview.new(self.cell_width, self.cell_height)
    self.listview.parent = self
    self.listview.drawCellBackground = drawCellBackground
    self.listview.drawSectionHeader = drawSectionHeader
    self.listview:setCellPadding(5, 5, 0, 1)
    self.listview:setSectionHeaderHeight(20)
    self.listview:setSectionHeaderPadding(0, 0, 0, 5)

    self:add()
end

function ListPanel:update()
    if self.listview.needsDisplay then
        pd_gfx.pushContext(self:getImage())
        pd_gfx.clear()

        pd_gfx.setDitherPattern(0.5)
        pd_gfx.fillRect(0, 0, self.panel_width, self.panel_height)
        self.listview:drawInRect(0, 0, self.panel_width, self.panel_height)

        pd_gfx.popContext()

        self:markDirty()
    end
end

function ListPanel:add()
    local function addKeyRepeat(direction)
        if not self.keyTimer then
            local function callback(timer)
                -- timerEndedCallback is set after callback is immediately run
                local is_immediate = timer.timerEndedCallback == nil

                if direction == playdate.kButtonDown then
                    self.listview:selectPreviousRow(true, nil, is_immediate)
                else
                    self.listview:selectNextRow(true, nil, is_immediate)
                end
            end

            self.keyTimer = playdate.timer.keyRepeatTimerWithDelay(300, 50, callback)
        end
    end

    local function removeKeyRepeat()
        if self.keyTimer then
            self.keyTimer:remove()
            self.keyTimer = nil
        end
    end

    local panelInputHandlers = {
        upButtonDown = function()
            addKeyRepeat(playdate.kButtonDown)
        end,
        downButtonDown = function ()
            addKeyRepeat(playdate.kButtonUp)
        end,
        upButtonUp = removeKeyRepeat,
        downButtonUp = removeKeyRepeat,

        AButtonUp = function()
            self:select()
        end,
        BButtonUp = function()
            self:remove()
        end
    }

    pd_input.push(panelInputHandlers)

    ListPanel.super.add(self)
end

function ListPanel:remove()
    table.remove(panel_list)
    pd_input.pop()

    ListPanel.super.remove(self)
end

function ListPanel:removePanels()
    for _ in pairs(panel_list) do
        pd_input.pop()
    end

    self.removeSprites(panel_list)
    panel_list = {}
end