--[[
ReaScript Name: 移动item到光标
Version: 1.0
Author: noiZ
]]

function main()

	reaper.Undo_BeginBlock()

	reaper.PreventUIRefresh(1)

	local it=reaper.BR_ItemAtMouseCursor()

	if it then 

		reaper.Main_OnCommand(41299, 0)

		reaper.Undo_EndBlock("移动鼠标下item", -1)

	else

		local num=reaper.CountSelectedMediaItems(0)

		if num>0 then

			reaper.Main_OnCommand(41205, 0)	-- move item position to cursor

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

					reaper.Main_OnCommand(40117, 0)	--move up a track

				end

			end

			reaper.Undo_EndBlock("移动选中item", -1)

		end

	end

	reaper.PreventUIRefresh(-1)

end



main()
