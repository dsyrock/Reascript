function search_in_region()
	reaper.PreventUIRefresh(1)
	local num=reaper.CountSelectedMediaItems(0)
	if num==0 then return end
	local it=reaper.GetSelectedMediaItem(0, 0)
	local pos=reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
	local mk, rg=reaper.GetLastMarkerAndCurRegion(0, pos)
	if rg<0 then return end
	local name, count=save_names(num)
	if count>0 then
		local _, isrg, left, right=reaper.EnumProjectMarkers(rg)
		reaper.GetSet_LoopTimeRange(true, true, left, right, false)
		reaper.Main_OnCommand(40717, 0)  --select items in time selection
		reaper.Main_OnCommand(40020, 0)  --remove time selection
		local num=reaper.CountSelectedMediaItems(0)
		local its={}
		for i=0,num-1 do
		local item=reaper.GetSelectedMediaItem(0,i)
		local take=reaper.GetActiveTake(item)
			if take then
				local tk_name=reaper.GetTakeName(take)
				if name[tk_name] then table.insert(its, item) end
			end
		end
		if #its>0 then
			reaper.SelectAllMediaItems(0, 0)
			for k, v in pairs(its) do
				reaper.SetMediaItemSelected(v, 1)
			end
		end
	end
	reaper.UpdateArrange()
	reaper.PreventUIRefresh(-1)
end
search_in_region()