--[[
ReaScript Name: 通过鼠标滚轮调整item间距
Version: 1.0
Author: noiZ
]]

function msg(value)
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
end

function main()
	reaper.PreventUIRefresh(1)
	local num=reaper.CountSelectedMediaItems(0)
	if num<2 then return end

	local its={}
	for i=1, num do
        local it=reaper.GetSelectedMediaItem(0, i-1)
        local snap=reaper.GetMediaItemInfo_Value(it, 'D_SNAPOFFSET')
        local pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")+snap
        its[i]={item=it, snap=snap, pos=pos}
	end
	function by_pos(t1,t2)
		return t1.pos<t2.pos
	end
	table.sort(its, by_pos)

    local time_d=0.0000001
    function move(t, d)
        local k=d and (1-time_d) or (1+time_d)
        for i=2, num do
            local pos=its[i].pos*k^(i-1)-its[i].snap
            reaper.SetMediaItemPosition(its[i].item, pos, 0)
        end
    end

	local _1, _2, _3, _4, _5, _6, dir=reaper.get_action_context()
    if dir>0 then
        move(its, false)
    elseif dir<0 then
        if its[2].pos*(1-time_d)>its[1].pos then move(its, true) end
    end

	reaper.PreventUIRefresh(-1)
	reaper.UpdateArrange()
end
reaper.defer(main)
