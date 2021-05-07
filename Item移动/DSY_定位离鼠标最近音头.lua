--[[
ReaScript Name: 定位离鼠标最近音头
Version: 1.0
Author: noiZ
]]

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local it=reaper.BR_ItemAtMouseCursor()
if not it then return end

reaper.SelectAllMediaItems(0, 0)
reaper.SetMediaItemSelected(it, 1)
local cur=reaper.GetCursorPosition()
reaper.SetEditCurPos(reaper.BR_PositionAtMouseCursor(true), 0, 0)
reaper.Main_OnCommand(40375, 0)  --move to transient
reaper.Main_OnCommand(40541, 0)  --set snap to cursor
reaper.SetEditCurPos(cur, 0, 0)
reaper.Main_OnCommand(41205, 0)  --move to cursor

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)