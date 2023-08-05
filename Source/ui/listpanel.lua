local pd_gfx <const> = playdate.graphics
local pd_gridview <const> = playdate.ui.gridview
local pd_input <const> = playdate.inputHandlers

local properties = {
    cell_width = 0,
    cell_height = 10
}

class("ListPanel", properties).extends(Panel)

local function drawCellBackground(selected, x, y, width)
    if selected then
		pd_gfx.setColor(pd_gfx.kColorBlack)
		pd_gfx.fillRoundRect(x, y, width, 20, 4)
		pd_gfx.setImageDrawMode(pd_gfx.kDrawModeInverted)
	else
		pd_gfx.setImageDrawMode(pd_gfx.kDrawModeCopy)
	end
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
    self.listview:setCellPadding(10, 10, 10, 0)
end

function ListPanel:update()
    if self.listview.needsDisplay then
        pd_gfx.pushContext(self:getImage())
        pd_gfx.clear()

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