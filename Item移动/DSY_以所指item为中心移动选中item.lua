--[[
ReaScript Name: 以所指item为中心移动选中item
Version: 1.0
Author: noiZ
]]

function move_item_point_to_point(pos_st, pos_des)

	local num=reaper.CountSelectedMediaItems(0)

	if num==0 then return end

	local cur=reaper.GetCursorPosition()

	local right=reaper.GetProjectLength(0)

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

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)

local baseitem=reaper.BR_ItemAtMouseCursor()

if not baseitem then

  	reaper.Main_OnCommand(41205,0)  -- move items to edit cursor

  	reaper.Undo_EndBlock("移动选中item",-1)

elseif not reaper.IsMediaItemSelected(baseitem) then 

    reaper.Main_OnCommand(41205,0)  -- move items to edit cursor

    reaper.Undo_EndBlock("移动选中item",-1)

elseif reaper.IsMediaItemSelected(baseitem)==true then 

  	local basepos=reaper.GetMediaItemInfo_Value(baseitem,"D_POSITION")

  	local snap=reaper.GetMediaItemInfo_Value(baseitem,"D_SNAPOFFSET")+basepos

	local cursor=reaper.GetCursorPosition()
	  
	move_item_point_to_point(snap, cursor)

  	reaper.Undo_EndBlock("以鼠标所指item为基准移动选中item",-1)

end

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)


