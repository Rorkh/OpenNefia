local Area = require("api.Area")
local Gui = require("api.Gui")
local Map = require("api.Map")
local Input = require("api.Input")
local state = require("mod.test_room.internal.global.state")
local Quest = require("mod.elona_sys.api.Quest")
local Chara = require("api.Chara")
local Magic = require("mod.elona_sys.api.Magic")
local Dialog = require("mod.elona_sys.dialog.api.Dialog")

data:add {
   _type = "base.feat",
   _id = "select_map",

   image = "elona.feat_quest_board",
   is_solid = true,
   is_opaque = false,

   on_bumped_into = function(self, params)
      local pred = function(arc) return state.is_test_map[arc._id] end
      local arcs = data["base.map_archetype"]:iter():filter(pred)

      local choices = arcs:map(function(arc) return arc._id:gsub("^.*%.", "") end):to_list()
      local choice, canceled = Input.prompt(choices)
      if canceled then
         return
      end
      local arc = arcs:nth(choice.index)

      local area = Area.for_map(self:current_map())
      local floor = area:deepest_floor() + 1
      local ok, map = area:load_or_generate_floor(floor, arc._id)
      if not ok then
         Gui.mes_c("Could not generate map: " .. map, "Red")
      end

      Gui.play_sound("base.exitmap1")
      Map.travel_to(map)

      return "player_turn_query"
   end,
}

local function visit_quest_giver(quest)
   local player = Chara.player()
   local map = player:current_map()
   local client = Chara.find(quest.client_uid, "all", map)
   assert(client)
   Magic.cast("elona.shadow_step", {source=player, target=client})
   if Chara.is_alive(client) then
      Dialog.start(client, "elona.quest_giver:quest_about")
   end
end

data:add {
   _type = "base.feat",
   _id = "select_quest",

   image = "elona.feat_quest_board",
   is_solid = true,
   is_opaque = false,

   on_bumped_into = function(self, params)
      local pred = function(q) return q.on_time_expired ~= nil end
      local quests = data["elona_sys.quest"]:iter():filter(pred)

      local choices = quests:map(function(q) return q._id:gsub("^.*%.", "") end):to_list()
      local choice, canceled = Input.prompt(choices)
      if canceled then
         return
      end
      local quest = quests:nth(choice.index)

      local map = self:current_map()
      local client = assert(Quest.iter_clients_in_map(map):nth(1))
      local new_quest = Quest.generate_from_proto(quest._id, client, map)

      visit_quest_giver(new_quest)

      return "player_turn_query"
   end,
}
