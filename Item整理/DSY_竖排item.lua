reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end

local it0=reaper.GetSelectedMediaItem(0, 0)
local start=reaper.GetMediaItemInfo_Value(it0, 'D_POSITION')
local cur=reaper.GetCursorPosition()
reaper.SetEditCurPos(start, 0, 0)

for i=1, num-1 do
    local it=reaper.GetSelectedMediaItem(0, 0)
    reaper.SetMediaItemSelected(it, 0)
    reaper.Main_OnCommand(40118, 0)  --move down a track
    reaper.Main_OnCommand(41205, 0)  --move item to cursor
end
reaper.SetEditCurPos(cur, 0, 0)

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)