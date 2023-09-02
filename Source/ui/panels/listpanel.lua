local pd_gfx <const> = playdate.graphics
local pd_gridview <const> = playdate.ui.gridview
local pd_input <const> = playdate.inputHandlers

local consts <const> = ui_consts
local normal_font <const> = pd_gfx.getFont()
local bold_font <const> = pd_gfx.getFont(pd_gfx.font.kVariantBold)

local panel_list = {}

local properties = {
    panel_width = consts.panel_width,
    panel_height = consts.display_height,
    cell_width = 0,
    cell_height = 20,
    section_title = "menu"
}

class("ListPanel", properties).extends(pd_gfx.sprite)

function ListPanel:drawSectionHeader(listview, section, x, y, width, height)
    pd_gfx.setColor(pd_gfx.kColorBlack)
    pd_gfx.fillRect(x, y, width, height)
    pd_gfx.setImageDrawMode(pd_gfx.kDrawModeInverted)
    pd_gfx.drawTextInRect(self.section_title, x + 10, y + 1, width - 10, height, nil, "...", nil, bold_font)
end

function ListPanel:drawCell(listview, section, row, column, selected, x, y, width, height)
    if selected then
        pd_gfx.setColor(pd_gfx.kColorBlack)
		pd_gfx.setImageDrawMode(pd_gfx.kDrawModeInverted)
	else
        pd_gfx.setColor(pd_gfx.kColorWhite)
		pd_gfx.setImageDrawMode(pd_gfx.kDrawModeCopy)
	end

    pd_gfx.fillRect(x, y, width, height)
    pd_gfx.drawTextInRect(self:get_row_text(row), x + 5, y + 2, width - 5, height, nil, "...", nil, normal_font)
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
    self.listview.drawCell = function (...) self:drawCell(...) end
    self.listview.drawSectionHeader = function (...) self:drawSectionHeader(...) end
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
    local function add_key_repeat(direction)
        if not self.key_timer then
            local function callback(timer)
                -- timerEndedCallback is set after callback is immediately run
                local is_immediate = timer.timerEndedCallback == nil

                if direction == playdate.kButtonDown then
                    self.listview:selectPreviousRow(true, nil, is_immediate)
                else
                    self.listview:selectNextRow(true, nil, is_immediate)
                end
            end

            self.key_timer = playdate.timer.keyRepeatTimerWithDelay(300, 50, callback)
        end
    end

    local function remove_key_repeat()
        if self.key_timer then
            self.key_timer:remove()
            self.key_timer = nil
        end
    end

    local panel_input_handlers = {
        upButtonDown = function () add_key_repeat(playdate.kButtonDown) end,
        downButtonDown = function () add_key_repeat(playdate.kButtonUp) end,
        upButtonUp = remove_key_repeat,
        downButtonUp = remove_key_repeat,

        AButtonUp = function () self:select() end,
        BButtonUp = function () self:remove() end
    }

    pd_input.push(panel_input_handlers)

    ListPanel.super.add(self)
end

function ListPanel:remove()
    table.remove(panel_list)
    pd_input.pop()

    ListPanel.super.remove(self)
end

function ListPanel:remove_all_panels()
    for _ in pairs(panel_list) do
        pd_input.pop()
    end

    self.removeSprites(panel_list)
    panel_list = {}
end