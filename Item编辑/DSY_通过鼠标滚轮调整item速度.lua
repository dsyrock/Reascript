--[[
ReaScript Name: 通过鼠标滚轮调整item速度
Version: 1.0
Author: noiZ
]]

function main()

    local it=reaper.BR_ItemAtMouseCursor()
      
    local num=reaper.CountSelectedMediaItems(0)

    is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()

    function set_rate(it, tk, rate, len)

        local delta=0.05
        local rate_up, rate_down=rate+delta, rate-delta

        if val>0 then
        
            reaper.SetMediaItemTakeInfo_Value(tk, "D_PLAYRATE", rate_down)

            reaper.SetMediaItemLength(it, len*rate/rate_down, 1)

        else

            reaper.SetMediaItemTakeInfo_Value(tk, "D_PLAYRATE", rate_up)

            reaper.SetMediaItemLength(it, len*rate/rate_up, 1)

        end

    end

    function is_video(it)

        local _, chunk=reaper.GetItemStateChunk(it, 'string str', true)

        local path=chunk:match('FILE \"([^\"]+)\"')

        if chunk:find('SOURCE VIDEO') and not (path:match(".+%.(%w+)$")):find('wma') then return true else return false end

    end

    function rate_one(it)

        local tk=reaper.GetActiveTake(it)

        if not tk then return end

        if is_video(it) then return end

        local rate=reaper.GetMediaItemTakeInfo_Value(tk, "D_PLAYRATE")

        local length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")

        set_rate(it, tk, rate, length)

    end

    function rate_all(num)

        for i=0, num-1 do

            local it=reaper.GetSelectedMediaItem(0, i)

            local tk=reaper.GetActiveTake(it)

            if tk and not is_video(it) then
    
                local rate=reaper.GetMediaItemTakeInfo_Value(tk, "D_PLAYRATE")
    
                local length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
    
                set_rate(it, tk, rate, length)

            end
    
        end

    end

    if it then

        rate_one(it)

    elseif num>0 then

        rate_all(num)

    end

    reaper.UpdateArrange()

end

reaper.defer(main)
