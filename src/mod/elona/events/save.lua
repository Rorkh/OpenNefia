local DateTime = require("api.DateTime")
local Event = require("api.Event")

local function init_save()
   local s = save.elona
   s.turns_until_cast_return = 0
   s.return_destination_map_uid = nil
   s.holy_well_count = 0
   s.guild = nil
   s.artifact_locations = {}
   s.inheritable_item_count = 0
   s.fire_giant_uid = nil
   s.is_fire_giant_released = false
   s.home_rank = "elona.cave"
   s.flag_has_met_ally = false
   s.total_skills_learned = 0
   s.waiting_guests = 0
   s.player_owned_buildings = {}
   s.is_lomias_easter_egg_enabled = false
   s.ranks = {
      ["elona.arena"] = 0,
      ["elona.pet_arena"] = 0,
      ["elona.crawler"] = 0,
      ["elona.museum"] = 0,
      ["elona.home"] = 0,
      ["elona.shop"] = 0,
      ["elona.vote"] = 0,
      ["elona.fishing"] = 0,
      ["elona.guild"] = 0
   }
   s.weather_id = "elona.sunny"
   s.turns_until_weather_changes = 0
   s.date_of_last_etherwind = DateTime:new()
   s.next_train_date = 0
end

Event.register("base.on_init_save", "Init save (elona)", init_save)
