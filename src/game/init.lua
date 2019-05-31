local MainTitleMenu = require("api.gui.menu.MainTitleMenu")
local Draw = require("api.Draw")
local Input = require("api.Input")
local internal = require("internal")

local game = {}
local chara_make = require("game.chara_make")

local function main_title()
   local title = require("api.gui.menu.chara_make.SelectBalanceMenu"):new({"ああ", "いや…"})

   local going = true
   local canceled
   while going do
      local choice = Input.query(title)

      if true then
         going, canceled = chara_make.query()
         if canceled then
            going = false
         end
      else
         error("no choice handler for " .. tostring(choice))
      end
   end

   return true
end

function game.loop()
   local action = main_title()
end

function game.draw()
   local going = true

   while going do
      internal.draw.draw_layers()

      going = coroutine.yield()
   end
end

return game
