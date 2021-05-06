function main()

	local num=reaper.CountSelectedMediaItems(0)

	if num==0 then return end

	local it=reaper.BR_ItemAtMouseCursor()

	if not it then return end

	reaper.SetMediaItemSelected(it, 0)

	reaper.Main_OnCommand(40006, 0)  -- remove items

	reaper.SetMediaItemSelected(it, 1)

	reaper.UpdateArrange()

end

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("", -1)