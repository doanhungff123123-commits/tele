if getgenv().LuckyBloxLoaded then return end
getgenv().LuckyBloxLoaded = true

loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/hungdao/tele/main/Main.lua",
    true
))()
