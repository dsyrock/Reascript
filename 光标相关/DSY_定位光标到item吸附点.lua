--[[
ReaScript Name: 定位光标到item吸附点
Version: 1.0
Author: noiZ
]]

local it=reaper.BR_ItemAtMouseCursor()

if not it then return end

local pos=reaper.GetMediaItemInfo_Value(it, 'D_POSITION')

local snap=reaper.GetMediaItemInfo_Value(it, 'D_SNAPOFFSET')

reaper.SetEditCurPos(pos+snap, 0, 0)