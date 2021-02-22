local Draw = require("api.Draw")
local Gui = require("api.Gui")
local Ui = require("api.Ui")
local I18N = require("api.I18N")
local InventoryTargetEquipWindow = require("api.gui.menu.InventoryTargetEquipWindow")

local IInput = require("api.gui.IInput")
local UiList = require("api.gui.UiList")
local UiTheme = require("api.gui.UiTheme")
local IPaged = require("api.gui.IPaged")
local IUiLayer = require("api.gui.IUiLayer")
local InputHandler = require("api.gui.InputHandler")
local UiWindow = require("api.gui.UiWindow")
local ItemDescriptionMenu = require("api.gui.menu.ItemDescriptionMenu")


--- A menu for a single inventory action, like getting or eating.
local InventoryMenu = class.class("InventoryMenu", {IUiLayer, IPaged})

InventoryMenu:delegate("input", IInput)
InventoryMenu:delegate("pages", IPaged)

local UiListExt = function(inventory_menu)
   local E = {}

   function E:get_item_text(entry)
      return entry.text
   end
   function E:get_item_color(entry)
      return entry.item:calc_ui_color()
   end
   function E:draw_select_key(entry, i, key_name, x, y)
      if (i - 1) % 2 == 0 then
         Draw.filled_rect(x - 1, y, 540, 18, {12, 14, 16, 16})
      end

      UiList.draw_select_key(self, entry, i, key_name, x, y)

      inventory_menu.chip_batch:add(entry.icon, x - 21, y + 11, nil, nil, entry.color, true)

      if entry.source.on_draw then
         entry.source:on_draw(x, y, entry.item, inventory_menu)
      end
   end
   function E:draw_item_text(item_name, entry, i, x, y, x_offset, color)
      -- on_display_item_value
      local subtext = Ui.display_weight(entry.item:calc("weight") * entry.item.amount)

      if entry.source.on_get_name then
         item_name = entry.source:on_get_name(item_name, entry.item, inventory_menu)
      end

      if entry.source.on_get_subtext then
         subtext = entry.source:on_get_subtext(subtext, entry.item, inventory_menu)
      end

      if inventory_menu.layout then
         item_name, subtext = inventory_menu.layout:draw_row(entry.item, item_name, subtext, x, y)
      end

      UiList.draw_item_text(self, item_name, entry, i, x, y, x_offset, color)

      Draw.text(subtext, x + 516 - Draw.text_width(subtext), y + 2, color)
   end
   function E:draw()
      UiList.draw(self)
      inventory_menu.chip_batch:draw()
      inventory_menu.chip_batch:clear()
   end

   return E
end

-- TODO: Needs to remember position based on context
--   except 11 and 12 (shops)

function InventoryMenu:init(ctxt, returns_item)
   self.ctxt = ctxt
   self.returns_item = returns_item

   self.win = UiWindow:new(self.ctxt.proto.window_title, true, "key help")
   self.target_equip = InventoryTargetEquipWindow:new()
   self.pages = UiList:new_paged({}, 16)
   table.merge(self.pages, UiListExt(self))

   self.total_weight = 0
   self.max_weight = 0
   self.cargo_weight = 0
   self.layout = nil -- ResistanceLayout:new()
   self.subtext_column = "subtext"
   self.is_drawing = true
   self.total_weight_text = ""
   self.text_equip_slots = {}

   self.result = nil

   self.chip_batch = nil

   self.input = InputHandler:new()
   self.input:forward_to(self.pages)
   -- TODO
   -- self.pages:register("on_chosen", self.on_chosen)
   self.input:bind_keys(self:make_keymap())
   self.input:bind_keys(self.ctxt:additional_keybinds())

   self:update_filtering()
end

function InventoryMenu:make_keymap()
   return {
      identify = function() self:show_item_description() end,
      cancel = function() self.canceled = true end,
      escape = function() self.canceled = true end,
   }
end

function InventoryMenu:on_query()
   self.canceled = false
   if self.ctxt.proto.query_text and self.result == nil then
      local params = {}
      if self.ctxt.proto.locale_params then
         params = {self.ctxt.proto:locale_params()}
      end
      Gui.mes_newline()

      local text = self.ctxt.proto.query_text
      if type(text) == "function" then
         text = text(self.ctxt)
      end
      Gui.mes(text, table.unpack(params))
   end
