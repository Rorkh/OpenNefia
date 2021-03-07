local Item = require("api.Item")
local Rank = require("mod.elona.api.Rank")
local Gui = require("api.Gui")
local I18N = require("api.I18N")
local InstancedMap = require("api.InstancedMap")
local InstancedArea = require("api.InstancedArea")
local Area = require("api.Area")
local Inventory = require("api.Inventory")
local Chara = require("api.Chara")
local Calc = require("mod.elona.api.Calc")
local Save = require("api.Save")
local Log = require("api.Log")

local Home = {}

function Home.is_home(map)
   -- TODO this should return true for any map globally marked as a home, not
   -- depending on the map/area archetype. Maybe we can have areas that hold the
   -- home map, and the rest of the floors are non-home maps.
   --
   -- For now, the assumption is that the home and area will both have the
   -- "elona.your_home" archetype.
   class.assert_is_an(InstancedMap, map)
   return map._archetype == "elona.your_home"
end

function Home.is_home_area(area)
   -- TODO as above
   class.assert_is_an(InstancedArea, area)
   return area._archetype == "elona.your_home"
end

function Home.iter_home_areas()
   return Area.iter():filter(Home.is_home_area)
end

function Home.calc_furniture_value(item)
   -- >>>>>>>> shade2/map_user.hsp:688 	if a=fltFurniture{ ...
   if not item:has_category("elona.furniture") then
      return 0
   end

   return math.clamp(math.floor(item:calc("value") / 50), 50, 500)
   -- <<<<<<<< shade2/map_user.hsp:690 		} ..
end

function Home.calc_item_value(item)
   -- >>>>>>>> shade2/map_user.hsp:692 	p=iValue(val) ...

   -- XXX: this is weird. Shouldn't it be (value * amount)? This means that you
   -- can trivially get more heirloom points by separating your item stack
   -- instead of putting the items in piles.
   local value = item:calc("value")

   if item:has_category("elona.furniture") then
      value = value / 20
   elseif item:has_category("elona.tree") then
      value = value / 10
   elseif item:has_category("elona.ore") then
      value = value / 10
   else
      value = value / 1000
   end

   return math.floor(value)
   -- <<<<<<<< shade2/map_user.hsp:707 	return ...
end

function Home.calc_most_valuable_items(map)
   -- >>>>>>>> shade2/map_user.hsp:700  ...
   local to_tuple = function(item)
      return {
         item = item,
         value = Home.calc_item_value(item)
      }
   end

   local sort = function(a, b) return a.value > b.value end

   return Item.iter(map):map(to_tuple):into_sorted(sort):take(10):to_list()
   -- <<<<<<<< shade2/map_user.hsp:707 	return ..
end

function Home.calc_total_home_value(map)
   return fun.iter(Home.calc_most_valuable_items(map)):extract("value"):foldl(fun.op.add, 0)
end

function Home.calc_total_furniture_value(map)
   return Item.iter(map):map(Home.calc_furniture_value):foldl(fun.op.add, 0)
end

function Home.calc_total_value(base_value, home_value, furniture_value)
   return math.floor(base_value + furniture_value + home_value / 3)
end

function Home.calc_rank(map)
   local base_value = map:calc("home_rank_points") or 0
   local home_value = math.clamp(0, Home.calc_total_home_value(map), 10000)
   local furniture_value = math.clamp(0, Home.calc_total_furniture_value(map), 10000)

   return math.max(10000 - Home.calc_total_value(base_value, home_value, furniture_value), 100), base_value, home_value, furniture_value
end

function Home.update_rank(map)
   local new_exp, base_value, home_value, furniture_value = Home.calc_rank(map)
   local old_exp = Rank.get("elona.home")

   if new_exp ~= old_exp then
      local color

      -- 1st rank is better than 10th rank.
      if new_exp < old_exp then
         color = "Green"
      else
         color = "Purple"
      end

      Gui.mes_c("building.home.rank.change", color,
                math.floor(furniture_value / 100),
                math.floor(home_value / 100),
                math.floor(old_exp / 100),
                math.floor(new_exp / 100),
                Rank.title("elona.home", new_exp))
   end

   Rank.set("elona.home", new_exp, true)

   return new_exp, base_value, home_value, furniture_value
end

function Home.add_salary_to_salary_chest(salary_chest_inv)
   salary_chest_inv = salary_chest_inv or Inventory.get_or_create("elona.salary_chest")

   local player = Chara.player()
   local gold = Calc.calc_actual_income(player)
   local items = Calc.calc_income_items(player)
   local item_count = #items

   assert(Item.create("elona.gold_piece", nil, nil, {amount=gold}, salary_chest_inv))
   for _, item in ipairs(items) do
      if not salary_chest_inv:take_object(item) then
         Log.error("Salary chest could not receive item '%s'", item._id)
      end
   end

   local text
   if gold > 0 then
      if item_count > 0 then
         text = I18N.get("misc.income.sent_to_your_house2", gold, item_count)
      else
         text = I18N.get("misc.income.sent_to_your_house", gold)
      end
   end

   if text then
      Gui.play_sound("base.ding2")
      Gui.mes_c(text)
      Save.queue_autosave()
   end
end

return Home
