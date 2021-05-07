--[[
ReaScript Name: 定位到鼠标右侧素材
Version: 1.0
Author: noiZ
]]

reaper.PreventUIRefresh(1)

local mouse=reaper.BR_PositionAtMouseCursor(true)

reaper.Main_OnCommand(41110, 0)  --select track under mouse

local tr=reaper.GetSelectedTrack(0, 0)

if not tr then return end

local its={}

local num=reaper.CountSelectedMediaItems(0)

if num>0 then

    for i=0, num-1 do

        table.insert(its,reaper.GetSelectedMediaItem(0, i))

    end

end

local right=reaper.GetProjectLength(0)

reaper.GetSet_LoopTimeRange(true, true, mouse, right, false)

reaper.Main_OnCommand(40718, 0)  --select item in time selection

local it=reaper.GetSelectedMediaItem(0, 0)

reaper.Main_OnCommand(40020, 0)  --remove time selection

if not it then return end

reaper.SelectAllMediaItems(0, 0)

local pos=reaper.GetMediaItemInfo_Value(it, 'D_POSITION')

reaper.SetEditCurPos(pos, 0, 0)

if #its>0 then

    for k, v in pairs(its) do
    
        reaper.SetMediaItemSelected(v, 1)

    end

end

reaper.PreventUIRefresh(-1)