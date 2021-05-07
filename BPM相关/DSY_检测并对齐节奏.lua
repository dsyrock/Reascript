--[[
ReaScript Name: 检测并对齐节奏
Version: 1.0
Author: noiZ
]]
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
local left, right=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
if num==0 or (num~=2 and right==0) or (right==0 and num<2) then return end

local cur=reaper.GetCursorPosition()
local l, r, it1
if right>0 then
    l, r=left, right
else
    it1=reaper.GetSelectedMediaItem(0, 0)
    l, r=reaper.GetMediaItemInfo_Value(it1, 'D_POSITION'), reaper.GetMediaItemInfo_Value(it1, 'D_POSITION')+reaper.GetMediaItemInfo_Value(it1, 'D_LENGTH')
end

reaper.SetEditCurPos(l, 0, 0)
reaper.Main_OnCommand(40541, 0)  --set snap to cursor
reaper.GetSet_LoopTimeRange(1, 1, l, r, 0)
reaper.Main_OnCommand(41597, 0)  --set tempo

if it1 then reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(it1), it1) end
reaper.Main_OnCommand(40020, 0)  --remove ts
reaper.SetEditCurPos(cur, 0, 0)
reaper.Main_OnCommand(41040, 0)  --move cursor to next measure
reaper.Main_OnCommand(41205, 0)  --move item to cursor

reaper.Main_OnCommand(41173, 0)  --move cursor to item start
reaper.Main_OnCommand(40541, 0)  --set snap to cursor
reaper.SetEditCurPos(cur, 0, 0)

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)