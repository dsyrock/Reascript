reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)

local item=reaper.BR_ItemAtMouseCursor()

local tsl, tsr=reaper.GetSet_LoopTimeRange(false, true, 0, 0, 0)

if item then

    local tr_ori=reaper.GetSelectedTrack(0, 0)

	reaper.SelectAllMediaItems(0, 0)

	reaper.SetMediaItemSelected(item, 1)

	local left=reaper.GetMediaItemInfo_Value(item,"D_POSITION")

	local right=left+reaper.GetMediaItemInfo_Value(item,"D_LENGTH")

	local tr=reaper.GetMediaItemTrack(item)

	local idx=reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")

    reaper.GetSet_LoopTimeRange(true, true, left, right, false)

    reaper.Main_OnCommand(40296, 0)  --select all tracks

	for i=0, idx-1 do

        local tr=reaper.GetTrack(0, i)

        reaper.SetTrackSelected(tr, 0)

    end --for i=0,numall-1 do
    
    reaper.Main_OnCommand(40718, 0)  -- select items on selected tracks in time selection

    reaper.Main_OnCommand(reaper.NamedCommandLookup("_FNG_TIME_SEL_NOT_START"), 0)  -- unselect items not start in time selection

    local index=0

    while true do

        local it=reaper.GetSelectedMediaItem(0, index)

        if it then

            local edge_l=reaper.GetMediaItemInfo_Value(it, "D_POSITION")

            local edge_r=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")+edge_l
            local lock=reaper.GetMediaItemInfo_Value(it, 'C_LOCK')

            if edge_r-right>0.0001 or lock==1 then 

                reaper.SetMediaItemSelected(it, 0)

            else

                index=index+1

            end

        else

            break

        end

    end

    reaper.Main_OnCommand(40020, 0)  -- remove time selection

    if tr_ori then reaper.SetOnlyTrackSelected(tr_ori) end

elseif tsl~=tsr then

    reaper.Main_OnCommand(40717, 0)  --select item in time selection

    reaper.Main_OnCommand(40034, 0)  --select item in group

    reaper.Main_OnCommand(40020, 0)  -- remove time selection

else

	local cur=reaper.BR_PositionAtMouseCursor(true)

	local m, r=reaper.GetLastMarkerAndCurRegion(0, cur)

    if r==-1 then return end
    
    local num=reaper.CountSelectedMediaItems(0)

    local its={}

    if num>0 then

        for i=0, num-1 do

            table.insert(its, reaper.GetSelectedMediaItem(0, i))

        end

    end

    local tr_ori=reaper.GetSelectedTrack(0, 0)

	local _, is, left, right=reaper.EnumProjectMarkers(r)

    reaper.GetSet_LoopTimeRange(true, true, left, right, false)
    
    reaper.Main_OnCommand(40717, 0)  --select all items in time selection

    reaper.Main_OnCommand(40020, 0)  -- remove time selection

    reaper.Main_OnCommand(40034, 0)  --select item in group

    if tr_ori then reaper.SetOnlyTrackSelected(tr_ori) end

    if #its>0 then

        for k, v in pairs(its) do

            reaper.SetMediaItemSelected(v, 1)

        end

    end

end

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("",-1)
