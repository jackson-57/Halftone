local pd_gfx <const> = playdate.graphics
local pd_gridview <const> = playdate.ui.gridview
local pd_input <const> = playdate.inputHandlers
local font <const> = pd_gfx.getFont(pd_gfx.font.kVariantBold)

local properties = {
    cell_width = 0,
    cell_height = 20,
    section_title = "menu"
}

class("ListPanel", properties).extends(Panel)

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

local function addKeyRepeat(self, callback)
    self.keyTimer = playdate.timer.keyRepeatTimerWithDelay(300, 50, callback)
end

local function removeKeyRepeat(self)
    self.keyTimer:remove()
end

function ListPanel:init()
    ListPanel.super.init(self)

    self.listview = pd_gridview.new(self.cell_width, self.cell_height)
    self.listview.parent = self
    self.listview.drawCellBackground = drawCellBackground
    self.listview.drawSectionHeader = drawSectionHeader
    self.listview:setCellPadding(5, 5, 0, 1)
    self.listview:setSectionHeaderHeight(20)
    self.listview:setSectionHeaderPadding(0, 0, 0, 5)
end

function ListPanel:update()
    if self.listview.needsDisplay then
        pd_gfx.pushContext(self:getImage())
        pd_gfx.clear()

        pd_gfx.setDitherPattern(0.5)
        pd_gfx.fillRect(0, 0, self.panel_width, self.panel_height)
        self.listview:drawInRect(0, 0, self.panel_width, self.panel_height)

        pd_gfx.popContext()
    end
end

function ListPanel:add()
    local panelInputHandlers = {
        upButtonDown = function()
            addKeyRepeat(self, function()
                self.listview:selectPreviousRow(true)
            end)
        end,
        downButtonDown = function ()
            addKeyRepeat(self, function()
                self.listview:selectNextRow(true)
            end)
        end,

        upButtonUp = function()
            removeKeyRepeat(self)
        end,
        downButtonUp = function()
            removeKeyRepeat(self)
        end,

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
    pd_input.pop()

    ListPanel.super.remove(self)
end