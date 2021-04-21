local i18n = require("internal.i18n")
local Rand = require("api.Rand")

local jp = {}

function jp.you()
   return i18n.get("chara.you")
end

function jp.name(obj, ignore_sight)
   -- >>>>>>>> shade2/init.hsp:4082 	#defcfunc name int tc ..
   if type(obj) == "table" then
      if obj.is_player then
         return jp.you()
      end

      if not obj.is_visible and not ignore_sight then
         return i18n.get("chara.something")
      end

      return obj.name or i18n.get("chara.something")
   end
   -- <<<<<<<< shade2/init.hsp:4090 	return cnName(tc) ..

   return i18n.get("chara.something")
end

function jp.basename(obj)
   if type(obj) == "table" then
      return obj.basename or obj.name or i18n.get("chara.something")
   end

   return i18n.get("chara.something")
end

jp.itemname = jp.name
jp.itembasename = jp.basename

function jp.ordinal(n)
   return tostring(n)
end

function jp.he(obj)
   if not type(obj) == "table" then
      return "彼"
   end

   if obj.gender == "male" then
      return "彼"
   else
      return "彼女"
   end
end

function jp.his(obj)
   if not type(obj) == "table" then
      return "彼の"
   end

   if obj.is_player then
      return "あなたの"
   elseif obj.gender == "male" then
      return "彼の"
   else
      return "彼女の"
   end
end

function jp.him(obj)
   if not type(obj) == "table" then
      return "彼"
   end

   if obj.gender == "male" then
      return "彼"
   else
      return "彼女"
   end
end

function jp.kare_wa(obj)
   if not type(obj) == "table" then
      return "それは"
   end

   if obj.is_player then
      return ""
   elseif not obj.is_visible then
      return "それは"
   else
      return obj.name .. "は"
   end
end

function jp.nii(obj)
   if not type(obj) == "table" then
      return "兄"
   end

   if obj.gender == "male" then
      return "兄"
   else
      return "姉"
   end
end

function jp.syujin(obj)
   if not type(obj) == "table" then
      return "ご主人様"
   end

   if obj.gender == "male" then
      return "ご主人様"
   else
      return "お嬢様"
   end
end

