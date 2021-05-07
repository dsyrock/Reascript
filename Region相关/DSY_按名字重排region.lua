--[[
ReaScript Name: 按名字重排region
Version: 1.0
Author: noiZ
]]

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountProjectMarkers(0)
if num==0 then return end

function add_it(pos, length, tr)
    local it=reaper.AddMediaItemToTrack(tr)
    reaper.SetMediaItemPosition(it, pos, 0)
    reaper.SetMediaItemLength(it, length, 0)
    return it
end

function del_it(it, tr)
    reaper.DeleteTrackMediaItem(tr, it)
end

function move(it, tr)
    reaper.SetMediaItemSelected(it, 1)
    reaper.Main_OnCommand(40311, 0)  --ripple all
    reaper.Main_OnCommand(41295, 0)  --duplicate
    reaper.Main_OnCommand(40309, 0)  --ripple off
    local it_new=reaper.GetSelectedMediaItem(0, 0)
    del_it(it_new, tr)
end

reaper.SelectAllMediaItems(0, 1)
local cur=reaper.GetCursorPosition()
local tr=reaper.GetTrack(0, 0)
-- 获取整体范围
reaper.Main_OnCommand(40290, 0)  --set ts
local left, right=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
reaper.Main_OnCommand(40020, 0)  --remove ts
-- 按ts范围建空item
local it=add_it(0, right-left, tr)
-- 以空item长度为距离整体往后移
reaper.SelectAllMediaItems(0, 0)
move(it, tr)
move(it, tr)
del_it(it, tr)

local region, marker={}, {}
for i=0, num-1 do
    local _, isr, pos, edge, name, idx, col=reaper.EnumProjectMarkers3(0, i)
    if isr then
        table.insert(region, {pos=pos, edge=edge, name=name, idx=idx, col=col})
    else
        table.insert(marker, {pos=pos, name=name, idx=idx, col=col})
    end
end

function by_name(t1, t2)
    return t1.name<t2.name
end
table.sort(region, by_name)

local start=0
for k, v in pairs(region) do
    local it=add_it(v.pos, v.edge-v.pos, tr)
    reaper.GetSet_LoopTimeRange(1, 1, v.pos, v.edge, 0)
    reaper.Main_OnCommand(40717, 0)  --select it in ts
    reaper.Main_OnCommand(40020, 0)  --remove ts
    reaper.SetEditCurPos(start, 0, 0)
    reaper.Main_OnCommand(41205, 0)  --move item position
    local edge=start+v.edge-v.pos
    reaper.SetProjectMarker3(0, v.idx, true, start, edge, v.name, v.col)
    reaper.SelectAllMediaItems(0, 0)
    del_it(it, tr)
    
    for k1, v1 in pairs(marker) do
        if v.pos-v1.pos<0.0001 and v1.pos-v.edge<0.0001 then
            reaper.SetProjectMarker3(0, v1.idx, false, start+v1.pos-v.pos, 0, v1.name, v1.col)
        elseif v.edge-v1.pos<-0.0001 then
            break
        end
    end

    reaper.SetEditCurPos(start+(v.edge-v.pos)*2, 0, 0)
    reaper.ApplyNudge(0, 2, 6, 18, 1, 0, 0)
    reaper.ApplyNudge(0, 2, 6, 18, 1, 1, 0)
    start=reaper.GetCursorPosition()

end

reaper.SetEditCurPos(cur, 0, 0)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('重排item', -1)