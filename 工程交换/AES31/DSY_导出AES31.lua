---------------------------------设置区---------------------------------
local debugmode="off"

local show="off"

local nuendo="off"

local keep="off"
------------------------------------------------------------------------
local info = debug.getinfo(1,'S')

local main_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

main_path=main_path.."\\DSY_导出AES31主体.lua"

local check=reaper.file_exists(main_path)

if not check then reaper.MB("请先把DSY_导出AES31主体.lua文件与此文件放在一起", "文件缺失", 0) return end

dofile(main_path)

main(debugmode, show, nuendo, keep)