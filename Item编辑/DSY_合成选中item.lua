--[[
ReaScript Name: 合成选中item
Version: 2.0
Author: noiZ
]]

function mix_items()
    local num=reaper.CountSelectedMediaItems(0)
	if num==0 then return end
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    local rate=reaper.Master_GetPlayRate(0)
    reaper.CSurf_OnPlayRateChange(1)
    reaper.Main_OnCommand(40297, 0)  --  unselect all tracks
    local item=reaper.GetSelectedMediaItem(0, 0)
    local track=reaper.GetMediaItem_Track(item)
    reaper.SetOnlyTrackSelected(track)
    reaper.Main_OnCommand(40751, 0)  -- free position on
    reaper.Main_OnCommand(40644, 0)  --move to one track
	local cur=reaper.GetCursorPosition()
	reaper.Main_OnCommand(40290, 0)  --set ts
	local retval, value = reaper.GetSetProjectInfo_String(0, 'RENDER_STATS', '42439', 0)
	reaper.Main_OnCommand(40020, 0)  -- remove ts
	local peak=tonumber(value:match('PEAK:([^;]+)'))
	local volFix=1
	if peak>0 then
		volFix=10^(-peak/20)
		for i=0, num-1 do
			local it=reaper.GetSelectedMediaItem(0, i)
			local volOri=reaper.GetMediaItemInfo_Value(it, 'D_VOL')
			reaper.SetMediaItemInfo_Value(it, 'D_VOL', volOri*volFix)
		end
	end
    reaper.Main_OnCommand(40257, 0)  -- glue items
    reaper.Main_OnCommand(40752, 0)  -- free position off
    local new_item=reaper.GetSelectedMediaItem(0, 0)
    local new_vol=reaper.GetMediaItemInfo_Value(new_item, 'D_VOL')
    reaper.SetMediaItemInfo_Value(new_item, "D_VOL", new_vol/volFix)
    reaper.SetEditCurPos(cur, 0, 0)
	reaper.Main_OnCommand(40541, 0)  --set snap to cursor
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("原地合成item",-1)
    reaper.UpdateArrange()
end
mix_items()