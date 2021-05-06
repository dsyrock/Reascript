function mix_items()
    if reaper.CountSelectedMediaItems(0)==0 then return end
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    local rate=reaper.Master_GetPlayRate(0)
    reaper.CSurf_OnPlayRateChange(1)
    reaper.Main_OnCommand(40297, 0)  --  unselect all tracks
    local item=reaper.GetSelectedMediaItem(0, 0)
    local vol=reaper.GetMediaItemInfo_Value(item, "D_VOL")
    local db=math.log(vol,10)*20-10
    local new_vol=10^((db)/20)
    reaper.SetMediaItemInfo_Value(item, "D_VOL", new_vol)
    local track=reaper.GetMediaItem_Track(item)
    reaper.SetOnlyTrackSelected(track)
    reaper.Main_OnCommand(40751, 0)  -- free position on
    for i=1, reaper.CountSelectedMediaItems(0)-1 do
        local item=reaper.GetSelectedMediaItem(0, i)
        local vol=reaper.GetMediaItemInfo_Value(item, "D_VOL")
        local db=math.log(vol,10)*20-10
        local new_vol=10^((db)/20)
        reaper.SetMediaItemInfo_Value(item, "D_VOL", new_vol)
        reaper.MoveMediaItemToTrack(item, track)
    end
    reaper.Main_OnCommand(40257, 0)  -- glue items
    reaper.Main_OnCommand(40752, 0)  -- free position off
    local new_item=reaper.GetSelectedMediaItem(0, 0)
    local new_db=math.log(1, 10)*20+10
    local new_vol=10^((new_db)/20)
    reaper.SetMediaItemInfo_Value(new_item, "D_VOL", new_vol)
    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("原地合成item",-1)
    reaper.UpdateArrange()
end
mix_items()