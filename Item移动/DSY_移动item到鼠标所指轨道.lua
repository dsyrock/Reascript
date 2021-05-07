--[[
ReaScript Name: 移动item到鼠标所指轨道
Version: 1.0
Author: noiZ
]]

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end
local tr=reaper.BR_TrackAtMouseCursor()
if not tr then return end

local its={}
for i=0, num-1 do
    table.insert(its, reaper.GetSelectedMediaItem(0, i))
end

for k, v in pairs(its) do
    reaper.MoveMediaItemToTrack(v, tr)
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('移动item到鼠标所指轨道', -1)