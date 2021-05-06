function main()

	reaper.PreventUIRefresh(1)

	reaper.Main_OnCommand(40297, 1)

	local num=reaper.CountSelectedMediaItems(0)

	if num==0 then 

		reaper.Main_OnCommand(41110, 0)  -- select mouse track

	else

		for i=0, num-1 do

			local it=reaper.GetSelectedMediaItem(0, i)

			local tr=reaper.GetMediaItem_Track(it)

			reaper.SetTrackSelected(tr, 1)

		end

	end

	reaper.Main_OnCommand(7, 1)

	reaper.PreventUIRefresh(-1)

end

main()