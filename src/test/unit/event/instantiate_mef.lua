local InstancedMap = require("api.InstancedMap")
local Chara = require("api.Chara")
local test_util = require("test.lib.test_util")
local Assert = require("api.test.Assert")
local data = require("internal.data")
local Mef = require("api.Mef")

data:add {
   _type = "base.mef",
   _id = "nonsteppable",

   is_solid = true,
   is_opaque = false,

   on_stepped_on = nil
}

data:add {
   _type = "base.mef",
   _id = "steppable",

   is_solid = true,
   is_opaque = false,

   on_stepped_on = function() end
}

function test_object_change_prototype__mef_callbacks_added()
   do
      local map = InstancedMap:new(10, 10)
      map:clear("elona.cobble")

      local player = Chara.create("base.player", 5, 5, {}, map)
      Chara.set_player(player)
      test_util.register_map(map)

      local mef = Mef.create("base.nonsteppable", nil, nil, {}, map)
      Assert.is_falsy(mef:has_event_handler("elona_sys.on_mef_stepped_on"))

      mef:change_prototype("base.steppable")
      Assert.is_truthy(mef:has_event_handler("elona_sys.on_mef_stepped_on"))
   end

   test_util.save_cycle()

   do
      local player = Chara.player()
      local map = player:current_map()
      local mef = Mef.iter(map):nth(1)

      Assert.is_truthy(mef:has_event_handler("elona_sys.on_mef_stepped_on"))
   end
end

function test_object_change_prototype__mef_callbacks_removed()
   do
      local map = InstancedMap:new(10, 10)
      map:clear("elona.cobble")

      local player = Chara.create("base.player", 5, 5, {}, map)
      Chara.set_player(player)
      test_util.register_map(map)

      local mef = Mef.create("base.steppable", nil, nil, {}, map)
      Assert.is_truthy(mef:has_event_handler("elona_sys.on_mef_stepped_on"))

      mef:change_prototype("base.nonsteppable")
      Assert.is_falsy(mef:has_event_handler("elona_sys.on_mef_stepped_on"))
   end

   test_util.save_cycle()

   do
      local player = Chara.player()
      local map = player:current_map()
      local mef = Mef.iter(map):nth(1)

      Assert.is_falsy(mef:has_event_handler("elona_sys.on_mef_stepped_on"))
   end
end

function test_object_change_prototype__mef_callbacks_preserved()
   local map = InstancedMap:new(10, 10)
   map:clear("elona.cobble")

   local player = Chara.create("base.player", 5, 5, {}, map)
   Chara.set_player(player)
   test_util.register_map(map)

   local mef = Mef.create("base.steppable", nil, nil, {}, map)
   mef:connect_self("elona_sys.on_mef_stepped_on", "Unrelated event", function() end)
   Assert.is_truthy(mef:has_event_handler("elona_sys.on_mef_stepped_on"))

   mef:change_prototype("base.nonsteppable")
   Assert.is_truthy(mef:has_event_handler("elona_sys.on_mef_stepped_on"))
end
