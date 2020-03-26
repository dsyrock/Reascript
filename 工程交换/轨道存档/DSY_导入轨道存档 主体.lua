function import_track_archieve(value, portable)
    
    local cursor=reaper.GetCursorPosition()	--获取光标位置
    reaper.Main_OnCommand(40749, 0)  --link loop point and ts
    local insert_state=0  --记录是否需要导入 0:不需要  1:需要

    function insert(its)

        if insert_state==0 then return end
        if its[#its].mute then return end
    
        local id=its[#its].id
        local file=its[id].path..its[id].fn
        if not reaper.file_exists(file) then
            file=portable..its[id].fn
        end
        if not reaper.file_exists(file) then msg(file) return end

        local start
        if its[#its].bpm then
            start=cursor+its[#its].start*60/its[#its].bpm/480
        else
            start=its[#its].start+cursor
        end
        reaper.SetEditCurPos(start, 0, 0)
        reaper.InsertMedia(file, 0)

        local it=reaper.GetSelectedMediaItem(0, 0)
        its[#its].it=it
        local tk=reaper.GetActiveTake(it)
        local spr=its[#its].spr
        reaper.SetMediaItemLength(it, its[#its].length/spr, 0)

        local vol=its[#its].vol
        if vol then reaper.SetMediaItemInfo_Value(it, 'D_VOL', its[#its].vol) end
        
        local offset=its[#its].offset
        if offset then
            reaper.SetMediaItemTakeInfo_Value(tk, 'D_STARTOFFS', offset/spr)
        end
    
        local pitch=its[#its].pitch
        if pitch then
            reaper.SetMediaItemTakeInfo_Value(tk, 'D_PITCH', pitch)
        end
    
        local fin=its[#its].fin
        if fin then
            reaper.SetMediaItemInfo_Value(it, "D_FADEINLEN", fin/spr)
        end
    
        local fout=its[#its].fout
        if fout then
            reaper.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", fout/spr)
        end

        if its[#its].rev then reaper.Main_OnCommand(41051, 0) end  --reverse
    
        insert_state=0

        reaper.SelectAllMediaItems(0, 0)
    
    end
    
    function get_value(line)
        return line:match('value=\"([^\"]+)\"')
    end
    
	reaper.SelectAllMediaItems(0, 0)

    local tr  --轨道
    local state  --当前处于哪个字段下
    local its={}  --item表
    its['mode']={}  --变调算法表
    its['rev']={}  --记录item反转数据
    local id_last  --文件名临时编号
    local mode_id_last  --变调模式临时编号
    local bpm  --记录bpm
    local tr_type  --记录轨道模式
    local marker={}  --marker表
    local audiofile_count=0  --出现第几个audiofile_count

	for line in io.lines(value) do

        if line:find('creat by DSY') then --防止导入reaper生成的轨道存档

            reaper.MB('仅限Cubase/Nuendo生成的轨道存档', '操作失败', 0)
            break
            return false
    
        elseif line:find('MAudioTrackEvent') then  --找到轨道事件
            
            insert(its)  --把上一个记录到的item导入
            state='tr'
            reaper.Main_OnCommand(40702, 0)  --建立轨道
            tr=reaper.GetSelectedTrack(0, 0)

        elseif line:find('float name=\"RehearsalTempo\"') then  --找到bpm
            
            bpm=get_value(line)

        elseif line:find('MListNode') then  --找到MListNode
            
            if state=='tr' then state='mlistnode' end

        elseif line:find('int name=\"Type\"') then  --找到轨道模式
            
            if state=='mlistnode' then
                tr_type=get_value(line)
            end

		elseif line:find('string name=\"Name\"') then  

            if state=='mlistnode' then  --找到轨道名字参数
                reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", get_value(line), 1)
--            elseif state=='it' then  --找到item名字参数
--                its[#its].name=get_value(line)
            elseif state=='fnpath' then  --找到文件名相关参数
                its[id_last].fn=get_value(line):gsub('amp;', '')
            elseif state=='marker' then  --找到marker名字
                local name=get_value(line)
                if not name then name=' ' end
                marker[#marker].name=name
            end

        elseif line:find('MAudioEvent') then  --找到新item数据

            insert(its)
            its[#its+1]={}
            state='it'
            insert_state=1

            if tr_type=='0' then its[#its].bpm=bpm end

        elseif line:find('float name=\"Start\"') then  

            local v=tonumber(get_value(line))
            if state=='it' then  --找到起始位置数据
                its[#its].start=v
            elseif state=='marker' then  --找到marker起始位置数据
                marker[#marker].pos=v
            end

        elseif line:find('float name=\"Length\"') then  --找到长度数据 单位:采样

            if state=='it' then
                its[#its].length=tonumber(get_value(line))
            end

        elseif line:find('float name=\"Offset\"') then  --找到offset数据 单位:采样

            if state=='it' then
                its[#its].offset=tonumber(get_value(line))
            end

        elseif line:find('float name=\"Volume\"') then  --找到音量数据

            if state=='it' then
                its[#its].vol=tonumber(get_value(line))
            end

        elseif line:find('int name=\"Flags\"') then  --找到mute数据

            if state=='audioclip' or state=='cluster' then
                if get_value(line)=='2' then its[#its].mute=true end
            end

        elseif line:find('int name=\"Inverted\"') then  --item段结束

            state='itend'
            audiofile_count=0

        elseif line:find('obj class=\"AudioFile\"') then  --找到AudioFile数据

            audiofile_count=audiofile_count+1
            if audiofile_count==2 then
                its['rev'][id_last]=0
                its[#its].rev=true
            end

        elseif line:find('name=\"AudioClip\"') then  --找到PAudioClip 路径ID

            state='audioclip'
            
            local id=line:match('ID=\"([^\"]+)\"')
            its[#its].id=id
            id_last=id
            
            if not its[id] then
                its[id]={} 
            else
                its[#its].spr=its[id_last].spr
            end
            
            if its['rev'][id_last] then its[#its].rev=true end

        elseif line:find('class=\"FNPath\"') then  --找到路径相关数据

            if state=='audioclip' then
                state='fnpath'
            end

        elseif line:find('name=\"Path\"') then  --找到路径

            if state=='fnpath' then
                its[id_last].path=get_value(line)
            end

        elseif line:find('name=\"FileType\"') then  --找到filetype
            
            state='filetype'  --区分路径和文件类型

        elseif line:find('name=\"StretchPreset\"') then  --找到变调算法

            local id=line:match('ID=\"([^\"]+)\"') 
            its[#its].mode=id
            its[id_last].mode=id
            if not its['mode'][id] then its['mode'][id]=0 end
            --if not mode[id] then mode[id]=0 end

        elseif line:find('name=\"Cluster\"') then  --找到cluster相关数据

            state='cluster'

        elseif line:find('float name=\"Rate\"') then  --找到item采样率

            local spr=tonumber(get_value(line))
            its[#its].spr=spr
            its[id_last].spr=spr

        elseif line:find('obj class=\"MFadeIn\"') then  --找到item淡入数据

            state='fadein'

        elseif line:find('float name=\"XMax\"') then  --找到淡入淡出长度

            if state=='fadein' then

                its[#its].fin=tonumber(get_value(line))

            elseif state=='fadeout' then

                its[#its].fout=tonumber(get_value(line))

            end

        elseif line:find('obj class=\"MFadeOut\"') then  --找到item淡出数据

            state='fadeout'

        elseif line:find('float name=\"PitF\"') then  --找到pitch数据

            local pitf=tonumber(get_value(line))
            its[#its].pitch=math.log(pitf, 2)*12

        elseif line:find('obj class=\"PArrangeSetup\"') then  --轨道结束

            insert(its)
            state='end'

        elseif line:find('obj class=\"ElastiquePreset\"') then  --找到变调模式设置

            mode_id_last=line:match('ID=\"([^\"]+)\"')

        elseif line:find('int name=\"tapeStyleMode\"') then  --找到变调模式设置

            if get_value(line)=='1' then
                its['mode'][mode_id_last]=720896
            else
                its['mode'][mode_id_last]=589824
            end

        elseif line:find('obj class=\"MMarkerEvent\"') then  --找到marker数据

            state='marker'
            marker[#marker+1]={}

        elseif line:find('int name=\"ID\"') then
            if state=='marker' then  --找到marker编号数据
                marker[#marker].idx=get_value(line)
            end
        end

    end

    for i=1, #its do
        if not its[i].mute then reaper.SetMediaItemSelected(its[i].it, 1) end
        local pitch=its[i].pitch
        if pitch then
            local mode_id=its[i].mode
            if not mode_id then
                local id=its[i].id
                mode_id=its[id].mode
            end
            local tk=reaper.GetActiveTake(its[i].it)
            reaper.SetMediaItemTakeInfo_Value(tk, 'I_PITCHMODE', its['mode'][mode_id])
        end
    end

    if #marker>0 then
        for k, v in pairs(marker) do
            reaper.AddProjectMarker(0, 0, v.pos+cursor, 0, v.name, v.idx)
        end
    end

    return true

end