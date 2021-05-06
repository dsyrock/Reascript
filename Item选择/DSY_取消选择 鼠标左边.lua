reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end

local mouse=reaper.BR_PositionAtMouseCursor(true)
local cur=reaper.GetCursorPosition()

reaper.Main_OnCommand(40749, 0)  --link ts
reaper.Main_OnCommand(40290, 0)  --set time selection
local left, right=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
reaper.Main_OnCommand(40020, 0)  --remove ts
reaper.GetSet_LoopTimeRange(1, 1, mouse, right, 0)
reaper.Main_OnCommand(reaper.NamedCommandLookup('_FNG_TIME_SEL_NOT_START'), 0)  --unselect items off screen
reaper.Main_OnCommand(40020, 0)  --remove ts
reaper.SetEditCurPos(cur, 1, 1)

reaper.UpdateArrange()
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)