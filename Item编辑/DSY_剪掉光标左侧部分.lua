--[[
ReaScript Name: 剪掉光标左侧部分
Version: 1.0
Author: noiZ
]]

function main()

	reaper.PreventUIRefresh(1)

	local it=reaper.BR_ItemAtMouseCursor()

	local its={}

	local num=reaper.CountSelectedMediaItems(0)

	if it then 

		if num>0 then

			for i=1, num do

				its[i]=reaper.GetSelectedMediaItem(0, i-1)

			end

			reaper.SelectAllMediaItems(0, 0)

		end

		reaper.SetMediaItemSelected(it, 1)

		reaper.Main_OnCommand(41305, 0)  -- trim left edge

		reaper.SetMediaItemSelected(it, 0)

		for i=1, num do

			reaper.SetMediaItemSelected(its[i], 1)

		end

	else 

		if num>0 then

			reaper.Main_OnCommand(41305, 0)  -- trim left edge

		end

	end

	reaper.PreventUIRefresh(-1)

	reaper.UpdateArrange()

end

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("", -1)