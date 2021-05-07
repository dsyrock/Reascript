--[[
ReaScript Name: 移动到轨道
Version: 1.0
Author: noiZ
]]

---------------------------------设置区---------------------------------
local name=debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]]
local track_name=name:match('^.+_([^_]+)$')
local is_del=true
------------------------------------------------------------------------
function move_to_track(track_name, is_del)
	reaper.Undo_BeginBlock()
	reaper.PreventUIRefresh(1)
	local num=reaper.CountSelectedMediaItems(0)
	if num==0 then return end
	reaper.Main_OnCommand(40297, 0)  -- unselect all tracks
	for i=0, num-1 do
		local it=reaper.GetSelectedMediaItem(0, i)
		local tr=reaper.GetMediaItemTrack(it)
		reaper.SetTrackSelected(tr, 1)
	end
	local trs={}
	local num=reaper.CountSelectedTracks(0)
	for i=0, num-1 do
		local tr=reaper.GetSelectedTrack(0, i)
		table.insert(trs, tr)
	end
	local num=reaper.CountTracks(0)
	local track
	for i=0,num-1 do
		track=reaper.GetTrack(0,i)
		local _,name=reaper.GetTrackName(track,"" )
		if string.find(name,track_name)~=nil then
			reaper.SetOnlyTrackSelected(track)
			reaper.Main_OnCommand(40913,0)  --scroll to selected track
			break
		end
	end
	if track==nil then return end
	local num_des=reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
	local it=reaper.GetSelectedMediaItem(0, 0)
	local tr_ori=reaper.GetMediaItemTrack(it)
	local num_ori=reaper.GetMediaTrackInfo_Value(tr_ori, "IP_TRACKNUMBER")
	if num_des>num_ori then
		for i=1, num_des-num_ori do
			reaper.Main_OnCommand(40118, 0)  --move down a track
		end
	elseif num_des<num_ori then
		for i=1, num_ori-num_des do
			reaper.Main_OnCommand(40117, 0) --move up a track
		end
	end
    reaper.Main_OnCommand(40297, 0)  -- unselect all tracks
    if is_del then
        for k, v in pairs(trs) do
			local num=reaper.CountTrackMediaItems(v)
			local color=reaper.GetTrackColor(v)
            if num==0 and color==0 then reaper.SetTrackSelected(v, 1) end
        end
        if reaper.CountSelectedTracks(0)>0 then reaper.Main_OnCommand(40005, 0) end  --remove tracks
    end
	reaper.UpdateArrange()
	reaper.PreventUIRefresh(-1)
	reaper.Undo_EndBlock("",-1)
end
move_to_track(track_name, is_del)
