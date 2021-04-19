local IItemUseable = require("mod.elona.api.aspect.IItemUseable")
local Event = require("api.Event")
local IEvented = require("mod.elona.api.aspect.IEvented")
local Prompt = require("api.gui.Prompt")
local Gui = require("api.Gui")
local IItemThrowable = require("mod.elona.api.aspect.IItemThrowable")
local IItemFood = require("mod.elona.api.aspect.IItemFood")
local IItemReadable = require("mod.elona.api.aspect.IItemReadable")
local IItemDippable = require("mod.elona.api.aspect.IItemDippable")

local function permit_item_actions(item)
   if item:get_aspect(IItemFood) then
      item.can_eat = true
   end

   if item:has_category("elona.drink") then
      item.can_throw = true
   end

   if item:iter_aspects(IItemUseable):length() > 0 then
      item.can_use = true
   end

   if item:iter_aspects(IItemThrowable):length() > 0 then
      item.can_throw = true
   end

   if item:iter_aspects(IItemReadable):length() > 0 then
      item.can_read = true
   end

   if item:iter_aspects(IItemDippable):length() > 0 then
      item.can_dip_into = true
   end
end
Event.register("base.on_item_instantiated", "Permit item actions", permit_item_actions)

-- Queries the player for an aspect action to use if there is more than one
-- aspect on an item that fulfills a specific interface.
local function prompt_aspect(iface, name, cb_name, filter)
   filter = filter or function() return true end
   return function(item, params, result)
      local aspects = item:iter_aspects(iface):filter(function(a) return filter(a, item, params, result) end):to_list()

      if #aspects == 0 then
         return result
      elseif #aspects == 1 then
         local aspect = aspects[1]
         return aspect[cb_name](aspect, item, params, result)
      else
         local map = function(aspect)
            return aspect:localize_action(item, iface)
         end

         local choices = fun.iter(aspects):map(map):to_list()

         Gui.mes("base:aspect._.elona." .. name .. ".prompt", item:build_name(1))
         local result, canceled = Prompt:new(choices):query()

         if canceled then
            return "player_turn_query"
         end

         local aspect = aspects[result.index]
         return aspect[cb_name](aspect, item, params, result)
      end
   end
end

local aspect_item_useable = prompt_aspect(IItemUseable, "IItemUseable", "on_use")
Event.register("elona_sys.on_item_use", "Aspect: IItemUseable", aspect_item_useable)

local aspect_item_readable = prompt_aspect(IItemReadable, "IItemReadable", "on_read")
Event.register("elona_sys.on_item_read", "Aspect: IItemReadable", aspect_item_readable)

local function dippable_filter(aspect, item, params)
   return aspect:can_dip_into(item, params.target_item)
end
local aspect_item_dippable = prompt_aspect(IItemDippable, "IItemDippable", "on_dip_into", dippable_filter)
Event.register("elona_sys.on_item_dip_into", "Aspect: IItemDippable", aspect_item_dippable)

local function aspect_item_dippable_can_dip_into(dip_item, params, result)
   for _, aspect in dip_item:iter_aspects(IItemDippable) do
      if aspect:can_dip_into(dip_item, params.item) then
         return true
      end
   end
   return false
end
Event.register("elona_sys.calc_item_can_dip_into", "Aspect: IItemDippable can dip into", aspect_item_dippable_can_dip_into)

local _retain = setmetatable({}, { __mode = "k" })
local function aspect_evented(obj, params, result)
   for _, aspect in obj:iter_aspects(IEvented) do
      obj:connect_self_multiple(aspect:get_events(obj), true)
   end
   _retain[obj] = true

   return result
end
Event.register("base.on_object_instantiated", "Aspect: IEvented", aspect_evented)

local function aspect_item_throwable(obj, params, result)
   local did_something

   for _, aspect in obj:iter_aspects(IItemThrowable) do
      if aspect:on_thrown(obj, params, result) then
         did_something = true
         break
      end
   end

   if did_something then
      return "turn_end"
   end

   return result
end
Event.register("elona_sys.on_item_throw", "Aspect: IItemThrowable", aspect_item_throwable)

require("mod.elona.events.aspect.sand_bag")
