local Dungeon = require("mod.elona.api.Dungeon")
local Rand = require("api.Rand")
local Itemgen = require("mod.tools.api.Itemgen")
local Filters = require("mod.elona.api.Filters")

local DungeonTemplate = {}

function DungeonTemplate.type_standard(floor, params)
   params.level = (params.level or 1) + floor - 1
   return Dungeon.gen_type_standard, params
end

function DungeonTemplate.type_wide(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.has_monster_houses = true
   return Dungeon.gen_type_wide, params
end

function DungeonTemplate.type_big_room(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.calc_density = function(map)
      local crowd_density = map:calc("max_crowd_density")
      return {
         mob = crowd_density / 2,
         item = crowd_density / 3
      }
   end

   return Dungeon.gen_type_big_room, params
end

function DungeonTemplate.type_resident(floor, params)
   params.level = (params.level or 1) + floor - 1
   return Dungeon.gen_type_resident, params
end

function DungeonTemplate.type_jail(floor, params)
   params.level = (params.level or 1) + floor - 1
   return Dungeon.gen_type_jail, params
end

function DungeonTemplate.type_hunt(floor, params)
   params.level = (params.level or 1) + floor - 1
   return Dungeon.gen_type_hunt, params
end

function DungeonTemplate.type_long(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.calc_density = function(map)
      local crowd_density = map:calc("max_crowd_density")
      return {
         mob = crowd_density / 4,
         item = crowd_density / 10
      }
   end

   return Dungeon.gen_type_long, params
end

function DungeonTemplate.type_maze(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.calc_density = function(map)
      local crowd_density = map:calc("max_crowd_density")
      return {
         mob = crowd_density / 3,
         item = crowd_density / 10
      }
   end
   params.after_generate = function(map)
      Itemgen.create(nil, nil, {categories=Rand.choice(Filters.fsetwear), quality=6}, map)
   end

   return Dungeon.gen_type_maze, params
end

function DungeonTemplate.type_puppy_cave(floor, params)
   params.level = (params.level or 1) + floor - 1
   function params.calc_density(map)
      local crowd_density = map:calc("max_crowd_density")
      return {
         mob = crowd_density / 3,
         item = crowd_density / 6
      }
   end

   return Dungeon.gen_type_puppy_cave, params
end


function DungeonTemplate.nefia_dungeon(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.tileset = "elona.dungeon"

   local gen = DungeonTemplate.type_wide
   if Rand.one_in(4) then
      gen = DungeonTemplate.type_standard
   end
   if Rand.one_in(6) then
      gen = DungeonTemplate.type_puppy_cave
   end
   if Rand.one_in(10) then
      gen = DungeonTemplate.type_resident
   end
   if Rand.one_in(25) then
      gen = DungeonTemplate.type_long
   end
   if Rand.one_in(25) then
      params.tileset = "elona.water"
   end

   return gen(floor, params)
end
-- image = "elona.feat_area_cave",

function DungeonTemplate.nefia_tower(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.tileset = "elona.tower_1"

   local gen = DungeonTemplate.type_standard
   if Rand.one_in(5) then
      gen = DungeonTemplate.type_resident
   end
   if Rand.one_in(10) then
      gen = DungeonTemplate.type_big_room
   end
   if Rand.one_in(25) then
      gen = DungeonTemplate.type_wide
   end
   if Rand.one_in(40) then
      params.tileset = "elona.water"
   end

   return gen(floor, params)
end
-- image = "elona.feat_area_tower",

function DungeonTemplate.nefia_forest(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.tileset = "elona.dungeon_forest"

   local gen = DungeonTemplate.type_wide
   if Rand.one_in(6) then
      gen = DungeonTemplate.type_standard
   end
   if Rand.one_in(6) then
      gen = DungeonTemplate.type_puppy_cave
   end
   if Rand.one_in(25) then
      gen = DungeonTemplate.type_long
   end
   if Rand.one_in(20) then
      gen = DungeonTemplate.type_resident
   end

   return gen(floor, params)
end
-- image = "elona.feat_area_tree",

function DungeonTemplate.nefia_castle(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.tileset = "elona.dungeon_castle"

   local gen = DungeonTemplate.type_standard
   if Rand.one_in(5) then
      gen = DungeonTemplate.type_resident
   end
   if Rand.one_in(6) then
      gen = DungeonTemplate.type_jail
   end
   if Rand.one_in(7) then
      gen = DungeonTemplate.type_wide
   end
   if Rand.one_in(40) then
      params.tileset = "elona.water"
   end

   return gen(floor, params)
end
-- image = "elona.feat_area_temple",

local function scale_density_with_floor(gen_params)
   gen_params.max_crowd_density = gen_params.width * gen_params.height / 100 + gen_params.level / 2
   return gen_params
end

function DungeonTemplate.lesimas(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.tileset = "elona.lesimas"
   params.on_generate_params = scale_density_with_floor

   if Rand.one_in(20) then
      params.tileset = "elona.water"
   end
   if floor < 35 then
      params.tileset = "elona.dungeon"
   end
   if floor < 20 then
      params.tileset = "elona.tower_1"
   end
   if floor < 10 then
      params.tileset = "elona.tower_2"
   end
   if floor < 5 then
      params.tileset = "elona.dungeon"
   end

   local gen = DungeonTemplate.type_standard
   if Rand.one_in(30) then
      gen = DungeonTemplate.type_big_room
   end

   local levels = {
      [1] = DungeonTemplate.type_wide,
      [5] = DungeonTemplate.type_jail,
      [10] = DungeonTemplate.type_big_room,
      [15] = DungeonTemplate.type_jail,
      [20] = DungeonTemplate.type_big_room,
      [25] = DungeonTemplate.type_jail,
      [30] = DungeonTemplate.type_big_room,
   }

   if levels[floor] then
      gen = levels[floor]
   else
      if floor < 30 and Rand.one_in(4) then
         gen = DungeonTemplate.type_wide
      end

      if Rand.one_in(5) then
         gen = DungeonTemplate.type_resident
      end
      if Rand.one_in(20) then
         gen = DungeonTemplate.type_long
      end
      if Rand.one_in(6) then
         gen = DungeonTemplate.type_puppy_cave
      end
   end

   return gen(floor, params)
end
-- image = "elona.feat_area_cave",

function DungeonTemplate.tower_of_fire(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.tileset = "elona.tower_of_fire"
   params.on_generate_params = scale_density_with_floor

   return Dungeon.gen_type_standard, params
end

function DungeonTemplate.crypt_of_the_damned(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.tileset = "elona.dungeon"
   params.on_generate_params = scale_density_with_floor

   return Dungeon.gen_type_standard, params
end

function DungeonTemplate.ancient_castle(floor, params)
   params.level = (params.level or 1) + floor - 1
   params.tileset = "elona.dungeon_castle"
   params.on_generate_params = scale_density_with_floor

   return Dungeon.gen_type_standard, params
end

return DungeonTemplate
