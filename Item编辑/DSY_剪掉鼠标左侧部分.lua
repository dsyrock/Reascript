--[[
ReaScript Name: 剪掉鼠标左侧部分
Version: 1.0
Author: noiZ
]]

function main()

	reaper.PreventUIRefresh(1)

	local it=reaper.BR_ItemAtMouseCursor()

	local its={}

	local num=reaper.CountSelectedMediaItems(0)

	local cur=reaper.GetCursorPosition()

	if it then 

		if num>0 then

			for i=1, num do

				its[i]=reaper.GetSelectedMediaItem(0, i-1)

			end

			reaper.SelectAllMediaItems(0, 0)

		end

		reaper.SetMediaItemSelected(it, 1)

		reaper.Main_OnCommand(40513, 0)  -- move edit cursor to mouse

		reaper.Main_OnCommand(41305, 0)  -- trim left edge

		local shape=reaper.GetMediaItemInfo_Value(it, "C_FADEINSHAPE")
		if shape==7 then
			reaper.SetMediaItemInfo_Value(it, "D_FADEINLEN_AUTO", 0)
			reaper.SetMediaItemInfo_Value(it, "D_FADEINLEN", 0)
			reaper.SetMediaItemInfo_Value(it, "C_FADEINSHAPE", 0)
		end

		reaper.SetMediaItemSelected(it, 0)

		for i=1, num do

			reaper.SetMediaItemSelected(its[i], 1)

		end

	else 

		if num>0 then

			reaper.Main_OnCommand(40513, 0)  -- move edit cursor to mouse

			reaper.Main_OnCommand(41305, 0)  -- trim left edge

			for i=0, num-1 do
				local it=reaper.GetSelectedMediaItem(0, i)
				local shape=reaper.GetMediaItemInfo_Value(it, "C_FADEINSHAPE")
				if shape==7 then
					reaper.SetMediaItemInfo_Value(it, "D_FADEINLEN_AUTO", 0)
					reaper.SetMediaItemInfo_Value(it, "D_FADEINLEN", 0)
					reaper.SetMediaItemInfo_Value(it, "C_FADEINSHAPE", 0)
				end
			end

		end

	end

	reaper.SetEditCurPos(cur, 0, 0)

	reaper.PreventUIRefresh(-1)

	reaper.UpdateArrange()

end

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("剪掉鼠标左侧部分", -1)