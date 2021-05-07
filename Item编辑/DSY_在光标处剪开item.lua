--[[
ReaScript Name: 在光标处剪开item
Version: 1.0
Author: noiZ
]]

function main()

	reaper.PreventUIRefresh(1)

	local it=reaper.BR_ItemAtMouseCursor()

	if it then

		local cur=reaper.GetCursorPosition()

		local it_new=reaper.SplitMediaItem(it, cur)

		reaper.SetMediaItemSelected(it, 0)

		if it_new then reaper.SetMediaItemSelected(it_new, 0) end

	else 

		reaper.Main_OnCommand(40759, 0)  -- split at edit cursor

	end

	reaper.PreventUIRefresh(-1)

	reaper.UpdateArrange()

end

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("", -1)