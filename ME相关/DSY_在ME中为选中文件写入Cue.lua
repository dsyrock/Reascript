--[[
ReaScript Name: 在ME中为选中文件写入Cue
Version: 1.0
Author: noiZ
]]

function msg(value)
    reaper.ShowConsoleMsg(tostring(value) .. '\n')
end

function write_cue_to_file(filename, time)  --modified from amagalma: Write project markers as media cues to selected items active takes source files.lua
    local sr=reaper.PCM_Source_CreateFromFile(filename)
    local samplerate=reaper.GetMediaSourceSampleRate(sr)
    reaper.PCM_Source_Destroy(sr)

    local projsrate
    local projoffset = reaper.GetProjectTimeOffset( 0, false )
    if reaper.SNM_GetIntConfigVar( "projsrateuse", 0 ) == 1 then 
        projsrate = reaper.SNM_GetIntConfigVar( "projsrate", 0 )
    else
        _, projsrate = reaper.GetAudioDeviceInfo( "SRATE", "" )
        projsrate = tonumber(projsrate)
    end

    local function escape_lua_pattern(s)
        local matches =
        {
            ["^"] = "%^";
            ["$"] = "%$";
            ["("] = "%(";
            [")"] = "%)";
            ["%"] = "%%";
            ["."] = "%.";
            ["["] = "%[";
            ["]"] = "%]";
            ["*"] = "%*";
            ["+"] = "%+";
            ["-"] = "%-";
            ["?"] = "%?";
            ["\0"] = "%z";
        }
        return (s:gsub(".", matches))
    end
    ----------------------------------
    local function pairsByKeys (t, f) -- https://www.lua.org/pil/19.3.html
        local a = {}
        for n in pairs(t) do table.insert(a, n) end
        table.sort(a, f)
        local i = 0 -- iterator variable
        local iter = function () -- iterator function
                i = i + 1
                if a[i] == nil then return nil
                else return a[i], t[a[i]]
                end
            end
        return iter
    end 
    ----------------------------------
    local function pack(number)
        return string.pack("I", number)
    end
    ----------------------------------
    local function unpack(number)
        return string.unpack("I", number)
    end
    ----------------------------------
    local function len(str)
        return string.len(str)
    end
    ----------------------------------
    local function sample_pos(n)
        return tonumber(reaper.format_timestr_pos( n, "", 4 ))
    end

    if not reaper.file_exists(filename) then return end

    local markers_to_write = 0
    local items = {}

    local file = io.open(filename, "rb")
    local head=file:read(4)
    if head~='RIFF' then
        file:close()
        return
    end
    file:seek('set')  --from beginning
    file:seek("cur", 4) -- riff_header
    local file_size_buf = file:read(4)
    local file_size = unpack(file_size_buf)
    local wave_header = file:read(4)
    if string.lower(wave_header) == "wave" then -- Is WAV
        -- find which markers are inside the visible source file portion
        local markers_inside = {}
        local marker_cnt = 0

        local tocopy = {} -- odd numbers = "from", even numbers = "to"
        tocopy[1] = 8
        -- check if any media cues are present in the source
        local cue_chunk_found, list_chunk_found = 0, 0
        local cue_chunk_start, cue_chunk_end, list_chunk_start, list_chunk_end
        local data_start, data_end, data_size
        local present_markers = {}
        while (cue_chunk_found == 0 or list_chunk_found == 0) and file:seek() < file_size do
            local chunk_start = file:seek()
            local chunk_header = file:read(4)
            local chunk_size_buf = file:read(4)
            local chunk_size = unpack(chunk_size_buf)
            if chunk_size % 2 ~= 0 then -- odd, add padding
                chunk_size = chunk_size + 1
            end
            
            if string.lower(chunk_header) == "cue " then
                cue_chunk_start = chunk_start
                -- find present markers in item
                local cue_points_cnt = unpack(file:read(4))
                for cp = 1, cue_points_cnt do
                    local ID = unpack(file:read(4))
                    file:seek("cur", 16)
                    local Sample_Offset = unpack(file:read(4))
                    present_markers[ID] = {pos = Sample_Offset, name = ""}
                    marker_cnt = marker_cnt + 1
                end
                cue_chunk_end = cue_chunk_start + 8 + chunk_size
                if #tocopy % 2 ~= 0 then -- odd ("from"), set "to"
                    tocopy[#tocopy+1] = cue_chunk_start
                else -- even, set new "to"
                    if tocopy[#tocopy] == cue_chunk_start then
                        tocopy[#tocopy+1] = cue_chunk_end
                    end
                end
                file:seek("set", cue_chunk_end)
                cue_chunk_found = 1
            elseif string.lower(chunk_header) == "list" then
                    list_chunk_start = chunk_start
                    file:seek("cur", 4) -- "adtl"
                    while file:seek() < chunk_start + chunk_size + 8 do
                        local chunk_id = file:read(4)
                        if string.lower(chunk_id) == "labl" or string.lower(chunk_id) == "note" then
                            local lbl_chunk_data_size = unpack(file:read(4))
                            local lbl_cue_point_id = unpack(file:read(4))
                            present_markers[lbl_cue_point_id].name = file:read(lbl_chunk_data_size-5)
                            if lbl_chunk_data_size % 2 == 0 then -- even, add null termination only
                                file:seek("cur", 1)
                            else -- odd, add padding and null termination
                                file:seek("cur", 2)
                            end
                        elseif string.lower(chunk_id) == "ltxt" then
                            -- not supported
                        end
                    end
                    list_chunk_end = list_chunk_start + 8 + chunk_size
                    if #tocopy % 2 ~= 0 then -- odd ("from"), set "to"
                        tocopy[#tocopy+1] = list_chunk_start
                    else -- even, set new "to"
                        if tocopy[#tocopy] == list_chunk_start then
                            tocopy[#tocopy+1] = list_chunk_end
                        end
                    end
                    file:seek("set", list_chunk_end)
                    list_chunk_found = 1
            elseif string.lower(chunk_header) == "data" then
                data_start = chunk_start
                data_size = chunk_size + 8
                data_end = file:seek("cur", chunk_size)
                if #tocopy % 2 ~= 0 then -- odd ("from"), set "to"
                    tocopy[#tocopy+1] = data_end
                else -- even, set new "to"
                    tocopy[#tocopy] = data_end
                end
            else -- move on
                local chunk_end = file:seek("cur", chunk_size)
                if #tocopy % 2 ~= 0 then -- odd ("from"), set "to"
                    tocopy[#tocopy+1] = chunk_end
                else -- even, set new "to"
                    tocopy[#tocopy] = chunk_end
                end
            end
        end
        if tocopy[#tocopy] == tocopy[#tocopy-1] then
            tocopy[#tocopy] = nil
            tocopy[#tocopy] = nil
        end
        -- add present markers (cues) that are not on the same position as (new) project markers
        for pm = 1, #present_markers do
            markers_inside[present_markers[pm].pos] = present_markers[pm].name
        end
        -- find which markers are inside the visible source start and length
        local max_mrk_pos, min_mrk_pos = 0, false
        local new_item_markers = 0

        local pos = sample_pos(time*(samplerate/projsrate)) - projoffset*projsrate-- position in samples  time是我的修改
        -- it's inside, check if it is new
        if not markers_inside[pos] then
            -- new marker, add
            markers_inside[pos] = ''
            markers_to_write = markers_to_write + 1
            new_item_markers = new_item_markers + 1
            marker_cnt = marker_cnt + 1
            -- store min & max position of markers
            if not min_mrk_pos then
                min_mrk_pos, max_mrk_pos = pos, pos
            elseif pos > max_mrk_pos then
                max_mrk_pos = pos
            end
        else
            -- exists, check if it brings a new name. If blank then erase
            markers_inside[pos] = nil
            markers_to_write = markers_to_write + 1
            new_item_markers = new_item_markers + 1
            marker_cnt = marker_cnt - 1
            -- store min & max position of markers
            if not min_mrk_pos then
                min_mrk_pos, max_mrk_pos = pos, pos
            elseif pos > max_mrk_pos then
                max_mrk_pos = pos
            end
        end

        items[#items+1] =
        {
        marker = markers_inside,
        file = filename,
        new_markers = new_item_markers,
        mrk_cnt = marker_cnt,
        copy = tocopy
        }    
    end

    file:close()

    -- CREATE NEW SOURCE FILES --
    reaper.PreventUIRefresh( 1 )

    local file = io.open(filename, "rb")
    local newfile = io.open(filename .. "cue", "wb")
    newfile:write("RIFF    ")
    for j = 1, #items[1].copy-1, 2 do
        local START = items[1].copy[j]
        local END = items[1].copy[j+1]
        file:seek("set", START)
        if END - START < 2000000 then -- smaller than 2MB
            newfile:write(file:read(END-START))
        else -- bigger than 2MB
            -- read 2MB chunks at a time
            while file:seek() < END do
                if END - file:seek() > 2000000 then
                    newfile:write(file:read(2000000))
                else
                    newfile:write(file:read(END-file:seek()))
                end
            end
        end
    end
    if items[1].mrk_cnt > 0 then -- cue and list chunks will exist
        local cue_chunk = {}
        local list_chunk = {}
        cue_chunk[1] = "cue " -- Chunk ID
        cue_chunk[2] = pack((items[1].mrk_cnt * 24) + 4) -- Chunk Data Size
        cue_chunk[3] = pack(items[1].mrk_cnt) -- Num Cue Points
        list_chunk[1] = "" -- reserved for later (Chunk ID)
        list_chunk[2] = "" -- reserved for later (Chunk Data Size)
        list_chunk[3] = "adtl" -- Type ID
        local ID = 0
        for pos,name in pairsByKeys(items[1].marker) do
            ID = ID + 1
            -- create cue chunk table
            cue_chunk[#cue_chunk+1] = pack(ID) -- ID
            cue_chunk[#cue_chunk+1] = pack("0") -- Position
            cue_chunk[#cue_chunk+1] = "data" -- Data Chunk ID
            cue_chunk[#cue_chunk+1] = pack("0") -- Chunk Start
            cue_chunk[#cue_chunk+1] = pack("0") -- Block Start
            cue_chunk[#cue_chunk+1] = pack(pos) -- Sample Offset
            -- create list chunk table
            list_chunk[#list_chunk+1] = "labl" -- Chunk ID
            local final_name = name .. "\0"
            list_chunk[#list_chunk+1] = pack(len(final_name) + 4) -- Chunk Data Size
            list_chunk[#list_chunk+1] = pack(ID) -- Cue Point ID
            if len(final_name) % 2 ~= 0 then -- odd, add padding
                final_name = final_name .. "\0"
            end
            list_chunk[#list_chunk+1] = final_name -- Text
        end
        local list_chunk_size = len(table.concat(list_chunk))
        list_chunk[2] = pack(list_chunk_size) -- Chunk Data Size
        list_chunk[1] = "list" -- ID
        local new_cue_chunk = table.concat(cue_chunk)
        local new_list_chunk = table.concat(list_chunk)
        newfile:write(new_cue_chunk)
        newfile:write(new_list_chunk)
    end
    local new_file_size = newfile:seek("end") - 8
    newfile:seek("set", 4)
    newfile:write(pack(new_file_size)) -- Chunk Data Size
    file:close()
    newfile:close()
    -- file substitution
    os.remove(filename) -- delete original file
    os.rename(filename .. "cue", filename) -- rename temporary file as original
end

function MediaExplorer_GetSelectedAudioFiles(hwnd)  --FeedTheCat:Link media explorer to active sample player.lua

    function IsAudioFile(file)
        local ext = file:match('%.([^.]+)$')
        if ext and reaper.IsMediaExtension(ext, false) then
            ext = ext:lower()
            if ext ~= 'xml' and ext ~= 'mid' and ext ~= 'rpp' then
                return true
            end
        end
    end
      
    local show_full_path = reaper.GetToggleCommandStateEx(32063, 42026) == 1
    local show_leading_path = reaper.GetToggleCommandStateEx(32063, 42134) == 1
    local forced_full_path = false
  
    local path_hwnd = reaper.JS_Window_FindChildByID(hwnd, 1002)
    local path = reaper.JS_Window_GetTitle(path_hwnd)
  
    local mx_list_view = reaper.JS_Window_FindChildByID(hwnd, 1001)
    local _, sel_indexes = reaper.JS_ListView_ListAllSelItems(mx_list_view)
  
    local sep = package.config:sub(1, 1)
    local sel_files = {}
  
    for index in string.gmatch(sel_indexes, '[^,]+') do
        index = tonumber(index)
        local file_name = reaper.JS_ListView_GetItem(mx_list_view, index, 0)
        -- File name might not include extension, due to MX option
        local ext = reaper.JS_ListView_GetItem(mx_list_view, index, 3)
        if not file_name:match('%.' .. ext .. '$') then
            file_name = file_name .. '.' .. ext
        end
        if IsAudioFile(file_name) then
            -- Check if file_name is valid path itself (for searches and DBs)
            if not reaper.file_exists(file_name) then
                file_name = path .. sep .. file_name
            end
  
            -- If file does not exist, try enabling option that shows full path
            if not show_full_path and not reaper.file_exists(file_name) then
                show_full_path = true
                forced_full_path = true
                -- Browser: Show full path in databases and searches
                reaper.JS_WindowMessage_Send(hwnd, 'WM_COMMAND', 42026, 0, 0, 0)
                file_name = reaper.JS_ListView_GetItem(mx_list_view, index, 0)
            end
  
            -- Check if file_name is valid path itself (for searches and DBs)
            if not reaper.file_exists(file_name) then
                file_name = path .. sep .. file_name
            end
            sel_files[#sel_files + 1] = file_name
        end
    end
  
    -- Restore previous settings
    if forced_full_path then
        -- Browser: Show full path in databases and searches
        reaper.JS_WindowMessage_Send(hwnd, 'WM_COMMAND', 42026, 0, 0, 0)
  
        if show_leading_path then
            -- Browser: Show leading path in databases and searches
            reaper.JS_WindowMessage_Send(hwnd, 'WM_COMMAND', 42134, 0, 0, 0)
        end
    end
  
    return sel_files
end

function MediaExplorer_GetTimeSelection(hwnd)  --FeedTheCat:Link media explorer to active sample player.lua
    -- If a time selection exists, it will be shown in the wave info window
    local wave_info_hwnd = reaper.JS_Window_FindChildByID(hwnd, 1014)
    local wave_info = reaper.JS_Window_GetTitle(wave_info_hwnd)
    local pattern = ': ([^%s]+) .-: ([^%s]+)'
    local start_timecode, end_timecode = wave_info:match(pattern)
  
    if not start_timecode then return false end
  
    -- Convert timecode to seconds
    local start_mins, start_secs = start_timecode:match('^(.-):(.-)$')
    start_secs = tonumber(start_secs) + tonumber(start_mins) * 60
  
    local end_mins, end_secs = end_timecode:match('^(.-):(.-)$')
    end_secs = tonumber(end_secs) + tonumber(end_mins) * 60
  
    -- Note: When no media file is loaded, start and end are both 0
    return start_secs, end_secs
end

function create_time_selection_in_ME(hwnd)
    local waveform = reaper.JS_Window_FindChildByID(hwnd, 1046)
    local wave_info_hwnd = reaper.JS_Window_FindChildByID(hwnd, 1014)
    local x, y=reaper.GetMousePosition()
    x1, y1 = reaper.JS_Window_ScreenToClient(waveform, x, y )
    reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 1008, 0, 0, 0)  --play
    reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 1010, 0, 0, 0)  --pause
    reaper.JS_WindowMessage_Send(waveform, 'WM_LBUTTONDOWN', 0, 0, x1, y1)
    function draging()
        x1=x1+1
        reaper.JS_WindowMessage_Send(waveform, "WM_MOUSEMOVE", 1, 0, x1, y1)
        local title=reaper.JS_Window_GetTitle(wave_info_hwnd)
        if title:match('start') then
            reaper.JS_WindowMessage_Send(waveform, 'WM_LBUTTONUP', 0, 0, x1, y1)
            return
        end
        reaper.defer(draging)
    end
    draging()
end

local meTitle = reaper.JS_Localize('Media Explorer', 'common')
local hwnd = reaper.JS_Window_Find(meTitle, true)
create_time_selection_in_ME(hwnd)
function wait_until_ts_created()
    local pos=MediaExplorer_GetTimeSelection(hwnd)
    if pos then
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 1009, 0, 0, 0)  --stop
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 1009, 0, 0, 0)  --stop
        local files=MediaExplorer_GetSelectedAudioFiles(hwnd)

        local pathOri=files[1]
        write_cue_to_file(pathOri, pos)
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 40018, 0, 0, 0)  --刷新
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 1008, 0, 0, 0)  --play
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 1010, 0, 0, 0)  --pause
        return
    end
    reaper.defer(wait_until_ts_created)
end
wait_until_ts_created()