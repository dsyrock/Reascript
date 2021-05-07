reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end

local it0=reaper.GetSelectedMediaItem(0, 0)
local tr=reaper.GetMediaItemTrack(it0)
local pos=reaper.GetMediaItemInfo_Value(it0, 'D_POSITION')
local edge=reaper.GetMediaItemInfo_Value(it0, 'D_LENGTH')+pos

for i=1, num-1 do
    local it=reaper.GetSelectedMediaItem(0, i)
    local len=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
    reaper.MoveMediaItemToTrack(it, tr)
    reaper.SetMediaItemPosition(it, edge, 0)
    edge=edge+reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('横排垂直item', -1)