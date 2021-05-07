--[[
ReaScript Name: 淡入到鼠标
Version: 1.0
Author: noiZ
]]

function set_fadein(it)

    local mouse=reaper.BR_PositionAtMouseCursor(true)

    local pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")
    
    local length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
    
    if mouse>=pos+length then return end
    
    reaper.SetMediaItemInfo_Value(it, "D_FADEINLEN_AUTO", 0)
    
    reaper.SetMediaItemInfo_Value(it, "D_FADEINLEN", mouse-pos)
    
end

reaper.Undo_BeginBlock()

local it=reaper.BR_ItemAtMouseCursor()

if it then

	set_fadein(it)

else

	local num=reaper.CountSelectedMediaItems(0)

	if num>0 then

		for i=0, num-1 do

			local it=reaper.GetSelectedMediaItem(0, i)

			set_fadein(it)

		end

	end

end

reaper.UpdateArrange()

reaper.Undo_EndBlock('淡入到鼠标', -1)