end

-- TODO: IList needs refactor to "selected_entry" to avoid naming
-- confusion
function InventoryMenu:selected_item_object()
   local selected = self.pages:selected_item()
   if selected == nil then
      return nil
   end
   return selected.item
end

function InventoryMenu:show_item_description()
   local item = self:selected_item_object()
   if item == nil then
      return
   end
   local rest = self.pages:iter_all_pages():extract("item"):to_list()
   ItemDescriptionMenu:new(item, rest):query()
end

function InventoryMenu:can_select()
   local item = self:selected_item_object()
   return self.ctxt:can_select(item)
end

function InventoryMenu:on_select()
   local item = self:selected_item_object()

   local amount, canceled = self.ctxt:query_item_amount(item)
   if canceled then
      return nil, canceled
   end

   self.is_drawing = false
   local result = self.ctxt:on_select(item, amount, self.pages:iter_all_pages():extract("item"))
   self.is_drawing = true
   return result
end

function InventoryMenu:on_menu_exit()
   return self.ctxt:on_menu_exit()
end

function InventoryMenu:relayout(x, y)
   self.width = 640
   self.height = 432
   self.x, self.y = Ui.params_centered(self.width, self.height)
   self.t = UiTheme.load(self)

   self.chip_batch = Draw.make_chip_batch("chip")
   -- >>>>>>>> shade2/command.hsp:3569 		x=winPosX(640)+455 ...
   local te_width, te_height = 200, 102
   local te_x, te_y = Ui.params_centered(self.width, self.height)
   te_x = te_x + 455
   te_y = te_y - 32
   self.target_equip:relayout(te_x, te_y, te_width, te_height)
   -- <<<<<<<< shade2/command.hsp:3574 		window x,y,w,h-h¥8,0,0 ..

   self.win:relayout(self.x, self.y, self.width, self.height)
   self.pages:relayout(self.x + 58, self.y + 60)
   self.win:set_pages(self.pages)
end

function InventoryMenu:update_icons_this_page()
   for _, entry in self.pages:iter() do
      if not entry.icon then
         entry.icon = entry.item:calc("image")
      end
   end
end

function InventoryMenu.filter_item(ctxt, item)
   return ctxt:filter(item)
end

