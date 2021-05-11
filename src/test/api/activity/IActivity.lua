local InstancedMap = require("api.InstancedMap")
local Feat = require("api.Feat")
local Activity = require("api.Activity")
local Assert = require("api.test.Assert")
local I18N = require("api.I18N")
local Chara = require("api.Chara")
local TestUtil = require("api.test.TestUtil")

function test_IActivity__proto_values()
   local chara = Chara.create("base.player", 5, 5, {ownerless=true})
   local activity = Activity.create("elona.resting", {})
   Assert.eq(50, activity:get_default_turns({}, chara))
   Assert.eq(5, activity:get_animation_wait())
   Assert.eq(nil, activity:get_auto_turn_anim())
   Assert.eq(I18N.get("activity._.elona.resting.verb"), activity:get_localized_name())
end

function test_IActivity__proto_callbacks()
   local map = InstancedMap:new(10, 10)
   map:clear("elona.cobble")

   local chara = Chara.create("base.player", 5, 5, {}, map)
   local feat = Feat.create("elona.material_spot", 1, 1, {params={material_spot_info="elona.spring"}}, map)
   local activity = Activity.create("elona.searching", {feat = feat})
   Assert.eq(100, activity:get_default_turns({}, chara))
   Assert.eq(40, activity:get_animation_wait())
   Assert.eq("base.fishing", activity:get_auto_turn_anim())
   Assert.eq(I18N.get("activity._.elona.fishing.verb"), activity:get_localized_name())

   feat = Feat.create("elona.material_spot", 1, 2, {params={material_spot_info="elona.default"}}, map)
   activity = Activity.create("elona.searching", {feat = feat})
   Assert.eq(20, activity:get_default_turns({}, chara))
   Assert.eq(15, activity:get_animation_wait())
   Assert.eq("base.searching", activity:get_auto_turn_anim())
   Assert.eq(I18N.get("activity._.elona.searching.verb"), activity:get_localized_name())
end

function test_IActivity__proto_callbacks_chara()
   local map = InstancedMap:new(10, 10)
   map:clear("elona.cobble")

   local chara = Chara.create("base.player", 5, 5, {}, map)
   local feat = Feat.create("elona.material_spot", 1, 1, {params={material_spot_info="elona.spring"}}, map)
   local activity = Activity.create("elona.searching", {feat = feat})
   Assert.eq(100, activity:get_default_turns({}, chara))
   Assert.eq(40, activity:get_animation_wait())
   Assert.eq("base.fishing", activity:get_auto_turn_anim())
   Assert.eq(I18N.get("activity._.elona.fishing.verb"), activity:get_localized_name())

   feat = Feat.create("elona.material_spot", 1, 2, {params={material_spot_info="elona.default"}}, map)
   activity = Activity.create("elona.searching", {feat = feat})
   Assert.eq(20, activity:get_default_turns({}, chara))
   Assert.eq(15, activity:get_animation_wait())
   Assert.eq("base.searching", activity:get_auto_turn_anim())
   Assert.eq(I18N.get("activity._.elona.searching.verb"), activity:get_localized_name())
end

function test_IActivity__serialization()
   do
      local map = InstancedMap:new(10, 10)
      map:clear("elona.cobble")

      local player = Chara.create("base.player", 5, 5, {}, map)
      Chara.set_player(player)
      TestUtil.register_map(map)

      player:start_activity("elona.preparing_to_sleep")
      Assert.eq(player, player.activity.chara)
   end

   TestUtil.save_cycle()

   do
      local player = Chara.player()
      Assert.eq(player, player.activity.chara)

      player:pass_activity_turn()
   end
end
