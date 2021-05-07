--[[
ReaScript Name: 取消选择 鼠标以下
Version: 1.0
Author: noiZ
]]

reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)

if num==0 then return end

local tr=reaper.BR_TrackAtMouseCursor()

if not tr then return end

local tr_num=reaper.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER')

local num=reaper.CountTracks(0)

reaper.Main_OnCommand(40297, 0)  --unselect all tracks

for i=tr_num, num-1 do

    local tr=reaper.GetTrack(0, i)

    reaper.SetTrackSelected(tr, 1)

end

reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_UNSELONTRACKS'), 0)  --unselect items on selected tracks

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)