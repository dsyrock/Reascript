function main()

	reaper.Undo_BeginBlock()

	local it=reaper.BR_ItemAtMouseCursor()

	if it then
		if reaper.GetMediaItemInfo_Value(it, 'C_LOCK')==1 then return end
		local tr=reaper.GetMediaItem_Track(it)

		reaper.DeleteTrackMediaItem(tr, it)

		reaper.Undo_EndBlock("删除鼠标下item", -1)

	else

		reaper.Main_OnCommand(40006, 0)  -- remove items

		reaper.Undo_EndBlock("删除item", -1)

	end

	reaper.UpdateArrange()

end

main()
