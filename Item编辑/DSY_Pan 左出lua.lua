function pan_take(pana,panz)
	reaper.Undo_BeginBlock()
	local num=reaper.CountSelectedMediaItems(0)
	if num<=2 then return end
	local its={}
	for i=1, num do
		its[i]={}
		its[i].it=reaper.GetSelectedMediaItem(0, i-1)
		its[i].pos=reaper.GetMediaItemInfo_Value(its[i].it, "D_POSITION")
	end
	table.sort(its,by_pos)
	local tka=reaper.GetActiveTake(its[1].it)
	local tkz=reaper.GetActiveTake(its[num].it)
	reaper.SetMediaItemTakeInfo_Value(tka, "D_PAN", pana)
	reaper.SetMediaItemTakeInfo_Value(tkz, "D_PAN", panz)
	local d=(panz-pana)/(num-1)
	for i=2, num-1 do
		local tk=reaper.GetActiveTake(its[i].it)
		reaper.SetMediaItemTakeInfo_Value(tk, "D_PAN", pana+(i-1)*d)
	end
  	reaper.UpdateArrange()
  	reaper.Undo_EndBlock("线性调整pan 左出", -1)
end
pan_take(0,-0.7)