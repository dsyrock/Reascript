local num=reaper.CountSelectedMediaItems(0)

if num==0 then return end

for i = 0, num-1 do
    
    it = reaper.GetSelectedMediaItem( 0, i)
	
	text=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")

    min=math.modf(text/60)

    second=math.modf(math.modf(text%60*100)/100)

    note=min..":"..second

    reaper.ULT_SetMediaItemNote(it, note)

    local _,chunk =reaper.GetItemStateChunk(it, "", 0)

    if string.find(chunk, "IMGRESOURCEFLAGS 0") then

        chunk = string.gsub(chunk, "IMGRESOURCEFLAGS 0", "IMGRESOURCEFLAGS 2")

        reaper.SetItemStateChunk(it, chunk, 0)

    end

end

reaper.UpdateArrange()
