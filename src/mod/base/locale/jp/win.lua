return {
   win = {
      conquer_lesimas = "信じられない！あなたはネフィアの迷宮「レシマス」を制覇した！",
      watch_event_again = "達成のシーンをもう一度再現する？",
      window = {
         arrived_at_tyris = function(_1, _2, _3)
            return ("%s年%s月%s日に、あなたはノースティリスに到着した。")
               :format(_1, _2, _3)
         end,
         caption = "制覇までの軌跡",
         comment = function(_1)
            return ("あなたは「%s」とコメントした。")
               :format(_1)
         end,
         have_killed = function(_1, _2)
            return ("最深で%s階相当まで到達し、%s匹の敵を殺して、")
               :format(_1, _2)
         end,
         lesimas = function(_1, _2, _3)
            return ("%s年%s月%s日にレシマスを制覇して、")
               :format(_1, _2, _3)
         end,
         score = function(_1)
            return ("現在%s点のスコアを叩き出している。")
               :format(_1)
         end,
         title = "*勝利*",
         your_journey_continues = "…あなたの旅はまだ終わらない。"
      },
      you_acquired_codex = function(_1, _2)
         return ("%s%sに祝福あれ！あなたは遂にレシマスの秘宝を手にいれた！")
            :format(_1, _2)
      end,
      words = {
         _0 = "遂に…！",
         _1 = "当然の結果だ",
         _2 = "おぉぉぉぉ！",
         _3 = "ふっ",
         _4 = "今日は眠れないな",
         _5 = "またそんな冗談を"
      },
      event = {
         text = {
            _0 = "「お前がここに辿り着くことは」台座から、何かの声が聞こえる。",

            _1 = "「決まっていたことなのだ…遅かれ早かれな」",
            _2 = "部屋の空気が突然緊張し、あなたの前に端麗な青年が現れた。",
            _3 = "「我々からすれば、複雑性の一面に過ぎないが、人間は運命とでも呼ぶのだろう？」",

            _4 = "あなたは懸命に脚の震えを抑えようとしたが、難しかった。",
            _5 = "華奢に見える幼顔の男の影は、人のものではない。",
            _6 = "あどけない瞳の奥に、あなたは底知れない力と闇を感じた。",

            _7 = "「ネフィアの永遠の盟約に基づき」青年は台座の横の死体を指し、皮肉な微笑を送った。",
            _8 = "「この哀れな老人が守っていたものは、今からお前のものだ」",

            _9 = "あなたは、台座の上に置かれている絢爛な装飾の本を、いぶかしげに眺めた。",

            _10 = "青年は悪戯っぽくニヤリと笑い、壁に寄りかかった。",

            _11 = "…どれくらい時間がたっただろう。氷の瞳の男は、いつの間にか姿を消していた。あなたは不安を振り払い、ゆっくりと本に手を伸ばした…",
         }
      }
   },
}
