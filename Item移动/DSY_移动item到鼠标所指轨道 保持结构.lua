local itemnum=reaper.CountSelectedMediaItems(0)

if itemnum==0 then return end

local track=reaper.BR_TrackAtMouseCursor()

if not track then return end

local idx_to=reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
		
reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)

local it0=reaper.GetSelectedMediaItem(0, 0)

local tr0=reaper.GetMediaItemTrack(it0)

local idx_from=reaper.GetMediaTrackInfo_Value(tr0, 'IP_TRACKNUMBER')

local dir, step

if idx_to>idx_from then

	dir, step=1, 1

elseif idx_to<idx_from then

	dir, step=0, -1

else

	return

end

for i=idx_from, idx_to-step, step do

	if dir==1 then
		
		reaper.Main_OnCommand(40118, 0)  -- move items down

	else

		reaper.Main_OnCommand(40117, 0)  -- move items up
	
	end

end

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("移动item到轨道", -1)