reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
local cur=reaper.GetCursorPosition()

if not reaper.HasExtState('copy_with_distance', 'distance') then
    reaper.Main_OnCommand(41110, 0)  --sel track
    reaper.Main_OnCommand(42398, 0)  --paste
else
    local distance=reaper.GetExtState('copy_with_distance', 'distance')
    local pos=cur+tonumber(distance)
    reaper.SetEditCurPos(pos, 0, 0)
    reaper.Main_OnCommand(41110, 0)  --select track at mouse
    reaper.Main_OnCommand(42398, 0)  --paste
    reaper.Main_OnCommand(41205, 0)  --move item position

    reaper.Main_OnCommand(40749, 0)  --link loop point
    reaper.Main_OnCommand(40290, 0)  --set ts
    local left=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
    reaper.Main_OnCommand(40020, 0)  --remove ts

    if pos-left>0.0001 then
        reaper.SetEditCurPos(pos+pos-left, 0, 0)
        reaper.Main_OnCommand(41205, 0)  --move item position
    end
end
reaper.SetEditCurPos(cur, 0, 0)
reaper.DeleteExtState('copy_with_distance', 'distance', true)
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('自定零点粘贴', -1)