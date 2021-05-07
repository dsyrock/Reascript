--[[
ReaScript Name: 复制item到光标
Version: 1.0
Author: noiZ
]]

function copy()
	local left, right=reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
	local cur=reaper.GetCursorPosition()
	reaper.Main_OnCommand(41295, 0)  --duplicate
	reaper.SetEditCurPos(cur, 0, 0)
	reaper.Main_OnCommand(41205, 0)  --move item to cursor
	reaper.GetSet_ArrangeView2(0, true, 0, 0, left, right)
end

function main()
	reaper.Undo_BeginBlock()
	reaper.PreventUIRefresh(1)
	local it=reaper.BR_ItemAtMouseCursor()
	local num=reaper.CountSelectedMediaItems(0)
	if it then 
		if num==0 then
			local is_sel=reaper.IsMediaItemSelected(it)
			reaper.Main_OnCommand(40528, 0)  --select item under mouse
			copy()
			if not is_sel then reaper.SetMediaItemSelected(reaper.GetSelectedMediaItem(0, 0), 0) end
		else
			local its={}
			for i=0, num-1 do
				table.insert(its, reaper.GetSelectedMediaItem(0, i))
			end
			reaper.SelectAllMediaItems(0, 0)
			reaper.Main_OnCommand(40528, 0)  --select item under mouse
			copy()
			reaper.SelectAllMediaItems(0, 0)
			for k, v in pairs(its) do
				reaper.SetMediaItemSelected(v, 1)
			end
		end
		reaper.Undo_EndBlock("复制鼠标下item", -1)
	else
		if num>0 then
			local pos=reaper.GetCursorPosition()
			reaper.Main_OnCommand(40290, 0)  -- time selection
			local edge=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
			reaper.Main_OnCommand(40020, 0)  -- remove time selection
			reaper.SetEditCurPos(pos, 1, 0)
			if edge~=pos then
				copy()
				reaper.Main_OnCommand(41110, 0)   -- select mouse track
				local tr_des=reaper.GetSelectedTrack(0, 0)
				local num_des=reaper.GetMediaTrackInfo_Value(tr_des, "IP_TRACKNUMBER")
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
			else
				reaper.Main_OnCommand(40698, 0)  -- copy
				reaper.Main_OnCommand(41110, 0)  -- select mouse track
				reaper.Main_OnCommand(40058, 0)  -- paste
			end
		end
		reaper.Undo_EndBlock("复制选中item", -1)
	end
	reaper.PreventUIRefresh(-1)
end
main()