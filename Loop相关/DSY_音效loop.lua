local ratio=0.1

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end
local cur=reaper.GetCursorPosition()
local fade_set=reaper.GetToggleCommandState(41194)
reaper.Main_OnCommand(41193, 0)  --remove fade

local its={}
for i=0, num-1 do
    its[i+1]=reaper.GetSelectedMediaItem(0, i)
end
for k, v in pairs(its) do
    reaper.SelectAllMediaItems(0, 0)
    reaper.SetMediaItemSelected(v, 1)
    reaper.Main_OnCommand(41173, 0)  --set cursor to start
    reaper.Main_OnCommand(40791, 0)  --next zero
    reaper.Main_OnCommand(41305, 0)  --trim left
    reaper.Main_OnCommand(41174, 0)  --set cursor to end
    reaper.Main_OnCommand(40790, 0)  --previous zero
    reaper.Main_OnCommand(41311, 0)  --trim right
    local left=reaper.GetMediaItemInfo_Value(v, 'D_POSITION')
    local len1=reaper.GetMediaItemInfo_Value(v, 'D_LENGTH')
    reaper.SetEditCurPos(left+len1/2, 0, 0)
    reaper.Main_OnCommand(41995, 0) --Move edit cursor to nearest zero crossing in items
    local split=reaper.GetCursorPosition()
    if split>left and split<left+len1 then
        local it_new=reaper.SplitMediaItem(v, split)
        local len2=reaper.GetMediaItemInfo_Value(it_new, 'D_LENGTH')
        reaper.SetMediaItemPosition(it_new, left, 0)
        reaper.SetMediaItemPosition(v, left+len2-math.min(len1, len2)*ratio, 0)
        reaper.Main_OnCommand(41059, 0) --crossfade overlapping
    end
end

if fade_set==1 then
    reaper.Main_OnCommand(41195, 0) --Enable default fadein/fadeout
end
reaper.SelectAllMediaItems(0, 0)
reaper.SetEditCurPos(cur, 0, 0)

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('制作loop', -1)