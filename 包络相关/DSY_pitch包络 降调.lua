function env(name,pointA,pointZ)
	reaper.Undo_BeginBlock()
	reaper.PreventUIRefresh(1)
    local num=reaper.CountSelectedMediaItems(0)
    if num==0 then return end
    local r_left,r_right = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false) -- get time selection both edges
    for i=0, num-1 do
		local it=reaper.GetSelectedMediaItem(0, i)
		local pos=reaper.GetMediaItemInfo_Value(it,"D_POSITION")
		local length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
		local tk=reaper.GetActiveTake(it)
		local rate=reaper.GetMediaItemTakeInfo_Value(tk, "D_PLAYRATE")
		local left,right
		if r_left<=pos or r_left==r_right then
			left=0 
		else 
			left=r_left-pos
		end
		if r_right>=pos+length or r_left==r_right then
			right=length
		else
			right=r_right-pos
		end
		if name=="Pan" then
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV2"),0) -- display the take volume of item
		elseif name=="Pitch" then
			reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV10"),0) -- display the take volume of item
		end                
		local env=reaper.GetTakeEnvelopeByName(tk,name)
        --insert 4 points of envelope
		reaper.InsertEnvelopePoint(env,left*rate,pointA,0,0,false,false)
		reaper.InsertEnvelopePoint(env,right*rate,pointZ,0,0,false,false)
	end
	reaper.UpdateArrange()
	reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("包络线效果",-1)
end
env("Pitch",0,-12)