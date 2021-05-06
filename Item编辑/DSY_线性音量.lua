function linear_volume()
    local num=reaper.CountSelectedMediaItems(0)
    if num==0 then return end
    local item={}
    for i=1,num do
		item[i]={}
		item[i].it=reaper.GetSelectedMediaItem(0,i-1)
		item[i].pos=reaper.GetMediaItemInfo_Value(item[i].it,"D_POSITION")  
    end
    --Resort items by their positions
    table.sort(item,by_pos)

    --iecrese volume linearly
    local log10 = function(x) return math.log(x, 10) end
    local first = item[1].it
    local last = item[num].it
    local a1 = 20*log10(reaper.GetMediaItemInfo_Value(first, 'D_VOL'))
    local az = 20*log10(reaper.GetMediaItemInfo_Value(last, 'D_VOL'))
    local d = (az - a1)/(num-1)
      
    reaper.Undo_BeginBlock()
	for i = 2, num-1 do
		local delta_db = math.floor(a1+d*(i-1))
		local delta_vol=10^((delta_db)/20)
		reaper.SetMediaItemInfo_Value(item[i].it, 'D_VOL',delta_vol)
	end
    reaper.UpdateArrange()
	reaper.Undo_EndBlock('线性音量', -1)
end
linear_volume()