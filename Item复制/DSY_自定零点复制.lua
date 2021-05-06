reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end

local cur=reaper.GetCursorPosition()

reaper.Main_OnCommand(40749, 0)  --link loop point
reaper.Main_OnCommand(40290, 0)  --set ts
local left=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
reaper.Main_OnCommand(40020, 0)  --remove ts

reaper.Main_OnCommand(40698, 0)  --copy items
reaper.SetExtState('copy_with_distance', 'distance', tostring(left-cur), false)

reaper.SetEditCurPos(cur, 0, 0)

reaper.PreventUIRefresh(-1)