--[[
ReaScript Name: 单独glue选中的每一个item
Version: 1.0
Author: noiZ
]]

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end

local its={}
for i=0, num-1 do
    local it=reaper.GetSelectedMediaItem(0, i)
    local tk=reaper.GetActiveTake(it)
    if tk and not reaper.TakeIsMIDI(tk) then
        table.insert(its, it)
    end
end
reaper.SelectAllMediaItems(0, 0)

local new={}
for k, v in pairs(its) do
    reaper.SetMediaItemSelected(v, 1)
    reaper.Main_OnCommand(40362, 0)
    table.insert(new, reaper.GetSelectedMediaItem(0, 0))
    reaper.SelectAllMediaItems(0, 0)
end

for k, v in pairs(new) do
    reaper.SetMediaItemSelected(v, 1)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('单独glue', -1)