local marks = {"。", "？", "！", ""}
local endings = {
   yoro = {
      {{"よろしくお願いします", "どうぞ、よろしくです"},
         {"よろしくお願いしますわ", "よろしくです"}},
      {{"よろしく頼むぜ", "よろしくな"},
         {"よろしくね", "よろしくな"}},
      {{"よろしくね", "よろしくお願いするよ"},
         {"よろしくねっ", "よろしく〜"}},
      {{"よろしく…", "今後とも、よろしく…"},
         {"よろしくね…", "よろ…"}},
      {{"よろしく頼もう", "よろしく頼むぞよ"},
         {"よろしく頼むぞよ", "よろしく頼むぞな"}},
      {{"よしなに", "よろしく頼むでござる"},
         {"よろしくでござりまする", "どうぞよしなに"}},
      {{"よろしくッス"},
         {"よろしくにゃの"}},
   },
   dozo = {
      {{"はい、どうぞ", "お待ちどうさまです"},
         {"はい、どうぞ", "注文の品ですわ"}},
      {{"ほらよ", "ほれ"},
         {"ほら", "待たせたね"}},
      {{"はい、お待ち", "さあ、どうぞ"},
         {"さあ、どうぞ", "お待ちどうさま"}},
      {{"ほら…", "待たせたな…"},
         {"はい…", "どうぞ…"}},
      {{"ほうれ", "ほれ、受け取りたまえ"},
         {"ほれ、受け取るが良い", "ほれ、待たせたのう"}},
      {{"お待たせ申した", "待たせたでござる"},
         {"お待たせ致しました", "ささ、どうぞ"}},
      {{"お待たせッス"},
         {"お待たせにゃん"}},
   },
   thanks = {
      {{"感謝します", "ありがとうございます"},
         {"感謝します", "ありがとうございます"}},
      {{"ありがとよ", "ありがたい"},
         {"礼を言うよ", "ありがたいね"}},
      {{"ありがとう", "感謝するよ"},
         {"ありがとう〜", "感謝するわ"}},
      {{"礼を言う…", "感謝する…"},
         {"ありがと…", "礼を言うわ…"}},
      {{"礼を申すぞ", "感謝してつかわす"},
         {"くるしゅうない", "礼をいってつかわす"}},
      {{"かたじけない", "恩に着る"},
         {"ありがたや", "お礼申し上げます"}},
      {{"アザーッス"},
         {"にゃりーん"}},
   },
   rob = {
      {{"悪いことは言わない。おやめなさい", "止めてください。きっと後悔しますよ"},
         {"止めてくださいませ", "こういう時のために、傭兵に金をかけているのです"}},
      {{"なんだ、貴様賊だったのか", "馬鹿な奴だ。後になって謝っても遅いぞ"},
         {"ふん、返り討ちにしてくれるよ", "ごろつき風情に何ができる"}},
      {{"おい、傭兵さんたち、このごろつきを追い払ってくれ", "馬鹿な真似をするな。こっちには屈強の傭兵がいるんだぞ"},
         {"やめて", "傭兵さんたち〜出番ですよ"}},
      {{"甘く見られたものだ…", "この護衛の数が見えないのか…"},
         {"おやめ…", "愚かな試みよ…"}},
      {{"なんたる無礼者か", "ほほほ、こやつめ"},
         {"下賤の者どもの分際で", "ほほほ、殺してあげなさい"}},
      {{"何をするでござるか"},
         {"ご無体な", "まあ、お戯れが過ぎますわ"}},
      {{"見損なったッス"},
         {"にゃりーん"}},
   },
   ka = {
      {{"ですか"},
         {"ですか"}},
      {{"かよ", "か"},
         {"かい"}},
      {{"かい", "なの"},
         {"なの"}},
      {{"か…", "かよ…"},
         {"なの…"}},
      {{"かのう", "であるか"},
         {"であるか"}},
      {{"でござるか"},
         {"でござりまするか"}},
      {{"ッスか"},
         {"かにゃ", "かニャン"}},
   },
   da = {
      {{"です", "ですね"},
         {"ですわ", "です"}},
      {{"だぜ", "だ"},
         {"ね", "よ"}},
      {{"だよ"},
         {"だわ", "よ"}},
      {{"だ…", "さ…"},
         {"よ…", "ね…"}},
      {{"じゃ", "でおじゃる"},
         {"じゃ", "でおじゃるぞ"}},
      {{"でござる", "でござるよ"},
         {"でござりまする"}},
      {{"ッス"},
         {"みゃん", "ミャ"}},
   },
   noda = {
      {{"のです", "んです"},
         {"のですわ", "のです"}},
      {{"", "んだ"},
         {"の"}},
      {{"んだよ", "んだ"},
         {"わ", "のよ"}},
      {{"…", "んだ…"},
         {"の…", "わ…"}},
      {{"のじゃ", "のだぞよ"},
         {"のじゃわ", "のだぞよ"}},
      {{"のでござる"},
         {"のでございます"}},
      {{"んだッス"},
         {"のニャ", "のにゃん"}},
   },
   noka = {
      {{"のですか", "んですか"},
         {"のですか", "んですか"}},
      {{"のか", "のだな"},
         {"の", "のかい"}},
      {{"のかい", "の"},
         {"の"}},
      {{"のか…"},
         {"の…"}},
      {{"のかのう", "のだな"},
         {"のかね", "のだな"}},
      {{"のでござるか"},
         {"のでございます"}},
      {{"のッスか"},
         {"にゃんか", "ニャン"}},
   },
   kana = {
      {{"でしょうか", "ですか"},
         {"かしら", "でしょう"}},
      {{"か", "かい"},
         {"か", "かい"}},
      {{"かな", "かなぁ"},
         {"かな", "かなー"}},
      {{"かな…", "か…"},
         {"かな…", "か…"}},
      {{"かのう", "かの"},
         {"かのう", "かの"}},
      {{"でござるか"},
         {"でございますか"}},
      {{"ッスか"},
         {"かにゃん", "かニャ"}},
   },
   kimi = {
      {{"貴方"},
         {"貴方"}},
      {{"お前"},
         {"お前"}},
      {{"君"},
         {"君"}},
      {{"君"},
         {"君"}},
      {{"お主"},
         {"お主"}},
      {{"そこもと"},
         {"そなた様"}},
      {{"アンタ"},
         {"あにゃた"}},
   },
   ru = {
      {{"ます", "ますよ"},
         {"ますわ", "ますの"}},
      {{"るぜ", "るぞ"},
         {"るわ", "るよ"}},
      {{"るよ", "るね"},
         {"るの", "るわ"}},
      {{"る…", "るが…"},
         {"る…", "るわ…"}},
      {{"るぞよ", "るぞ"},
         {"るぞよ", "るぞ"}},
      {{"るでござる", "るでござるよ"},
         {"るのでございます"}},
      {{"るッス"},
         {"るのニャ", "るにゃん"}},
   },
   tanomu = {
      {{"お願いします", "頼みます"},
         {"お願いしますわ", "頼みますわ"}},
      {{"頼む", "頼むな"},
         {"頼むよ", "頼む"}},
      {{"頼むね", "頼むよ"},
         {"頼むわ", "頼むね"}},
      {{"頼む…", "頼むぞ…"},
         {"頼むわ…", "頼むよ…"}},
      {{"頼むぞよ"},
         {"頼むぞよ"}},
      {{"頼み申す", "頼むでござる"},
         {"お頼み申し上げます"}},
      {{"頼むッス"},
         {"おねがいにゃ", "おねがいニャン"}},
   },
   ore = {
      {{"私"},
         {"私"}},
      {{"俺"},
         {"あたし"}},
      {{"僕"},
         {"わたし"}},
      {{"自分"},
         {"自分"}},
      {{"麻呂"},
         {"わらわ"}},
      {{"拙者"},
         {"手前"}},
      {{"あっし"},
         {"みゅー"}},
   },
   ga = {
      {{"ですが", "ですけど"},
         {"ですが", "ですけど"}},
      {{"が", "がな"},
         {"が"}},
      {{"けど", "が"},
         {"が", "けど"}},
      {{"が…", "けど…"},
         {"が…", "けど…"}},
      {{"であるが"},
         {"であるが"}},
      {{"でござるが"},
         {"でございますが"}},
      {{"ッスけど", "ッスが"},
         {"ニャけど", "にゃが"}},
   },
   dana = {
      {{"ですね"},
         {"ですわね", "ですね"}},
      {{"だな"},
         {"だね", "ね"}},
      {{"だね"},
         {"ね"}},
      {{"だな…"},
         {"だね…", "ね…"}},
      {{"であるな"},
         {"であるな"}},
      {{"でござるな"},
         {"でございますね"}},
      {{"ッスね"},
         {"にゃ", "みゃ"}},
   },
   kure = {
      {{"ください", "くださいよ"},
         {"くださいな", "ください"}},
      {{"くれ", "くれよ"},
         {"くれ", "よ"}},
      {{"ね", "よ"},
         {"ね", "ね"}},
      {{"くれ…", "…"},
         {"よ…", "…"}},
      {{"つかわせ", "たもれ"},
         {"つかわせ", "たもれ"}},
      {{"頂きたいでござる"},
         {"くださいませ"}},
      {{"くれッス"},
         {"にゃ", "みゃ"}},
   },
   daro = {
      {{"でしょう"},
         {"でしょう"}},
      {{"だろ"},
         {"だろうね"}},
      {{"だろうね"},
         {"でしょ"}},
      {{"だろ…"},
         {"でしょ…"}},
      {{"であろう"},
         {"であろうな"}},
      {{"でござろうな"},
         {"でございましょう"}},
      {{"ッスね"},
         {"にゃ", "みゃ"}},
   },
   yo = {
      {{"ですよ", "です"},
         {"ですよ", "です"}},
      {{"ぜ", "ぞ"},
         {"わ", "よ"}},
      {{"よ", "ぞ"},
         {"わよ", "わ"}},
      {{"…", "ぞ…"},
         {"わ…", "…"}},
      {{"であろう", "でおじゃる"},
         {"であろうぞ", "でおじゃる"}},
      {{"でござろう"},
         {"でございますわ"}},
      {{"ッスよ", "ッス"},
         {"にゃぁ", "みゃぁ"}},
   },
   aru = {
      {{"あります", "ありますね"},
         {"あります", "ありますわ"}},
      {{"ある", "あるな"},
         {"あるね", "あるよ"}},
      {{"あるね", "あるよ"},
         {"あるわ", "あるわね"}},
      {{"ある…", "あるぞ…"},
         {"あるわ…"}},
      {{"あろう", "おじゃる"},
         {"あろう", "おじゃる"}},
      {{"あるでござる", "あるでござるな"},
         {"ござます"}},
      {{"あるッスよ", "あるッス"},
         {"あにゅ", "あみぅ"}},
   },
   u = {
      {{"います", "いますよ"},
         {"いますわ", "います"}},
      {{"うぜ", "うぞ"},
         {"うわ", "うよ"}},
      {{"うよ", "う"},
         {"うわ", "う"}},
      {{"う…", "うぞ…"},
         {"うわ…", "う…"}},
      {{"うぞよ", "うぞ"},
         {"うぞよ", "うぞ"}},
      {{"うでござる", "うでござるよ"},
         {"うでございます"}},
      {{"うッスよ", "うッス"},
         {"うにぁ", "うみぁ"}},
   },
   na = {
      {{"ですね", "です"},
         {"ですわ", "ですね"}},
      {{"ぜ", "な"},
         {"ね", "な"}},
      {{"ね", "なぁ"},
         {"わ", "わね"}},
      {{"…", "な…"},
         {"…", "わ…"}},
      {{"でおじゃるな", "のう"},
         {"でおじゃるな", "のう"}},
      {{"でござるな"},
         {"でございますわ"}},
      {{"ッスね", "ッス"},
         {"ニァ", "ミァ"}},
   },
   ta = {
      {{"ました", "ましたね"},
         {"ました", "ましたわ"}},
      {{"た", "たな"},
         {"たね", "たよ"}},
      {{"たね", "たよ"},
         {"たよ", "たね"}},
      {{"た…", "たぞ…"},
         {"たわ…"}},
      {{"たぞよ", "たぞな"},
         {"たぞよ"}},
      {{"たでござる"},
         {"ましてございます"}},
      {{"たッスよ", "たッス"},
         {"たにゃぁ", "たみゃぁ"}},
   },
}

for name, list in pairs(endings) do
   jp[name] = function(obj, mark)
      mark = mark and (mark+1) or 1

      local gender_index
      if obj.gender == "male" then
         gender_index = 1
      else
         gender_index = 2
      end

      local base = list[(obj.talk_type or 0) + 1]
      if not base then
         base = list[1]
      end
      local choices = base[gender_index] or {""}
      return ("%s%s"):format(Rand.choice(choices), marks[mark] or marks[1])
   end
end

return jp
