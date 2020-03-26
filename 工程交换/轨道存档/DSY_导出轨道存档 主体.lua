function main(debugmode, show, nuendo, keep)

    function msg(value)

        if show=="on" then reaper.ShowConsoleMsg(tostring(value) .. "\n") end
      
    end
    
    local proj = reaper.EnumProjects(-1, "")
    
    if not reaper.HasExtState("Temp_Proj_Path", 1) then reaper.MB("请先运行设定中转工程脚本", "警告", 0) return end
    
    if not reaper.APIExists("CF_GetSWSVersion") then reaper.MB("请先安装SWS", "警告", 0) return end
    
    local path=reaper.GetExtState("Temp_Proj_Path", 1)
    
    local path_nofilename=path:match("(.+)[/\\][^/\\]+")
    
    local samplerate=reaper.SNM_GetIntConfigVar("projsrate", -1)
    
    if samplerate==-1 then reaper.MB("Please set samplerate", "Warning", 0) return end
    
    local sr=tonumber(samplerate)

    local loop_setting=reaper.SNM_GetIntConfigVar('loopnewitems', -1)

    reaper.SNM_SetIntConfigVar('loopnewitems', 12)
    
    local shift_mode=reaper.SNM_GetIntConfigVar('defpitchcfg', -1)

    if reaper.GetProjectName(0, "")=='' then reaper.MB('请先保存并命名工程', '警告', 0) return end

    local project_name=reaper.GetProjectName(0, ""):match("(.+)%.[^%.]+")

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

            local ext=name_check:match(".+%.(%w+)$")

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
            elseif rate~=1 or pan~=0 or chan_mode~=0 or psr or env~=nil or str_mk_num>0 or name_check=="" or not ext or ext:lower()~='wav' or num_fx>0 or sr_check~=sr or shape1>0 or shape2>0 or content:find('acid') or state:find('SOURCE LTC') or fin-length+fout>-0.0001 then
                if show=='on' then
                    if pitch~=0 then msg('pitch')
                    elseif rate~=1 then msg('rate')
                    elseif pan~=0 then msg('pan')
                    elseif chan_mode~=0 then msg('chan_mode')
                    elseif psr then msg('psr')
                    elseif env~=nil then msg('env')
                    elseif str_mk_num>0 then msg('str mk num')
                    elseif name_check=='' or name_check:find('.aif', 1, true) or name_check:find(".ogg", 1, true) or name_check:find(".flac", 1, true) or name_check:find(".wma", 1, true) then msg('name_check')
                    elseif num_fx>0 then msg('num_fx')
                    elseif sr_check~=sr then msg('sr_check')
                    elseif shape1>0 or shape2>0 then msg('shape')
                    elseif content:find('acid') then msg('acid')
                    elseif state:find('SOURCE LTC') then msg('LTC')
                    elseif fin-length+fout>-0.0001 then msg('fadein=fadeout')
                    end
                end
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


    -------------------------------------------------------------------dubug模式关闭后-------------------------------------------------------------------
    if debugmode=="off" then

        local xml=''
        local tab=0
    
    -------------------------------------------------------------------建立轨道存档文件夹-------------------------------------------------------------------
        local target_filename=project_name..'_'..region_name..'_'..os.date("%H")..os.date("%M")..os.date("%S")
        
        local target_path=path_nofilename..'\\'..target_filename..'\\'

        local target_media=target_path..'Media\\'

        local target_file=target_path..target_filename..'_FX'..'.xml'
        
        reaper.ExecProcess('cmd /c mkdir \"'..target_path..'\"', 0)

    
    --------------------------------------------- writing xml------------------------------------
        function write_line(text)
            if text:find('</', 1, true) then tab=tab-1 end
            text=string.rep('\t', tab)..text..'\n'
            if text:find('[^/?]>') and not text:find('</') then tab=tab+1 end
            return text
        end

        xml=xml..write_line([[<?xml version="1.0" encoding="utf-8"?> creat by DSY]])
        xml=xml..write_line([[<tracklist>]])
        xml=xml..write_line([[<list name="track" type="obj">]])
    
        local idx={tr='01', it='02', path='03', mlist='04', audioclip='05', cluster='06', stream='07', fn='08', fin='09', lin='10', fout='11', lout='12', dev='13'}
    
        local num_track=reaper.CountTracks(0)
    
        local fns, its_no_change, it_count={}, {}, 0
    
        function write_fade(len, mode, spr, fid, lid)
            local fade=len*spr
            local name
            if mode=='in' then name='FadeIn' else name='FadeOut' end
            xml=xml..write_line([[<obj class="M]]..name..[[" name="]]..name..[[" ID="]]..fid..[[">]])
            xml=xml..write_line([[<obj class="MLinearInterpolator" name="Curve" ID="]]..lid..[[">]])
            xml=xml..write_line([[<list name="Points" type="list">]])
            xml=xml..write_line([[<item>]])
            xml=xml..write_line([[<float name="X" value="0"/>]])
            local y
            if mode=='in' then y=0 else y=1 end
            xml=xml..write_line([[<float name="Y" value="]]..y..[["/>]])
            xml=xml..write_line([[</item>]])
            xml=xml..write_line([[<item>]])
            xml=xml..write_line([[<float name="X" value="]]..fade..[["/>]])
            if mode=='in' then y=1 else y=0 end
            xml=xml..write_line([[<float name="Y" value="]]..y..[["/>]])
            xml=xml..write_line([[</item>]])
            xml=xml..write_line([[</list>]])
            xml=xml..write_line([[<float name="XMin" value="0"/>]])
            xml=xml..write_line([[<float name="XMax" value="]]..fade..[["/>]])
            xml=xml..write_line([[<float name="YMin" value="0"/>]])
            xml=xml..write_line([[<float name="YMax" value="1"/>]])
            xml=xml..write_line([[</obj>]])
            xml=xml..write_line([[</obj>]])
        end
    
        function copy_file(path_sr, path_des)
            local file=io.open(path_sr, "rb")
            local content = file:read("*a")
            file:close()
            local file=io.open(path_des, "wb")
            file:write(content)
            file:close()
        end

        for i=0, num_track-1 do
    
            xml=xml..write_line([[<obj class="MAudioTrackEvent" ID="]]..idx['tr']..i..[[">]])
            xml=xml..write_line([[<int name="Flags" value="1"/>]])
            xml=xml..write_line([[<float name="Start" value="0"/>]])
            xml=xml..write_line([[<float name="Length" value="1200"/>]])
            xml=xml..write_line([[<obj class="MListNode" name="Node" ID="]]..idx['mlist']..i..[[">]])

            local tr=reaper.GetTrack(0, i)
            local _, tr_name=reaper.GetTrackName(tr, '')
            
            xml=xml..write_line([[<string name="Name" value="]]..tr_name..[[" wide="true"/>]])
            xml=xml..write_line([[<list name="Events" type="obj">]])

            local num_it=reaper.CountTrackMediaItems(tr)

            for j=0, num_it-1 do

                it_count=it_count+1

                xml=xml..write_line([[<obj class="MAudioEvent" ID="]]..idx['it']..it_count..[[">]])

                local it=reaper.GetTrackMediaItem(tr, j)

                local start=reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
                
                xml=xml..write_line([[<float name="Start" value="]]..start..[["/>]])

                local tk=reaper.GetActiveTake(it)
                local tk_pitch=reaper.GetMediaItemTakeInfo_Value(tk, 'D_PITCH')
                local sr=reaper.GetMediaItemTake_Source(tk)
                local spr=reaper.GetMediaSourceSampleRate(sr)

                local len=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
                xml=xml..write_line([[<float name="Length" value="]]..len*spr..[["/>]])

                local offset=reaper.GetMediaItemTakeInfo_Value(tk, 'D_STARTOFFS')
                xml=xml..write_line([[<float name="Offset" value="]]..offset*spr..[["/>]])

                local vol=reaper.GetMediaItemInfo_Value(it, 'D_VOL')
                xml=xml..write_line([[<float name="Volume" value="]]..vol..[["/>]])

                local _, chunk=reaper.GetItemStateChunk(it, '', 1)
                local it_path=chunk:match('FILE \"([^\"]+)\"')
                local it_fn=it_path:match(".+[/\\]([^/\\]+)")

                if not (it_path:gsub('/', '\\')):find(path_nofilename:gsub('/', '\\'), 1, true) and not its_no_change[it_path] then
                    table.insert(its_no_change, it_path)
                    its_no_change[it_path]={fn=it_fn}
                end

                if not fns[it_fn] then

                    xml=xml..write_line([[<obj class="PAudioClip" name="AudioClip" ID="]]..idx['audioclip']..it_count..[[">]])

                    table.insert(fns, it_fn)
                    fns[it_fn]={idx=idx['audioclip']..it_count, arch=idx['fn']..it_count}

                    xml=xml..write_line([[<obj class="FNPath" name="Path" ID="]]..idx['path']..it_count..[[">]])
                    xml=xml..write_line([[<member name="FileType">]])
                    xml=xml..write_line([[<int name="MacType" value="1463899717"/>]])
                    xml=xml..write_line([[<string name="DosType" value="wav" wide="true"/>]])
                    xml=xml..write_line([[<string name="UnixType" value="wav" wide="true"/>]])
                    xml=xml..write_line([[<string name="Name" value="Wave File" wide="true"/>]])
                    xml=xml..write_line([[</member>]])
                    xml=xml..write_line([[</obj>]])

                    local shift_mode_tk=reaper.GetMediaItemTakeInfo_Value(tk, 'I_PITCHMODE')
                    if tk_pitch~=0 then
                        xml=xml..write_line([[<member name="Additional Attributes">]])
                        if shift_mode==720896 or shift_mode==524288 or shift_mode_tk==720896 or shift_mode_tk==524288 then
                            xml=xml..write_line([[<obj name="StretchPreset" ID="20180604"/>]])
                        else
                            xml=xml..write_line([[<obj name="StretchPreset" ID="19860111"/>]])
                        end
                        xml=xml..write_line([[</member>]])
                    end

                    local num_chan=reaper.GetMediaSourceNumChannels(sr)
                    local file_item=io.open(it_path, 'rb')
                    local content=file_item:read('*a')
                    file_item:close()
                    local bitsrate=string.unpack('I2', content:sub(35, 36))
                    local blockalign=num_chan*tonumber(bitsrate)/8
                    local totalsample=math.modf(len*spr)
                    local dataoffset=content:find('data')+7

                    xml=xml..write_line([[<obj class="AudioCluster" name="Cluster" ID="]]..idx['cluster']..it_count..[[">]])
                    xml=xml..write_line([[<list name="Substreams" type="obj">]])
                    xml=xml..write_line([[<obj class="AudioFile" ID="]]..idx['stream']..it_count..[[">]])
                    xml=xml..write_line([[<obj name="FPath" ID="]]..idx['path']..it_count..[["/>]])
                    xml=xml..write_line([[<int name="FrameCount" value="]]..totalsample..[["/>]])
                    xml=xml..write_line([[<int name="Sample Size" value="]]..bitsrate..[["/>]])
                    xml=xml..write_line([[<int name="Frame Size" value="]]..blockalign..[["/>]])
                    xml=xml..write_line([[<int name="Channels" value="]]..num_chan..[["/>]])
                    xml=xml..write_line([[<float name="Rate" value="]]..spr..[["/>]])
                    xml=xml..write_line([[<int name="Format" value="65536"/>]])
                    xml=xml..write_line([[<int name="ByteOrder" value="0"/>]])
                    xml=xml..write_line([[<int name="DataOffset" value="]]..dataoffset..[["/>]])
                    xml=xml..write_line([[<obj name="archivePath" ID="]]..idx['fn']..it_count..[["/>]])
                    xml=xml..write_line([[</obj>]])
                    xml=xml..write_line([[</list>]])
                    xml=xml..write_line([[<list name="Segments" type="list">]])
                    xml=xml..write_line([[<item>]])
                    xml=xml..write_line([[<obj name="Stream" ID="]]..idx['stream']..it_count..[["/>]])
                    xml=xml..write_line([[<int name="Offset" value="0"/>]])
                    xml=xml..write_line([[<int name="Length" value="]]..totalsample..[["/>]])
                    xml=xml..write_line([[<int name="Start" value="0"/>]])
                    xml=xml..write_line([[</item>]])
                    xml=xml..write_line([[</list>]])
                    xml=xml..write_line([[</obj>]])  --audiocluster结尾
                    xml=xml..write_line([[</obj>]])  --paudioclip结尾

                else

                    xml=xml..write_line([[<obj name="AudioClip" ID="]]..fns[it_fn].idx..[["/>]])

                end  --if not fns[it_fn]

                local fin=reaper.GetMediaItemInfo_Value(it, "D_FADEINLEN")
                if fin~=0 then write_fade(fin, 'in', spr, idx['fin']..it_count, idx['lin']..it_count) end
                local fout=reaper.GetMediaItemInfo_Value(it, "D_FADEOUTLEN")
                if fout~=0 then write_fade(fout, 'out', spr, idx['fout']..it_count, idx['lout']..it_count) end

                if tk_pitch~=0 then
                    xml=xml..write_line([[<member name="Additional Attributes">]])
                    xml=xml..write_line([[<float name="PitF" value="]]..2^(tk_pitch/12)..[["/>]])
                    xml=xml..write_line([[</member>]])
                end
                
                xml=xml..write_line([[</obj>]])  --MAudioEvent结尾

            end  --for j=0, num_it-1
            
            xml=xml..write_line([[</list>]])  --Events结尾
            xml=xml..write_line([[</obj>]])  --MListNode结尾
            xml=xml..write_line([[<obj class="MAudioTrack" name="Track Device" ID="]]..idx['dev']..i..[[">]])
            xml=xml..write_line([[<int name="Connection Type" value="1"/>]])
            xml=xml..write_line([[<string name="Device Name" value="VST Multitrack"/>]])
            xml=xml..write_line([[<int name="Channel ID" value="1"/>]])
            xml=xml..write_line([[<int name="Flags" value="0"/>]])
            xml=xml..write_line([[</obj>]])  --maudiotrack结尾
            xml=xml..write_line([[</obj>]])  --trackevent结尾

        end  --i=0, num_track-1
        
        xml=xml..write_line([[</list>]])  --name="track"结尾
        xml=xml..write_line([[<obj class="PArrangeSetup" name="Setup" ID="]]..os.date("%y")..os.date("%m")..os.date("%d")..[[">]])
        xml=xml..write_line([[<member name="Length">]])
        xml=xml..write_line([[<float name="Time" value="1200"/>]])
        xml=xml..write_line([[<member name="Domain">]])
        xml=xml..write_line([[<int name="Type" value="1"/>]])
        xml=xml..write_line([[<float name="Period" value="1"/>]])
        xml=xml..write_line([[</member>]])
        xml=xml..write_line([[</member>]])
        xml=xml..write_line([[<int name="BarOffset" value="0"/>]])
        xml=xml..write_line([[<int name="FrameType" value="3"/>]])
        xml=xml..write_line([[<int name="TimeType" value="1"/>]])
        xml=xml..write_line([[<float name="SampleRate" value="48000"/>]])
        xml=xml..write_line([[<int name="SampleSize" value="24"/>]])
        xml=xml..write_line([[<int name="SampleFormatSize" value="3"/>]])
        xml=xml..write_line([[<int name="PanLaw" value="6"/>]])
        xml=xml..write_line([[<int name="RecordFile" value="1"/>]])
        xml=xml..write_line([[<int name="VolumeMax" value="1"/>]])
        xml=xml..write_line([[<int name="HmtType" value="0"/>]])
        xml=xml..write_line([[<int name="HmtDepth" value="100"/>]])
        xml=xml..write_line([[</obj>]])  --parrangesetup结尾

        for i=1, #fns do

            xml=xml..write_line([[<obj class="FNPath" ID="]]..fns[fns[i]].arch..[[">]])
            xml=xml..write_line([[<string name="Name" value="]]..fns[i]:gsub('&', '&amp;')..[[" wide="true"/>]])
            xml=xml..write_line([[<string name="Path" value="" wide="true"/>]])
            xml=xml..write_line([[<member name="FileType">]])
            xml=xml..write_line([[<int name="MacType" value="1463899717"/>]])
            xml=xml..write_line([[<string name="DosType" value="wav" wide="true"/>]])
            xml=xml..write_line([[<string name="UnixType" value="wav" wide="true"/>]])
            xml=xml..write_line([[<string name="Name" value="Wave File" wide="true"/>]])
            xml=xml..write_line([[</member>]])
            xml=xml..write_line([[</obj>]])  --fnpath结尾

        end

        xml=xml..write_line([[<obj class="ElastiquePreset" ID="20180604">]])
        xml=xml..write_line([[<string name="processingMode" value="pro default" wide="true"/>]])
        xml=xml..write_line([[<string name="stereoMode" value="left-right" wide="true"/>]])
        xml=xml..write_line([[<int name="tapeStyleMode" value="1"/>]])
        xml=xml..write_line([[</obj>]])

        xml=xml..write_line([[<obj class="ElastiquePreset" ID="19860111">]])
        xml=xml..write_line([[<string name="processingMode" value="pro default" wide="true"/>]])
        xml=xml..write_line([[<string name="stereoMode" value="left-right" wide="true"/>]])
        xml=xml..write_line([[<int name="tapeStyleMode" value="0"/>]])
        xml=xml..write_line([[<int name="pitchAccurateMode" value="0"/>]])
        xml=xml..write_line([[</obj>]])

        tab=0
        xml=xml..write_line([[</tracklist>]])

        ---------------------------------------------------export track achive----------------------------------------------------
        local file=io.open(target_file, 'a')
        file:write(xml)
        file:close()
    
    --------------------------善后处理--------------------------
    
        reaper.SelectAllMediaItems(0, 1)
    
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
    
            --check_message()
    
        end

        local media_old=reaper.GetProjectPath('')
      
        reaper.Main_OnCommand(40860, 0)  -- close project
    
        reaper.SelectProjectInstance(proj)
    
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_FOCUS_TRACKS"), 0)  -- focus main

        local ret=os.rename(media_old, target_media)

        if not ret then reaper.MB('请检查\n'..media_old..'\n文件夹内是否有文件被其他程序锁定', '导出中止', 0) return end

        if #its_no_change>0 then

            for i=1, #its_no_change do

                copy_file(its_no_change[i], target_media..its_no_change[its_no_change[i]].fn)

            end

        end

        reaper.ExecProcess('cmd /c explorer select, \"'..path_nofilename:gsub('/', '\\')..'\"', 0)
    
    end
    
end