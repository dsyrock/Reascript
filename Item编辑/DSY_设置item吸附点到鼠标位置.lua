--[[
ReaScript Name: 设置item吸附点到鼠标位置
Version: 1.0
Author: noiZ
]]

item=reaper.BR_ItemAtMouseCursor()

if item==nil then return end

left=reaper.GetMediaItemInfo_Value(item,"D_POSITION")

pos=reaper.GetCursorPosition()

if pos<=left then return end

reaper.SetMediaItemInfo_Value(item,"D_SNAPOFFSET",pos-left)

reaper.UpdateArrange()
