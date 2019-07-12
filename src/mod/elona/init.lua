data:extend_type(
   "base.map_tile",
   {
      field_type = schema.Optional(schema.String),
   }
)

require("mod.elona.data.resolver")
require("mod.elona.data.skill")
require("mod.elona.data.body_part")
require("mod.elona.data.class")
require("mod.elona.data.race")
require("mod.elona.data.chara")
require("mod.elona.data.item")
require("mod.elona.data.effects")
require("mod.elona.data.feat")
require("mod.elona.data.scenario")
require("mod.elona.data.chip")
require("mod.elona.data.map_tile")
require("mod.elona.data.map_template")
require("mod.elona.data.map_generator")
