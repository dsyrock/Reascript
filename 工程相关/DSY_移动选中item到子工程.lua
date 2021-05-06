function msg(value)
    reaper.ShowConsoleMsg(tostring(value) .. '\n')
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local numIt=reaper.CountSelectedMediaItems(0)
if numIt==0 then return end

local cur=reaper.GetCursorPosition()
reaper.Main_OnCommand(40290, 0)  --set ts
local left, right=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
reaper.Main_OnCommand(40020, 0)  -- remove loop point and time selection
reaper.SetEditCurPos(cur, 0, 0)

local tr=reaper.GetTrack(0, 0)
local _, nameOri=reaper.GetTrackName(tr, '')
reaper.GetSetMediaTrackInfo_String(tr, 'P_NAME', '', true)

local proj = reaper.EnumProjects(-1, '')
local num=0
while true do
    local check=reaper.EnumProjects(num, '')
    if check then
        num=num+1
    else
        break
    end
end

reaper.Main_OnCommand(40296, 0)  --select all tracks
reaper.Main_OnCommand(41997, 0)  --move tracks to sub
reaper.Main_OnCommand(40698, 0)  --copy
reaper.Main_OnCommand(40029, 0)  --undo
reaper.Main_OnCommand(40006, 0)  --remove item
reaper.SetEditCurPos(left, 0, 0)
reaper.Main_OnCommand(42398, 0)  --paste
reaper.SetMediaItemLength(reaper.GetSelectedMediaItem(0, 0), right-left, 0)
reaper.GetSetMediaTrackInfo_String(tr, 'P_NAME', nameOri, true)

local sub=reaper.EnumProjects(num, '')
reaper.SelectProjectInstance(sub)
if left~=0 then
    reaper.GetSet_LoopTimeRange(true, true, 0, left, 0)
    reaper.Main_OnCommand(40201, 0)  --remove time
end
local pjEdge=reaper.GetProjectLength(0)
if right~=pjEdge then
    reaper.GetSet_LoopTimeRange(true, true, right, pjEdge, 0)
    reaper.Main_OnCommand(40201, 0)  --remove time
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)