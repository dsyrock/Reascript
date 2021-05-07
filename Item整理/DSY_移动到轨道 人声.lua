---------------------------------设置区---------------------------------
local track_name="人声"

local is_del=true
------------------------------------------------------------------------
local info = debug.getinfo(1,'S')

local main_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

show_path=main_path.."\\DSY_show VO tracks.lua"

main_path=main_path.."\\DSY_移动到轨道 主体.lua"

local check=reaper.file_exists(main_path)

if not check then reaper.MB("请先把DSY_移动到轨道 主体.lua文件与此文件放在一起", "文件缺失", 0) return end

dofile(main_path)

move_to_track(track_name, is_del)

dofile(show_path)
