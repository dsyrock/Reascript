function linear_pitch()
    local num=reaper.CountSelectedMediaItems(0)
    if num==0 then return end
    local its={}
    for i=0, num-1 do
        local it=reaper.GetSelectedMediaItem(0,i)
        local pos=reaper.GetMediaItemInfo_Value(it,"D_POSITION")
        its[#its+1]={it=it, pos=pos}
    end
    table.sort(its,by_pos)
    local first=its[1].it
    local tk_st=reaper.GetActiveTake(first)
    if not tk_st then return end
    local last=its[num].it
    local tk_ed=reaper.GetActiveTake(last)
    if not tk_ed then return end
    local p_st=reaper.GetMediaItemTakeInfo_Value(tk_st, 'D_PITCH')
    local p_ed=reaper.GetMediaItemTakeInfo_Value(tk_ed, 'D_PITCH')
    local d=(p_ed-p_st)/(num-1)
    reaper.Undo_BeginBlock()
    for i=2, num-1 do
        local tk=reaper.GetActiveTake(its[i].it)
        if tk then
            reaper.SetMediaItemTakeInfo_Value(tk, 'D_PITCH', p_st+(i-1)*d)
        end
    end
    reaper.UpdateArrange()
    reaper.Undo_EndBlock('线性音调', -1)
end
linear_pitch()