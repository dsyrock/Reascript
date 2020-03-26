function main(debugmode, show, nuendo, keep)

    function msg(value)

        if show=="on" then reaper.ShowConsoleMsg(tostring(value) .. "\n") end
      
    end
    
    local proj = reaper.EnumProjects(-1, "")
    
    if not reaper.HasExtState("Temp_Proj_Path", 1) then reaper.MB("请先运行设定中转工程脚本", "警告", 0) return end
    
    if not reaper.APIExists("CF_GetSWSVersion") then reaper.MB("请先安装SWS", "警告", 0) return end
    
    local path=reaper.GetExtState("Temp_Proj_Path", 1)
    
    local path_nofilename=path:sub(1, (path:len()-string.find(path:reverse(), "/")+1))
    
    local fr=reaper.SNM_GetIntConfigVar("projfrbase", -1)
    
    if fr==-1 then reaper.MB("Please set framerate", "Warning", 0) return end
    
    local sep, framerate
    
    if fr==25 then
    
        sep="."
    
        framerate=tostring(fr)
    
    elseif fr==24 then
    
        sep="="
    
        framerate=tostring(fr)
    
    elseif fr==30 then
    
        sep="|"
    
        framerate=tostring(fr)
    
    else
    
        sep="|"
    
        framerate=tostring(30)
    
    end
    
    local samplerate=reaper.SNM_GetIntConfigVar("projsrate", -1)
    
    if samplerate==-1 then reaper.MB("Please set samplerate", "Warning", 0) return end
    
    local sr=tonumber(samplerate)

    local loop_setting=reaper.SNM_GetIntConfigVar('loopnewitems', -1)

    reaper.SNM_SetIntConfigVar('loopnewitems', 12)
    
    local shift_mode=reaper.SNM_GetIntConfigVar('defpitchcfg', -1)

    --------------------清理旧的AES文件---------------------
    if nuendo=="on" then
    
        local index=0
    
        local aes={}
    
        while true do
    
            local filename=reaper.EnumerateFiles(path_nofilename, index)
    
            if filename then
    
                if filename:find(".adl") then
    
                    local aes_file=path_nofilename..filename
    
                    table.insert(aes, aes_file)
    
                end
    
                index=index+1
    
            else
    
                break
    
            end
    
        end
    
        if #aes>0 then
    
            for k, v in pairs(aes) do
    
                os.remove(v)
    
            end
    
        end
    
    end
    
    if not reaper.GetProjectName(0, "") then reaper.MB('请先保存并命名工程', '警告', 0) return end

    local project_name_with_ext=reaper.GetProjectName(0, "")
    
    local project_name_index=string.len(project_name_with_ext)-4
    
    local project_name=string.sub(project_name_with_ext,1,project_name_index)
    
    local cur_pos=reaper.GetCursorPosition()
    
    local _, rgidx=reaper.GetLastMarkerAndCurRegion(0, cur_pos)
    
    if rgidx<0 then reaper.MB('请把光标放置在需要导出的Region中', '警告', 0) return end
    
    local _1, _2, left, right, region_name, _4=reaper.EnumProjectMarkers(rgidx)
    
    local tr_first=reaper.GetTrack(0, 0)
    
    reaper.PreventUIRefresh(1)
    
    local it_locate=reaper.AddMediaItemToTrack(tr_first)
    
    reaper.SetMediaItemPosition(it_locate, left, 0)
    
    reaper.SetMediaItemLength(it_locate, right-left, 0)
    
    reaper.SelectAllMediaItems(0, 0)
    
    reaper.Main_OnCommand(40297, 0)  -- unselect all tracks
    
    reaper.GetSet_LoopTimeRange(true, true, left, right, false)
    
    reaper.Main_OnCommand(40717, 0)  --select all items in time selection
    
    reaper.Main_OnCommand(40020, 0)  -- remove time selection
    
    reaper.PreventUIRefresh(-1)
    
    local it=reaper.GetSelectedMediaItem(0, 0)
    
    local tr=reaper.GetMediaItemTrack(it)
    
    local idx=reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    
    local num_tr=reaper.CountTracks(0)
    
    local trs={}
    
    for i=1, num_tr do
    
        local tr=reaper.GetTrack(0, i-1)
    
        local _, name=reaper.GetTrackName(tr, "")
    
        trs[i]=name
    
    end
    
    reaper.Main_OnCommand(40698, 0)  -- copy items
    
    reaper.SelectAllMediaItems(0, 0)
    
    reaper.DeleteTrackMediaItem(tr_first, it_locate)
    
    reaper.Main_OnCommand(41929,0)  -- new tab
    
    reaper.Main_openProject(path)
    
    reaper.SNM_SetIntConfigVar("projfrbase", fr)
    
    reaper.SNM_SetIntConfigVar("projsrate", sr)
    
    reaper.SNM_SetIntConfigVar('defpitchcfg', shift_mode)

    reaper.SelectAllMediaItems(0, 1)
    
    reaper.Main_OnCommand(40006, 0)  -- remove all items
    
    reaper.Main_OnCommand(40296, 0)  -- select all tracks
    
    reaper.Main_OnCommand(40005, 0)  -- remove all tracks
    
    reaper.Main_OnCommand(40042, 0)  -- goto start of project
    
    reaper.Main_OnCommand(40309, 0)  -- ripple off
    
    for i=1, #trs do
    
        reaper.InsertTrackAtIndex(i-1, 1)
    
        local tr=reaper.GetTrack(0, i-1)
    
        reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", trs[i], 1)
    
    end
    
    local tr=reaper.GetTrack(0, idx-1)
    
    reaper.SetOnlyTrackSelected(tr)
    
    reaper.Main_OnCommand(40058, 0)  -- paste  
    
    reaper.Main_OnCommand(40689, 0) -- unlock
    
    reaper.Main_OnCommand(40101, 0)  --online
    
    reaper.SelectAllMediaItems(0, 0)
    
    reaper.Main_OnCommand(40295, 0)  --zoom out
    
    ----------------------------------------------remove video and empty tracks-------------------------------------
    
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELMUTEDITEMS"), 0)  --select mute items
    
    reaper.Main_OnCommand(40006, 0)  -- remove item
    
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SEL_ALL_ITEMS_MIDI"), 0)  --select midi items
    
    reaper.Main_OnCommand(40006, 0)  -- remove item
    
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SEL_ALL_ITEMS_EMPTY"), 0)  --select empty items
    
    reaper.Main_OnCommand(40006, 0)  -- remove item
    
    local num=reaper.CountMediaItems(0)
    
    for i=0, num-1 do
    
        local it=reaper.GetMediaItem(0, i)
    
        local tk=reaper.GetMediaItemTake(it, 0)
    
        if reaper.GetMediaItemInfo_Value(it, "D_LENGTH")<0.0001 then reaper.SetMediaItemSelected(it, 1) end
    
        local sr=reaper.GetMediaItemTake_Source(tk)
    
        local type_name=reaper.GetMediaSourceType(sr, "")
    
        local psr = reaper.GetMediaSourceParent(sr)
    
        if psr then sr = psr end
    
        local filename_check=reaper.GetMediaSourceFileName(sr, "")
    
        local ext_check=filename_check:match(".+%.(%w+)$")
    
        if type_name=="VIDEO" and not ext_check:find("wma") then 
    
            reaper.SetMediaItemSelected(it, 1)
    
        end
    
    end
    
    reaper.Main_OnCommand(40006, 0)  -- remove item
    
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SELTRAXNOITEMS"), 0)  --select empty track
    
    reaper.Main_OnCommand(40005, 0)  -- remove track

    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELMUTEDTRACKS"), 0)  --select muted track
    
    reaper.Main_OnCommand(40005, 0)  -- remove track
    
    
    -----------------------------------------Force Offline-------------------------------------------
    msg("Checking Offline Item")
    
    local num=reaper.CountMediaItems(0)
    
    for i=0, num-1 do
    
        local it=reaper.GetMediaItem(0, i)
    
        local _, state=reaper.GetItemStateChunk(it, "", true)
    
        if state:find("OFFLINE") then
    
            reaper.SetMediaItemSelected(it, 1)
    
        end
    
    end
    
    reaper.Main_OnCommand(42356, 0)  --force online
    
    reaper.SelectAllMediaItems(0, 0)
    
    -----------------------------------------Overlapping----------------------------------------------
    local num=reaper.CountTracks(0)
    
    for i=0, num-1 do
    
        local tr=reaper.GetTrack(0, i)
    
        local idx=1
    
        while true do
    
            local it=reaper.GetTrackMediaItem(tr, idx)
    
            if it then
    
                local itpos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")
    
                local itpre=reaper.GetTrackMediaItem(tr, idx-1)
    
                local itend=reaper.GetMediaItemInfo_Value(itpre, "D_POSITION")+reaper.GetMediaItemInfo_Value(itpre, "D_LENGTH")
    
                if itpos<itend then
    
                    reaper.SetOnlyTrackSelected(tr)
    
                    reaper.Main_OnCommand(40751, 0)  -- free position on
    
                    reaper.SetMediaItemSelected(it, 1)
    
                    reaper.SetMediaItemSelected(itpre, 1)
    
                    reaper.Main_OnCommand(40257, 0)  -- glue items
    
                    reaper.Main_OnCommand(40752, 0)  -- free position off
    
                    reaper.SelectAllMediaItems(0, 0)
    
                else
    
                    idx=idx+1
    
                end
    
            else
    
                break
    
            end 
    
        end
    
    end
    
    
    -------------------------------------------------dealing special items-------------------------------------------------
    local cur=reaper.GetCursorPosition()
    
    local num=reaper.CountMediaItems(0)

    function glue(it, keep)
        local vol=reaper.GetMediaItemInfo_Value(it, 'D_VOL')
        local db=math.log(vol,10)*20-10
        reaper.SetMediaItemInfo_Value(it, 'D_VOL', 10^(db/20))
        if not keep then 
            reaper.Main_OnCommand(40257, 0)  -- glue item
        else
            reaper.Main_OnCommand(40362, 0)  -- glue item keeping fade
        end
        local it_new=reaper.GetSelectedMediaItem(0, 0)
        reaper.SetMediaItemInfo_Value(it_new, 'D_VOL', 10^0.5)
    end
    
    function glue_nokeep(it)
        reaper.SetMediaItemSelected(it, 1)
        glue(it, false)
        reaper.SelectAllMediaItems(0, 0)
    end
    
    function glue_keep(it, channel)
        reaper.PreventUIRefresh(1)
        reaper.SetMediaItemSelected(it, 1)
        local pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        local length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        reaper.SetMediaItemPosition(it, pos+3600, 0)
        reaper.Main_OnCommand(42228, 0)  --restore start end
        if channel=='mono' then
            reaper.Main_OnCommand(40209, 0)  --apply fx to take
            reaper.Main_OnCommand(45000, 0)  --switch to take 1
            reaper.Main_OnCommand(40129, 0)  --delete take 1
        else
            glue(it, true)
        end
        local it_new=reaper.GetSelectedMediaItem(0, 0)
        local tk_new=reaper.GetActiveTake(it_new)
        reaper.SetEditCurPos(pos+3600, 0, 0)
        reaper.Main_OnCommand(41305, 0)  -- trim left edge
        reaper.SetMediaItemLength(it_new, length, 0)
        reaper.SetMediaItemPosition(it_new, pos, 0)
        reaper.SelectAllMediaItems(0, 0)
        reaper.PreventUIRefresh(-1)
    end
    
    for i=0, num-1 do
    
        local num_check=reaper.CountMediaItems(0)
    
        msg("Checking Special:"..(i+1).."/"..num_check)
    
        local it=reaper.GetMediaItem(0, i)

        local _, state=reaper.GetItemStateChunk(it, '', true)
    
        local tk=reaper.GetMediaItemTake(it, 0)
    
        local source=reaper.GetMediaItemTake_Source(tk)
 
        local num_chan=reaper.GetMediaSourceNumChannels(source)

        local env_pan=reaper.GetTakeEnvelopeByName(tk, 'Pan')

        local chan_mode=reaper.GetMediaItemTakeInfo_Value(tk, "I_CHANMODE")
        
        if env_pan and (num_chan==1 or chan_mode>=2) then

            if keep=='off' then

                reaper.SetMediaItemSelected(it, 1)

                reaper.Main_OnCommand(40209, 0)  --apply fx to take

                reaper.Main_OnCommand(45000, 0)  --switch to take 1
                
                reaper.Main_OnCommand(40129, 0)  --delete take 1

                reaper.SelectAllMediaItems(0, 0)

            else

                glue_keep(it, 'mono')

            end

        else

            local length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
        
            local sr_check=reaper.GetMediaSourceSampleRate(source)
      
            local pitch=reaper.GetMediaItemTakeInfo_Value(tk, "D_PITCH")
        
            local rate=reaper.GetMediaItemTakeInfo_Value(tk, "D_PLAYRATE")
        
            local pan=reaper.GetMediaItemTakeInfo_Value(tk, "D_PAN")

            local env=reaper.GetTakeEnvelope(tk, 0)
        
            local shape1=reaper.GetMediaItemInfo_Value(it, "C_FADEINSHAPE")
        
            local shape2=reaper.GetMediaItemInfo_Value(it, "C_FADEOUTSHAPE")

            local fin=reaper.GetMediaItemInfo_Value(it, "D_FADEINLEN")

            local fout=reaper.GetMediaItemInfo_Value(it, "D_FADEOUTLEN")
        
            local str_mk_num=reaper.GetTakeNumStretchMarkers(tk)
        
            local offset=reaper.GetMediaItemTakeInfo_Value(tk, "D_STARTOFFS")
        
            local num_fx=reaper.BR_GetTakeFXCount(tk)
        
            local isloop=reaper.GetMediaItemInfo_Value(it, "B_LOOPSRC")
   
            local psr = reaper.GetMediaSourceParent(source)

            if psr then source = psr end
        
            local name_check=reaper.GetMediaSourceFileName(source, "")

            local file=io.open(name_check, "rb")

            local content

            if file then 
                
                content = file:read("*a")
            
                file:close()

            end
            
            local isempty=false
        
            if isloop==0 then
        
                local orilen=reaper.GetMediaSourceLength(source)
        
                if length-orilen>0.0001 or length-(orilen-offset)>0.0001 then isempty=true end

            end
            
            if isempty or offset<0 then
                glue_nokeep(it)
            elseif pitch~=0 or rate~=1 or pan~=0 or chan_mode~=0 or psr or env~=nil or str_mk_num>0 or name_check=="" or name_check:find(".aif", 1, true) or name_check:find(".ogg", 1, true) or name_check:find(".flac", 1, true) or name_check:find(".wma", 1, true) or num_fx>0 or sr_check~=sr or shape1>0 or shape2>0 or content:find('LIST') or state:find('SOURCE LTC') or fin-length+fout>-0.0001 then
                if keep=="on" then
                    glue_keep(it, 'stereo')
                else
                    glue_nokeep(it)
                end
            end

        end
    end
    
    reaper.SetEditCurPos(cur, 0, 0)
    
    -----------------------------------------------Cut loops------------------------------------------------------
    
    local its={}
    
    for i=1, num do
    
        its[i]=reaper.GetMediaItem(0, i-1)
    
        local tk=reaper.GetActiveTake(its[i])
    
    end
    
    function splitlong(it, ori_len, fadeout)

        while it~=nil do
    
            local tk=reaper.GetActiveTake(it)
    
            reaper.SetMediaItemTakeInfo_Value(tk, "D_STARTOFFS", 0)
            
            local pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")
    
            local length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
    
            if ori_len<=length-fadeout then

                it=reaper.SplitMediaItem(it, pos+ori_len)
    
            elseif ori_len>length-fadeout and length>ori_len then

                local it_new=reaper.SplitMediaItem(it, pos+length-fadeout)

                reaper.SetMediaItemSelected(it_new, 1)
    
                reaper.Main_OnCommand(40257, 0)  -- glue item
    
                reaper.SelectAllMediaItems(0, 0)
    
                it=nil
    
            elseif ori_len>length-fadeout and length<ori_len then 

                it=nil
    
            end
    
        end
    
    end
    
    for i=1, #its do
    
        local pos=reaper.GetMediaItemInfo_Value(its[i], "D_POSITION")
        
        local length=reaper.GetMediaItemInfo_Value(its[i], "D_LENGTH")
        
        local fadein=reaper.GetMediaItemInfo_Value(its[i], "D_FADEINLEN")
    
        local fadeout=reaper.GetMediaItemInfo_Value(its[i], "D_FADEOUTLEN")
    
        local tk=reaper.GetActiveTake(its[i])
    
        msg("cutting loop:"..":"..i.."/"..#its.." Name: "..reaper.GetTakeName(tk).. " At: "..pos.." In Track: "..reaper.GetMediaTrackInfo_Value(reaper.GetMediaItemTrack(its[i]), "IP_TRACKNUMBER") )
        
        local source=reaper.GetMediaItemTake_Source(tk)
    
        local ori_len=reaper.GetMediaSourceLength(source)
        
        local offset=reaper.GetMediaItemTakeInfo_Value(tk, "D_STARTOFFS")
    
    
    
    ----------------------------------------没有offset时----------------------------------------
    
        if offset==0 or math.abs(ori_len-offset)<0.0001 then  
    
            if math.abs(length-ori_len)<0.0001 then
    
                reaper.SetMediaItemSelected(its[i], 1)
    
                reaper.Main_OnCommand(42228, 0)  -- set to source length
    
                reaper.SetMediaItemSelected(its[i], 0)
    
            end
    
            if (length-ori_len)>0.0001 then  --长度大于等于原始长度

                if fadein<=ori_len then     --淡入没有跨过循环点

                    splitlong(its[i], ori_len, fadeout)
    
                else                        --淡入跨过循环点

                    local it_new=reaper.SplitMediaItem(its[i], pos+fadein)  --从淡入点剪开
    
                    reaper.SetMediaItemSelected(its[i], 1)
    
                    reaper.Main_OnCommand(40257, 0)  -- glue item
    
                    reaper.SelectAllMediaItems(0, 0)
    
                    local tk_new=reaper.GetActiveTake(it_new)
    
                    local offset_new=reaper.GetMediaItemTakeInfo_Value(tk_new, "D_STARTOFFS")
                    --pos+fadein即为新的pos  
                    local it_new2=reaper.SplitMediaItem(it_new, pos+fadein+ori_len-offset_new)
    
                    splitlong(it_new2, ori_len, fadeout)
    
                end  --if fadein<=ori_len
    
            else

                reaper.SetMediaItemTakeInfo_Value(tk, "D_STARTOFFS", 0)
    
            end  --if length>ori_len then
    
        end  -- offset==0 or offset==ori_len then
    
    
    
    ----------------------------------------有offset时----------------------------------------
    
        if offset>0 and ori_len-offset>0.0001 then         --有offset时
    
            if length-(ori_len-offset)>0.0001 then           --长度大于循环点左侧部分长度

                if ori_len-offset-fadein>=0.0001 then      --淡入没有跨过循环点

                    if (pos+ori_len-offset)-(pos+length-fadeout)<0.0001 then  --分割点pos+ori_len-offset小于等于淡出点

                        local it_new=reaper.SplitMediaItem(its[i], pos+ori_len-offset)

                        splitlong(it_new, ori_len, fadeout)

                    else                                                                        --分割点pos+ori_len-offset大于淡出点

                        local it_new=reaper.SplitMediaItem(its[i], pos+length-fadeout)

                        reaper.SetMediaItemSelected(it_new, 1)
            
                        reaper.Main_OnCommand(40257, 0)  -- glue item
            
                        reaper.SelectAllMediaItems(0, 0)
            
                    end
    
                else                                --淡入跨过循环点

                    local it_new=reaper.SplitMediaItem(its[i], pos+fadein)
        
                    reaper.SetMediaItemSelected(its[i], 1)
    
                    reaper.Main_OnCommand(40257, 0)  -- glue item
    
                    reaper.SelectAllMediaItems(0, 0)
    
                    local tk_new=reaper.GetActiveTake(it_new)
    
                    local offset_new=reaper.GetMediaItemTakeInfo_Value(tk_new, "D_STARTOFFS")
   
                    local length_new=reaper.GetMediaItemInfo_Value(it_new, "D_LENGTH")
                    --pos+fadein即为新的pos  
                    if (pos+fadein+ori_len-offset_new)-(pos+fadein+length_new-fadeout)<0.0001 then  --分割点pos+ori_len-offset小于等于淡出点

                        local it_new=reaper.SplitMediaItem(it_new, pos+fadein+ori_len-offset_new)
                    
                        splitlong(it_new, ori_len, fadeout)
        
                    else                                                                        --分割点pos+ori_len-offset大于淡出点

                        local it_new=reaper.SplitMediaItem(it_new, pos+fadein+length_new-fadeout)

                        reaper.SetMediaItemSelected(it_new, 1)
            
                        reaper.Main_OnCommand(40257, 0)  -- glue item
            
                        reaper.SelectAllMediaItems(0, 0)
            
                    end

                end  -- fade<=ori_len-offset
    
            end  --length>ori_len-offset
    
        end  -- offset>0 and offset<ori_len
    
    end  -- for i=1, #its do
    
    reaper.SelectAllMediaItems(0, 1)

    reaper.SNM_SetIntConfigVar('loopnewitems', loop_setting)

    if debugmode=="off" then
    ---------------------------------------------------export AES31----------------------------------------------------
        msg("exporting AES31 file")
    
        local proj_name=reaper.GetProjectName(0, "")
    
        local edge_proj=proj_name:find("%.")-1
    
        proj_name=proj_name:sub(1, edge_proj)
    
        local target=path_nofilename..project_name.."-"..region_name..".adl"
    
        local file=io.output(target, w)

    --------------------------------------------- writing basic information------------------------------------
    
        msg("writing basic information")
    
        file:write("<ADL>\n<VERSION>\n(ADL_ID)\t\"\"\n(ADL_UID)\t\"\"\n(VER_ADL_VERSION)\t\"\"\n(VER_CREATOR)\t\"DSY\"\n(VER_CRTR)\t\"\"\n</VERSION>\n")
    
        file:write("<PROJECT>\n(PROJ_TITLE)\t\""..proj_name.."\"\n(PROJ_ORIGINATOR)\t\"\"\n(PROJ_CREATE_DATE)\t\"\"\n(PROJ_NOTES)\t\"\"\n(PROJ_CLIENT_DATA)\t_\n</PROJECT>\n")
    
        file:write("<SYSTEM>\n(SYS_SRC_OFFSET)\t00"..sep.."00"..sep.."00.00/0000\n</SYSTEM>\n")
    
        file:write("<SEQUENCE>\n(SEQ_TITLE)\t\""..proj_name.."\"\n(SEQ_SAMPLE_RATE)\tS"..samplerate.."\n(SEQ_FRAME_RATE)\t"..framerate.."\n(SEQ_ADL_LEVEL)\t1\n(SEQ_CLEAN)\tFALSE\n(SEQ_SORT)\t0\n(SEQ_MULTICHAN)\tFALSE\n(SEQ_DEST_START)\t00"..sep.."00"..sep.."00.00/0000\n</SEQUENCE>\n")
    
    --------------------------------------------- writing track information------------------------------------
    
        msg("writing track list information")
    
        file:write("<TRACKLIST>\n")
    
        local trs={}
    
        local num=reaper.CountTracks(0)
    
        for i=1, num do
    
            trs[i]={}
    
            trs[i].tr=reaper.GetTrack(0, i-1)
    
            local _, name=reaper.GetTrackName(trs[i].tr, "")
    
            trs[i].num=(2*i-1).."-"..(2*i)
    
            file:write("(Track) "..(2*i-1).."\t\""..name.."\"\n")
    
            file:write("(Track) "..(2*i).."\t\"\"\n")
    
        end
    
        file:write("</TRACKLIST>\n")
    
    --------------------------------------------- writing source information------------------------------------
    
        msg("writing source information")
    
        file:write("<SOURCE_INDEX>\n")
    
        local num=reaper.CountMediaItems(0)
    
        local paths, paths_idx, text={}, 1, ''
    
        for i=0, num-1 do
    
            local it=reaper.GetMediaItem(0, i)
    
            local tk=reaper.GetActiveTake(it)
    
            local source=reaper.GetMediaItemTake_Source(tk)
    
            local path=reaper.GetMediaSourceFileName(source, "")
    
            local path_name=path:match(".+[/\\]([^/\\]+)")
    
            if not text:find(path, 1, true) then

                text=text..path

                table.insert(paths, path)
    
                file:write("(Index) "..paths_idx.."\t(F)\t\"url:file://localhost/"..path.."\"\t_\t00.00.00.00/0000\t_\t\""..path_name.."\"\t_\n")
    
                paths_idx=paths_idx+1
        
            end
    
        end
    
        file:write("</SOURCE_INDEX>\n")
    
    --------------------------------------------- writing clip information------------------------------------
    
        msg("writing clip information")
    
        file:write("<EVENT_LIST>\n")
    
        function formattime(t)
    
            local hour=tostring(math.modf(t/3600))
    
            if hour:len()<2 then hour="0"..hour end
    
            local min=tostring(math.modf(t%3600/60))
    
            if min:len()<2 then min="0"..min end
    
            local sec, ff=math.modf(t%3600%60)
    
            if tostring(sec):len()<2 then sec="0"..sec end
    
            --local ff,ss=math.modf(rest1*100)
            local ff,ss=math.modf(ff*fr)
            --local ss=math.modf(rest1*100)
            local ss=math.modf(ss/fr*sr)
            --ff=math.modf(ff*fr/100)
    
            if tostring(ff):len()<2 then ff="0"..ff end
    
            --ss=math.modf(sr*ss/100)
    
            if tostring(ss):len()==3 then 
    
                ss="0"..ss 
    
            elseif tostring(ss):len()==2 then
    
                ss="00"..ss
    
            elseif tostring(ss):len()==1 then
    
                ss="000"..ss
    
            end
    
            local time=hour..sep..min..sep..sec.."."..ff.."/"..ss
    
            return time
    
        end
    
        for i=0, num-1 do
    
            local it=reaper.GetMediaItem(0, i)
    
            local tk=reaper.GetActiveTake(it)
    
            local source=reaper.GetMediaItemTake_Source(tk)
    
            local path=reaper.GetMediaSourceFileName(source, "")
    
            local source_check
    
            for k, v in pairs(paths) do
    
                if path==v then source_check=k end
    
            end
    
            local tr=reaper.GetMediaItemTrack(it)
    
            local tr_num
    
            for k, v in pairs(trs) do
    
                if tr==trs[k].tr then tr_num=trs[k].num end
    
            end
    
            local pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")
    
            local edge=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")+pos
    
            local start=reaper.GetMediaItemTakeInfo_Value(tk, "D_STARTOFFS")
    
            local t1=formattime(start)
    
            local t2=formattime(pos)
    
            local t3=formattime(edge)
    
            local vol1=reaper.GetMediaItemInfo_Value(it, "D_VOL")
    
            local vol2=reaper.GetMediaItemTakeInfo_Value(tk, "D_VOL")
    
            local db1=math.log(vol1,10)*20
    
            local db2=math.log(vol2,10)*20
    
            local db=db1+db2
    
            local name=reaper.GetTakeName(tk)
    
            local fadein=reaper.GetMediaItemInfo_Value(it, "D_FADEINLEN")
    
            local fadeout=reaper.GetMediaItemInfo_Value(it, "D_FADEOUTLEN")
    
            file:write("(Entry) "..(i+1).."\t(Cut)\tI\t"..source_check.."\t1-2\t"..tr_num.."\t"..t1.."\t"..t2.."\t"..t3.."\tR\n")
    
            if fadein~=0 then
    
                file:write("(Infade)\t"..formattime(fadein).."\tLIN\t_\t_\t_\n")
    
            end
    
            if fadeout~=0 then
    
                file:write("(Outfade)\t"..formattime(fadeout).."\tLIN\t_\t_\t_\n")
    
            end
    
            if db~=0 then
    
                file:write("(Gain) 1\t"..db.."\n")
    
            end
    
            file:write("(Rem)\tNAME\t\""..name.."\"\n")
    
        end
    
        file:write("</EVENT_LIST>\n")
    
        file:write("</ADL>")
    
        file:close()
    
        local command=[[powershell -c "dir ']]..target..[[' |%{[IO.File]::ReadAllText($_,[Text.Encoding]::UTF8)|Out-File ']]..target..[[' -en Default}"]]

        reaper.ExecProcess(command, 10000)
    
        msg("\n".."Done!")
    
        reaper.SelectAllMediaItems(0, 1)
    
    --------------------------善后处理--------------------------
    
        reaper.Main_OnCommand(40006, 0)  -- remove items
    
        reaper.Main_OnCommand(40026, 0)  -- save project
    
        if show=="on" then
    
            function check_message()
    
                local hwnd = reaper.JS_Window_Find('ReaScript', false)
    
                if hwnd then 
    
                    reaper.JS_Window_Destroy(hwnd)
    
                else 
    
                    reaper.defer(check_message)
    
                end
    
            end
    
            check_message()
    
        end
      
        reaper.Main_OnCommand(40860, 0)  -- close project
    
        reaper.SelectProjectInstance(proj)
    
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_FOCUS_TRACKS"), 0)  -- focus main
    
    --------------------------剪贴板-------------------------- 
    
        local date=os.date("%y")..os.date("%m")..os.date("%d").."-"..os.date("%H")..os.date("%M")..os.date("%S")
    
        local text=project_name.." "..region_name.." FX "..date
    
        reaper.CF_SetClipboard(text)
    
    end
    
    if nuendo=="on" and debugmode=="off" then
    
    --------------------------启动nuendo-------------------------
        local window=reaper.GetMainHwnd()
    
        local title=reaper.JS_Window_GetTitle(window, "")
    
        local me=title:find("SiYu")~=nil
    
        if me then 
            
            local nuendo_path=reaper.GetResourcePath()
    
            nuendo_path=nuendo_path.."\\Scripts\\ahk\\nuendo.ahk"
    
            reaper.CF_ShellExecute(nuendo_path) 
        
        end
    
    end
end