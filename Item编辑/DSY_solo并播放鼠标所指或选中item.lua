function main()

	reaper.PreventUIRefresh(1)

	local it=reaper.BR_ItemAtMouseCursor()

	if it then

		local isselect=reaper.IsMediaItemSelected(it)

		local num=reaper.CountSelectedMediaItems(0)

		local its={}

		if num>0 then

			for i=1, num do

				its[i]=reaper.GetSelectedMediaItem(0, i-1)

			end

			reaper.SelectAllMediaItems(0, 0)

		end

		reaper.SetMediaItemSelected(it, 1)

		reaper.Main_OnCommand(40340, 0)  -- unsolo all tracks

		reaper.Main_OnCommand(41110, 0)  --select track under mouse

		reaper.Main_OnCommand(40728, 0)  --solo

		reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_TIMERTEST1"), 0)

		if not isselect then reaper.SetMediaItemSelected(it, 0) end

		if num>0 then

			for i=1, num do

				reaper.SetMediaItemSelected(its[i], 1)

			end

		end

	else

		local num=reaper.CountSelectedMediaItems(0)

		if num==0 then return end

		local its, edr, edl={}, 0, reaper.GetProjectLength(0)

		for i=0, num-1 do

			local it=reaper.GetSelectedMediaItem(0, i)

			table.insert(its, it)

		end

		local it_last=reaper.GetSelectedMediaItem(0, num-1)

		reaper.SetOnlyTrackSelected(reaper.GetMediaItemTrack(it_last))

		reaper.Main_OnCommand(40285, 0)  --next track

		local tr=reaper.GetSelectedTrack(0, 0)

		reaper.Main_OnCommand(40290, 0)  --set ts

		reaper.Main_OnCommand(40142, 0)  --insert empty item

		local left=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)

		reaper.Main_OnCommand(40020, 0)

		reaper.SetEditCurPos(left, 0, 0)

		local it_e=reaper.GetSelectedMediaItem(0, 0)

		reaper.Main_OnCommand(reaper.NamedCommandLookup('_XENAKIOS_TIMERTEST1'), 0)  --play select item once

		reaper.Main_OnCommand(40006, 0)  --remove item

		reaper.Main_OnCommand(40297, 0)  --unselct all tracks
		
		for k, v in pairs(its) do

			reaper.SetMediaItemSelected(v, 1)

			reaper.SetTrackSelected(reaper.GetMediaItemTrack(v), 1)

		end

		reaper.Main_OnCommand(40728, 0)  --solo tracks

	end

	reaper.UpdateArrange()

	reaper.PreventUIRefresh(-1)

end

reaper.defer(main)