function InventoryMenu.build_list(ctxt)
   local filtered = {}
   local all = {}

   local sources = ctxt.sources
   if type(sources) == "string" then
      sources = {sources}
   end

   -- Obtain an iterator of IItem for each source. For example, calls
   -- IChara:iter_inventory() for the "chara" and "target" sources.
   for _, source in pairs(sources) do
      local items = source.getter(ctxt)
      items = items:map(function(item)
            return {
               item = item,
               source = source,
               text = item:build_name(),
               color = item:calc("color")
            }
      end)

      all[#all+1] = items
   end

   -- Combine each source iterator into one chained iterator.
   local iter = fun.chain(table.unpack(all))

   -- Filter invalid items and items that do not pass the filter
   -- configured for the inventory action.
   for _, entry in iter:unwrap() do
      local item = entry.item
      if item.amount <= 0 then
         item:remove_ownership()
      else
         if InventoryMenu.filter_item(ctxt, item) then
            filtered[#filtered+1] = entry
         end
      end
   end

   -- Sort everything. Defaults to item ID but can be configured per
   -- inventory context.

   -- NOTE: This needs to be a stable sort, which table.sort isn't. If
   -- correctness is not important, it should use merge sort...
   table.insertion_sort(filtered, ctxt:gen_sort())

   return filtered
end

function InventoryMenu:update_filtering()
   local filtered = InventoryMenu.build_list(self.ctxt)

   self.pages:set_data(filtered)
   self:update_icons_this_page()
   --
   -- TODO: Determine when to display weight. Inventory contexts can
   -- be created out of any number of sources that might exclude a
   -- character, like a spot on the map.
   self.total_weight = Ui.display_weight(self.ctxt.chara:calc("inventory_weight"))
   self.max_weight = Ui.display_weight(self.ctxt.chara:calc("max_inventory_weight"))
   self.cargo_weight = Ui.display_weight(self.ctxt.chara:calc("cargo_weight"))

   if self.ctxt.show_money and self.ctxt.target then
      self.money = self.ctxt.target.gold
   end

   if self.ctxt.show_target_equip and self.ctxt.target then
      self.target_equip:set_data(self.ctxt.target)

      local map = function(slot)
         return {
            text = I18N.get("ui.body_part." .. slot.body_part._id),
            has_equipment = slot.equipped ~= nil
         }
      end

      self.text_equip_slots = self.ctxt.target:iter_body_parts(true):map(map):to_list()
   end

   -- Run after filter actions that can return a turn result, like
   -- exiting the menu preemptively if a condition is false (for
   -- example, an altar is not on ground when praying).
   local result = self.ctxt:after_filter(filtered)
   if result then
      self.result = result
   end

   if self.ctxt.proto.show_weight_text then
      local weight_text = I18N.get("ui.inv.window.total_weight", self.total_weight, self.max_weight, self.cargo_weight)
      self.total_weight_text = ("%d items  (%s)"):format(self.pages:len(), weight_text)
   else
      self.total_weight_text = ""
   end
end

function InventoryMenu:draw()
   if not self.is_drawing then
      return
   end

   self.win:draw()

   Draw.set_color(255, 255, 255)
   self.t.base.inventory_icons:draw_region(self.ctxt.icon, self.x + 46, self.y - 14)

   self.t.base.deco_inv_a:draw(self.x + self.width - 136, self.y - 6)
   if self.layout == nil then
      self.t.base.deco_inv_b:draw(self.x + self.width - 186, self.y - 6)
   end
   self.t.base.deco_inv_c:draw(self.x + self.width - 246, self.y - 6)
   self.t.base.deco_inv_d:draw(self.x - 6, self.y - 6)

   Ui.draw_topic("ui.inv.window.name", self.x + 28, self.y + 30)

   Ui.draw_topic(self.subtext_column, self.x + 526, self.y + 30)

   Ui.draw_note(self.total_weight_text, self.x, self.y, self.width, self.height, 0)

   if self.ctxt.show_target_equip then
      self.target_equip:draw()

      -- >>>>>>>> shade2/command.hsp:3579 		x=wX+40:y=wY+wH-65-wH¥8 ...
      local x = self.x + 40
      local y = self.y + self.height - 65 - (self.height % 8)
      Draw.text(I18N.get("ui.inv.take_ally.window.equip"), x, y)
      x = x + 60

      for _, slot in ipairs(self.text_equip_slots) do
         if slot.has_equipment then
            Draw.set_color(self.t.base.equip_slot_text_color_occupied)
         else
            Draw.set_color(self.t.base.equip_slot_text_color_empty)
         end
         Draw.text(slot.text, x, y)
         x = x + Draw.text_width(slot.text) + Draw.text_width(" ")
      end
      -- <<<<<<<< shade2/command.hsp:3590 		loop ..
   end

   Draw.set_font(14) -- 14 - en * 2
   self.pages:draw()

   if self.ctxt.show_money then
      Draw.set_font(self.t.base.gold_count_font) -- 13 - en * 2
      self.t.base.gold_coin:draw(self.x + 340, self.y + 32, nil, nil, {255, 255, 255})
      Draw.text(("%d gp"):format(self.money), self.x + 368, self.y + 37, self.t.base.text_color)
   end
end

function InventoryMenu:update(dt)
   if self.pages.changed_page then
      self:update_icons_this_page()
      self.win:set_pages(self)
   end

   if self.pages.chosen then
      local can_select, reason = self:can_select()
      if type(can_select) == "string" then
         -- This is a turn result, like "turn_end".
         return can_select
      elseif not can_select then
         Gui.mes("Can't select: " .. reason)
      else
         if self.returns_item then
            return self:selected_item_object()
         end

         local result, canceled = self:on_select()

         if not canceled then
            if result == "inventory_continue" then
               self:update_filtering()
            elseif result == "inventory_cancel" then
               return nil, "canceled"
            else
               return result
            end
         end
      end
   end

   if self.result and self.result ~= "inventory_continue" then
      if self.result == "inventory_cancel" then
         return nil, "canceled"
      end
      return self.result
   end

   self.result = nil

   if self.canceled then
      if self.returns_item then
         return nil, "canceled"
      end

      local result = self:on_menu_exit()
      return result, "canceled"
   end

   self.target_equip:update(dt)
   self.pages:update(dt)
end

function InventoryMenu:release()
   self.chip_batch:release()
end

return InventoryMenu
