local debug="on"

function msg(value)

  if debug=="on" then reaper.ShowConsoleMsg(tostring(value) .. "\n") end

end

function get_take_file(tk)  --获取take源文件路径

    local sr=reaper.GetMediaItemTake_Source(tk)

    local psr = reaper.GetMediaSourceParent(sr)

    if psr then sr = psr end

    local sr_file=reaper.GetMediaSourceFileName(sr, "")

    return sr, sr_file

end

local path_dll=reaper.GetResourcePath().."\\UserPlugins\\fileops.dll"

if not reaper.file_exists(path_dll) then reaper.MB("请先拷贝fileops.dll文件到UserPlugins文件夹", "提示", 0) return end

local copyFile = package.loadlib(path_dll, "copyFile")

local last_mod=package.loadlib(path_dll, "getLastModified")

local peaks={}

function copy_peak(path_peak, path_only, name, it)

    local peak_des=path_only.."peaks/"..name..".reapeaks"

    if reaper.file_exists(path_peak) and not reaper.file_exists(peak_des) then
    
        local peak_sr=path_peak

        copyFile(peak_sr, peak_des)

    else

        table.insert(peaks, it)

    end

end

function random_name(name, files)

    local time=0

    while true do

        time=time+1

        local date=math.modf(os.clock()).."_"..math.random(1,9999)

        if time>=100 then date=date.."_"..math.random(1,9999) end
    
        name=name:gsub("(.+)(%..+)", "%1".."_"..date.."%2")

        if not files[name] then break end
    
    end

    return name

end

function copy_new(name, sr_file, path, tk, files)

    local name_new=random_name(name, files)

    local copy_source=sr_file

    local copy_des=path.."\\"..name_new

    copyFile(copy_source, copy_des)

    reaper.BR_SetTakeSourceFromFile(tk, copy_des, true)

    return name_new, copy_des

end

function DSY_get_content(path)

    local file=io.open(path, "rb")

    local content = file:read("*a")

    file:close()

    return content

end

function byname(t1, t2)

    return t1.name<t2.name

end

function byname_only(t1, t2)

    return t1<t2

end

function copy_to_project()

    local num=reaper.CountSelectedMediaItems(0)

    if num==0 then return end

    local peak_setting=reaper.SNM_GetIntConfigVar("altpeaks", -1)
    
    local index, files, files_copy, section=0, {}, {}, {}

    local path=reaper.GetProjectPath("")

    local path_local=path.."\\"

    while true do  --保存本地文件列表

        local file=reaper.EnumerateFiles(path, index)

        if file then

            table.insert(files, file)         --保存纯文件名 作为排序依据

            files[file]=file

            index=index+1

        else

            break

        end

    end

    for i=0, num-1 do  --保存待复制文件列表

        local it=reaper.GetSelectedMediaItem(0, i)

        local _, state=reaper.GetItemStateChunk(it, "", true)

        local tk=reaper.GetActiveTake(it)

        if tk then

            local sr=reaper.GetMediaItemTake_Source(tk)

            local type_name=reaper.GetMediaSourceType(sr, "")

            if type_name~="MIDI" then

                local sr, sr_file=get_take_file(tk)

                local path_only=sr_file:match("(.+[/\\])[^/\\]*%.%w+$")
                
                local name=sr_file:match(".+[/\\]([^/\\]+)")

                local peak=reaper.GetPeakFileName(sr_file, "")
            
                files_copy[#files_copy+1]={it=it, tk=tk, path=sr_file, path_only=path_only, name=name, peak=peak}

                if state:find("<SOURCE SECTION") then section[it]=state:match('(<SOURCE SECTION.+)<SOURCE') end  --把打开了section开关的item记录下来

            end

        end

    end

    if #files_copy>0 then 

        local done={}

        for k, v in pairs(files_copy) do  --从待复制文件列表里循环

            reaper.SetMediaItemSelected(v.it, true)

            local copy_mode="normal"

            if v.path_only~=path_local then   --item文件不在工程内

                if done[v.path] then    --已经有同样的文件完成了复制，直接指向新路径

                    reaper.BR_SetTakeSourceFromFile(v.tk, done[v.path], true)

                    copy_mode="no"

                else

                    if #files>0 then

                        if files[v.name] then   --如果遇到重名

                            local path_ori=path_local..v.name

                            if DSY_get_content(path_ori)==DSY_get_content(v.path) then --如果文件内容相同

                                reaper.BR_SetTakeSourceFromFile(v.tk, path_ori, true)

                                copy_mode="no"

                                done[v.path]=path_ori

                            else    --文件内容不同

                                copy_mode="new"

                                local name_new, path_new=copy_new(v.name, v.path, path, v.tk, files)

                                done[v.path]=path_new

                                files[name_new]=name_new

                                if peak_setting==4 or peak_setting==6 then copy_peak(v.peak, path_local, name_new, v.it) end

                            end

                        end

                    end
                    
                    if copy_mode=="normal" then

                        local copy_source=v.path

                        local copy_des=path_local..v.name

                        copyFile(copy_source, copy_des)

                        reaper.BR_SetTakeSourceFromFile(v.tk, copy_des, true)

                        done[v.path]=copy_des

                        files[v.name]=v.name

                        if peak_setting==4 or peak_setting==6 then copy_peak(v.peak, path_local, v.name, v.it) end
                        
                    end

                end

                if section[v.it] then

                    local _, chunk=reaper.GetItemStateChunk(v.it, '', 1)

                    local head, mid, tail=chunk:match('(.+)(<SOURCE[^>]+)(.+)')

                    reaper.SetItemStateChunk(v.it, head..section[v.it]..mid..'>\n'..tail, 1)

                end

            end
            
        end

    end

    reaper.Main_OnCommand(41858, 0)  -- set take name from file

    if peak_setting==4 or peak_setting==6 then

        reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_TOGGLE_ITEM_ONLINE"), 0)

        reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_TOGGLE_ITEM_ONLINE"), 0)
        
        if #peaks>0 then

            reaper.SelectAllMediaItems(0, 0)
    
            for k, v in pairs(peaks) do
    
                reaper.SetMediaItemSelected(v, 1)
    
            end
    
            reaper.Main_OnCommand(40441, 0)  -- rebuild peaks
    
        end
    
    else

        reaper.Main_OnCommand(40441, 0)  -- rebuild peaks

    end

    reaper.UpdateArrange()

    
end

reaper.Undo_BeginBlock()

local time=os.time()

copy_to_project()

--reaper.MB("本次复制用时: "..(os.time()-time), "Done", 0)
reaper.Undo_EndBlock("复制媒体文件到工程目录", -1)     