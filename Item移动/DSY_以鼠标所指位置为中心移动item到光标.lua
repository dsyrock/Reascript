function move_item_point_to_point(pos_st, pos_des)

	local num=reaper.CountSelectedMediaItems(0)

	if num==0 then return end

	local cur=reaper.GetCursorPosition()

	local edge=reaper.GetProjectLength(0)

	for i=0, num-1 do

		local it=reaper.GetSelectedMediaItem(0, i)

		local pos=reaper.GetMediaItemInfo_Value(it, 'D_POSITION')

		local snap=reaper.GetMediaItemInfo_Value(it,"D_SNAPOFFSET")

		if pos+snap<edge then edge=pos+snap end

	end

	reaper.SetEditCurPos(pos_des-(pos_st-edge), 0, 0)

	reaper.Main_OnCommand(41205, 0)  --move to cursor

	reaper.SetEditCurPos(cur, 0, 0)
	
end

function mv_it_base_snap()

	local it=reaper.BR_ItemAtMouseCursor()

	if not it then return end

	local pos=reaper.GetCursorPosition()

	local mouse=reaper.BR_PositionAtMouseCursor(1)

	local snap=reaper.GetMediaItemInfo_Value(it,"D_SNAPOFFSET")

	reaper.PreventUIRefresh(1)

	if reaper.IsMediaItemSelected(it) then 

		move_item_point_to_point(mouse, pos)

	else

		local num=reaper.CountSelectedMediaItems(0)

		if num==0 then

			reaper.SetMediaItemSelected(it, 1)

			move_item_point_to_point(mouse, pos)

			reaper.SelectAllMediaItems(0, 0)

		else

			local its={}

			for i=1, num do

				its[i]=reaper.GetSelectedMediaItem(0, i-1)

			end

			reaper.SelectAllMediaItems(0, 0)

			reaper.SetMediaItemSelected(it, 1)

			move_item_point_to_point(mouse, pos)

			reaper.SelectAllMediaItems(0, 0)

			for k, v in pairs(its) do

				reaper.SetMediaItemSelected(v, 1)

			end

		end

	end

	reaper.UpdateArrange()

	reaper.PreventUIRefresh(-1)

end

reaper.Undo_BeginBlock()

mv_it_base_snap()

reaper.Undo_EndBlock("以鼠标为基准移动选中item", -1)