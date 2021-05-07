--[[
ReaScript Name: 音乐loop
Version: 1.0
Author: noiZ
]]

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num~=2 then return end

local it1=reaper.GetSelectedMediaItem(0, 0)
local it2=reaper.GetSelectedMediaItem(0, 1)
local tk1=reaper.GetActiveTake(it1)
local tk2=reaper.GetActiveTake(it2)

local pos1=reaper.GetMediaItemInfo_Value(it1, 'D_POSITION')
local len1=reaper.GetMediaItemInfo_Value(it1, 'D_LENGTH')
local edge=pos1+len1
local offset1=reaper.GetMediaItemTakeInfo_Value(tk1, 'D_STARTOFFS')
local fadeout=reaper.GetMediaItemInfo_Value(it1, 'D_FADEOUTLEN')
local fadeouta=reaper.GetMediaItemInfo_Value(it1, 'D_FADEOUTLEN_AUTO')
local dirout=reaper.GetMediaItemInfo_Value(it1, 'D_FADEOUTDIR')
local shapeout=reaper.GetMediaItemInfo_Value(it1, 'C_FADEOUTSHAPE')
local offset2=reaper.GetMediaItemTakeInfo_Value(tk2, 'D_STARTOFFS')
local pos2=reaper.GetMediaItemInfo_Value(it2, 'D_POSITION')
local snap2=reaper.GetMediaItemInfo_Value(it2, 'D_SNAPOFFSET')
reaper.SetMediaItemLength(it2, offset1+len1-offset2, 0)
reaper.SetMediaItemInfo_Value(it2, 'D_FADEOUTLEN', fadeout)
reaper.SetMediaItemInfo_Value(it2, 'D_FADEOUTLEN_AUTO', fadeouta)
reaper.SetMediaItemInfo_Value(it2, 'D_FADEOUTDIR', dirout)
reaper.SetMediaItemInfo_Value(it2, 'C_FADEOUTSHAPE', shapeout)

reaper.SetMediaItemSelected(it1, 0)
reaper.Main_OnCommand(41295, 0)  --duplicate
local it3=reaper.GetSelectedMediaItem(0, 0)
reaper.Main_OnCommand(40117, 0)  --move up a track
local d=edge-pos2-snap2
reaper.SetEditCurPos(pos2+offset1+len1-offset2-d, 0, 0)
reaper.Main_OnCommand(41205, 0)  --move item to cursor
reaper.SetMediaItemSelected(it2, 1)

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('音乐loop', -1)