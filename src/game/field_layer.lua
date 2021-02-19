local InputHandler = require("api.gui.InputHandler")
local IUiLayer = require("api.gui.IUiLayer")
local Event = require("api.Event")
local IInput = require("api.gui.IInput")
local KeyHandler = require("api.gui.KeyHandler")
local Log = require("api.Log")
local Env = require("api.Env")

local draw = require("internal.draw")
local draw_callbacks = require("internal.draw_callbacks")
local env = require("internal.env")
local field_renderer = require("internal.field_renderer")

local field_layer = class.class("field_layer", IUiLayer)

field_layer:delegate("keys", IInput)

function field_layer:init()
   self.is_active = false

   self.hud = require("api.gui.hud.MainHud"):new()

   self.map = nil
   self.renderer = nil
   self.repl = nil

   self.loaded = false
   self.map_changed = false
   self.no_scroll = true
   self.waiting_for_draw_callbacks = false
   self.sound_manager = require("internal.global.global_sound_manager")
   self.draw_callbacks = draw_callbacks:new()

   local keys = KeyHandler:new(true)
   self.keys = InputHandler:new(keys)
   self.keys:focus()
   -- TODO: Maybe we should rethink allowing "alt" as a part of movement
   -- keybinds
   self.keys:ignore_modifiers { "alt" }

   self.layers = {
      "internal.layer.tile_layer",
      "internal.layer.debris_layer",
      "internal.layer.chip_layer",
      "internal.layer.tile_overhang_layer",
      "internal.layer.emotion_icon_layer",
      "internal.layer.shadow_layer",
   }
end

function field_layer:make_keymap()
   return {}
end

function field_layer:setup_repl()
   -- avoid circular requires that depend on internal.field, since
   -- `Repl.generate_env()` auto-requires the full public API.
   local Repl = require("api.Repl")
   local ReplLayer = require("api.gui.menu.ReplLayer")

   local repl_env, history = Repl.generate_env()

   self.repl = ReplLayer:new(repl_env, { history = history, history_file = "data/repl_history" })
   self.repl:relayout()
end

function field_layer:init_global_data()
   self.player = nil
   self.map = nil

   Event.trigger("base.on_init_save")
end

function field_layer:set_map(map)
   assert(type(map) == "table")
   assert(map.uid, "Map must have UID")

   self.map = map
   self.map:redraw_all_tiles()
   if self.renderer == nil then
      self.renderer = field_renderer:new(map:width(), map:height(), self.layers)
   else
      self.renderer:set_map(map, self.layers)
   end
   self.map_changed = true
   self.no_scroll = true
end

function field_layer:relayout(x, y, width, height)
   self.x = x or self.x
   self.y = y or self.y
   self.width = width or self.width
   self.height = height or self.height
   self.hud:relayout(self.x, self.y, self.width, self.height)
end

function field_layer:on_theme_switched()
   -- Make sure that we redraw all tiles regardless of the FOV of the player. If
   -- we don't do this those tiles will get cleared from the theme switch, but
   -- not redrawn, so they will become black squares.
   if self.map then
      self.map:redraw_all_tiles()
   end

   if self.renderer then
      self.renderer:on_theme_switched()
   end
end

function field_layer:turn_cost()
   return self.map.turn_cost
end

function field_layer:get_object(_type, uid)
   return self.map and self.map:get_object_of_type(_type, uid)
end

function field_layer:set_camera_pos(x, y)
   self.camera_x = x
   self.camera_y = y
   self.renderer:update_draw_pos(x, y, 0)
   self.renderer:update(0)
   self:refresh_hud()
end

function field_layer:update_screen(scroll, dt)
   if not self.is_active or not self.renderer then return end

   if scroll == nil or self.no_scroll then
      scroll = false
   end

   assert(self.map ~= nil)

   local player = self.player
   local scroll_frames = 0
   if scroll then
      scroll_frames = 3
   end

   local center_x = self.camera_x or nil
   local center_y = self.camera_y or nil
   self.camera_x = nil
   self.camera_y = nil

   if center_x == nil and player then
      center_x = player.x
      center_y = player.y
      if scroll then
         scroll_frames = player:calc("scroll") or scroll_frames
      end
   end

   if center_x then
      self.renderer:update_draw_pos(center_x, center_y, scroll_frames)
   end

   if player then
      self.map:calc_screen_sight(player.x, player.y, player:calc("fov") or 15)
   end

   local dt = dt or 0

   if not Env.is_headless() then
      local going = true
      while going do
         self.keys:update_repeats(dt)
         going = self.renderer:update(dt)
         dt = coroutine.yield() or 0
      end

      self:refresh_hud()
   end

   self.no_scroll = false
end

function field_layer:key_held_frames()
   return self.keys:key_held_frames()
end

function field_layer:player_is_running()
   -- HACK
   return self.keys.keys.pressed["shift"]
end

function field_layer:refresh_hud()
   local player = self.player
   self.hud:refresh(player)
end


function field_layer:get_message_window()
   return self.hud.widgets:get("hud_message_window"):widget()
end

function field_layer:update(dt, ran_action, result)
   self.renderer:update(dt)
   self.draw_callbacks:update(dt)
   self.sound_manager:update(dt)
   self.hud:update(dt)
end

function field_layer:add_async_draw_callback(cb, tag)
   self.draw_callbacks:add(cb, tag)
end

function field_layer:remove_async_draw_callback(tag)
   self.draw_callbacks:remove(tag)
end

function field_layer:wait_for_draw_callbacks()
   self.draw_callbacks:wait()
end

function field_layer:update_draw_callbacks(dt)
   return self.draw_callbacks:update(dt)
end

function field_layer:draw()
   if not self.is_active or not self.renderer then
      return
   end

   self.renderer:draw()
   self.draw_callbacks:draw(self.renderer.draw_x, self.renderer.draw_y)
   self.hud:draw()
end

function field_layer:query_repl()
   if self.repl == nil then
      self:setup_repl()
   end

   if draw.is_layer_active(self.repl) then
      return
   end

   -- The repl could get hotloaded, so keep it in an upvalue.
   local repl = self.repl
   repl:query()

   if repl then
      repl:save_history()
   end
end

-- HACK: Needs to be replaced with resource system.
function field_layer:register_draw_layer(require_path)
   if env.is_hotloading() then
      Log.warn("Skipping draw layer register of '%s'", require_path)
      return
   end
   self.layers[#self.layers+1] = require_path
end

return field_layer
