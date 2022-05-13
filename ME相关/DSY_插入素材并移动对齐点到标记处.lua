--[[
ReaScript Name: 插入素材并移动对齐点到标记处
Version: 1.0
Author: noiZ
]]

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

if not reaper.JS_Window_Find then
    reaper.MB('请先安装JS API插件', '操作错误', 0)
    return
end

local left,right=reaper.GetSet_ArrangeView2(0, 0, 0, 0)
local cur=reaper.GetCursorPosition()
reaper.Main_OnCommand(41110, 0)  --select track under mouse
local title = reaper.JS_Localize("Media Explorer","common")
local hwnd = reaper.JS_Window_Find(title, true)
if hwnd then reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 41010, 0, 0, 0) else return end
local num=reaper.CountSelectedMediaItems(0)
local its={}
for i=0, num-1 do
    table.insert(its, reaper.GetSelectedMediaItem(0, i))
end
reaper.SelectAllMediaItems(0, 0)
for k, v in pairs(its) do
    reaper.SetMediaItemSelected(v, 1)
    reaper.Main_OnCommand(41173, 0)  --move cursor to start
    local curtemp=reaper.GetCursorPosition()
    reaper.Main_OnCommand(40741, 0)  --move cursor to cue
    local curcheck=reaper.GetCursorPosition()
    if curtemp~=curcheck then
        reaper.Main_OnCommand(40541, 0)  --set snap to cursor
    end
    reaper.SelectAllMediaItems(0, 0) 
end

for k, v in pairs(its) do
    reaper.SetMediaItemSelected(v, 1)
end
reaper.SetEditCurPos(cur, 0, 0)
reaper.Main_OnCommand(41205, 0)  --move item to cursor
reaper.GetSet_ArrangeView2(0, 1, 0, 0, left, right)
reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'), 0)
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)