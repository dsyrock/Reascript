function msg(value)
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local cur=reaper.GetCursorPosition()
local mouse=reaper.BR_PositionAtMouseCursor(0)
local m, r=reaper.GetLastMarkerAndCurRegion(0, mouse)
if r>=0 then
    local _, isr, left, right=reaper.EnumProjectMarkers(r)
    reaper.GetSet_LoopTimeRange(1, 1, left, right, 0)
else
    reaper.SelectAllMediaItems(0, 1)
    reaper.Main_OnCommand(40290, 0)  --set ts
end
local checkl, checkr=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
if checkr==0 then return end

reaper.SelectAllMediaItems(0, 0)
reaper.Main_OnCommand(41110, 0)  --select track at mouse
reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_SELPARENTS'), 0)  --select parent
reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_SELCHILDREN'), 0)  --select child
reaper.Main_OnCommand(40718, 0)  --select item in ts
reaper.Main_OnCommand(40020, 0)  --remove ts
reaper.SetEditCurPos(cur, 0, 0)

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)