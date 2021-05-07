--[[
ReaScript Name: 定位光标到鼠标所指item或region起点
Version: 1.0
Author: noiZ
]]

function main()

	reaper.PreventUIRefresh(1)

	local it=reaper.BR_ItemAtMouseCursor()

	if it==nil then  

		--local pos=reaper.GetCursorPosition()
		local pos=reaper.BR_PositionAtMouseCursor(true)

		_,idx=reaper.GetLastMarkerAndCurRegion(0, pos)

		if idx~=nil then

			local _, _2, left, right=reaper.EnumProjectMarkers(idx)

			reaper.SetEditCurPos(right, 1, 0)

		end

	else

		local pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")

		local right=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")+pos

		reaper.SetEditCurPos(right, 1, 0)

	end

	reaper.PreventUIRefresh(-1)

end

main()