function items_dup(rev)
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
	if reaper.CountSelectedMediaItems(0)<2 then return end
	local itema=reaper.GetSelectedMediaItem(0,0)
	local posa=reaper.GetMediaItemInfo_Value(itema,"D_POSITION")+reaper.GetMediaItemInfo_Value(itema, 'D_SNAPOFFSET')
	local itemb=reaper.GetSelectedMediaItem(0,1)
	local posb=reaper.GetMediaItemInfo_Value(itemb,"D_POSITION")+reaper.GetMediaItemInfo_Value(itemb, 'D_SNAPOFFSET')
    local posl=math.min(posa, posb)
    local posr=math.max(posa, posb)
	local distance=(posr-posl)*2
    local pos=posr+distance
    reaper.ApplyNudge(0, 0, 5, 1, distance, rev, 1)
    reaper.Main_OnCommand(40290, 0)  -- set ts
    reaper.Main_OnCommand(40020, 0)  --remove ts
    reaper.PreventUIRefresh(-1)
	reaper.Undo_EndBlock("等距离复制item_右", -1)
end
items_dup()