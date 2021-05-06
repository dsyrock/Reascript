function main()
    local db=1  --每次变动的音量值
    local dir=0  --0为正向，1为反向
    local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()

    function db_one(it, db0)
        if (dir==0 and val<0) or (dir==1 and val>0) then
            reaper.SetMediaItemInfo_Value(it, "D_VOL", 10^((db0+db)/20))
        else
            reaper.SetMediaItemInfo_Value(it, "D_VOL", 10^((db0-db)/20))
        end                       
    end

    function db_all(num)
        for i=0, num-1 do
            local it=reaper.GetSelectedMediaItem(0, i)
            local vol=reaper.GetMediaItemInfo_Value(it, "D_VOL")
            local db0=math.log(vol,10)*20
            if (dir==0 and val<0) or (dir==1 and val>0) then
                reaper.SetMediaItemInfo_Value(it, "D_VOL", 10^((db0+db)/20))
            else
                reaper.SetMediaItemInfo_Value(it, "D_VOL", 10^((db0-db)/20))
            end
        end
    end

    local it=reaper.BR_ItemAtMouseCursor()
    
    if it then

        local pos_it=reaper.GetMediaItemInfo_Value(it, "D_POSITION")

        local length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        
        local tk=reaper.GetActiveTake(it)

        if not tk then return end

        local rate=reaper.GetMediaItemTakeInfo_Value(tk, "D_PLAYRATE") 

        local vol=reaper.GetMediaItemInfo_Value(it, "D_VOL")

        local db0=math.log(vol,10)*20

        local check1, check2=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)

        if check1>pos_it and check1<pos_it+length and check2>pos_it and check2<pos_it+length then

            reaper.SetMediaItemSelected(it, 1)

            reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENVSHOW1"), 0)  -- show volume envelope

            local env=reaper.GetTakeEnvelopeByName(tk, "Volume")

            reaper.Main_OnCommand(40020, 0)  -- remove time selection

            local v_new

            if (dir==0 and val<0) or (dir==1 and val>0) then

                v_new=10^(db/20)

            else

                v_new=10^(-db/20)

            end

            reaper.InsertEnvelopePoint(env,(check1-pos_it)*rate,1,0,0,false,false)

            reaper.InsertEnvelopePoint(env,(check1-pos_it)*rate,v_new,0,0,false,false)

            reaper.InsertEnvelopePoint(env,(check2-pos_it)*rate,v_new,0,0,false,false)                

            reaper.InsertEnvelopePoint(env,(check2-pos_it)*rate,1,0,0,false,false)

            reaper.SetMediaItemSelected(it, 0)

        else

            local env=reaper.GetTakeEnvelopeByName(tk, "Volume")         

            if env then
                
                local num=reaper.CountEnvelopePoints(env)

                local pos_it=reaper.GetMediaItemInfo_Value(it, "D_POSITION")

                local pos_mouse=(reaper.BR_PositionAtMouseCursor(1)-pos_it)*rate

                local index=reaper.GetEnvelopePointByTime(env, pos_mouse)

                local _, pos0, v0 = reaper.GetEnvelopePoint(env, index-1)
                local _, pos1, v1, sh1, ten1, sel1 = reaper.GetEnvelopePoint(env, index)
                local _, pos2, v2, sh2, ten2, sel2 = reaper.GetEnvelopePoint(env, index+1)
                local _, pos3, v3 = reaper.GetEnvelopePoint(env, index+2)

                if index>=1 and index+2<=num-1 and pos0==pos1 and pos2==pos3 and v0==v3 and v1==v2 then

                    local db_new

                    if (dir==0 and val<0) or (dir==1 and val>0) then

                        db_new=math.log(v1,10)*20+db

                    else

                        db_new=math.log(v1,10)*20-db

                    end

                    reaper.SetEnvelopePoint(env, index, pos1, 10^(db_new/20), sh1, ten1, sel1, false)

                    reaper.SetEnvelopePoint(env, index+1, pos2, 10^(db_new/20), sh2, ten2, sel2, false)

                else

                    db_one(it, db0)

                end

            else
                
                db_one(it, db0)

            end

        end

    else

        local num=reaper.CountSelectedMediaItems(0)

        if num>0 then db_all(num) end

    end

    reaper.UpdateArrange()

end

reaper.defer(main)
