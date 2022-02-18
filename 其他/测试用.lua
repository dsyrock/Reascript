--@description dsytest
--@version 1.0
--@author noiZ
--@provides [nomain] .
function msg(value)

  reaper.ShowConsoleMsg(tostring(value) .. "\n")

end

it=reaper.GetSelectedMediaItem(0, 0)

if it then

    tk=reaper.GetActiveTake(it)

    pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")

    length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")

    itend=pos+length

    vol=reaper.GetMediaItemInfo_Value(it, "D_VOL")

    db=math.log(vol,10)*20

    snapoffset=reaper.GetMediaItemInfo_Value(it, "D_SNAPOFFSET")

    fadeinlen=reaper.GetMediaItemInfo_Value(it, "D_FADEINLEN")

    fadeoutlen=reaper.GetMediaItemInfo_Value(it, "D_FADEOUTLEN")

    fadeindir=reaper.GetMediaItemInfo_Value(it, "D_FADEINDIR")

    fadeoutdir=reaper.GetMediaItemInfo_Value(it, "D_FADEOUTDIR")

    fadeinlenauto=reaper.GetMediaItemInfo_Value(it, "D_FADEINLEN_AUTO")

    fadeoutlen=reaper.GetMediaItemInfo_Value(it, "D_FADEOUTLEN_AUTO")

    fadeinshape=reaper.GetMediaItemInfo_Value(it, "C_FADEINSHAPE")

    fadeoutshape=reaper.GetMediaItemInfo_Value(it, "C_FADEOUTSHAPE")

    _,state=reaper.GetItemStateChunk(it, "", true)

    if tk then

        source=reaper.GetMediaItemTake_Source(tk)

        filename=reaper.GetMediaSourceFileName(source, "")

        offset=reaper.GetMediaItemTakeInfo_Value(tk, "D_STARTOFFS")

        rate=reaper.GetMediaItemTakeInfo_Value(tk, "D_PLAYRATE")

        orilen=reaper.GetMediaSourceLength(source)

        sourcetype=reaper.GetMediaSourceType(source, "")

    end

end

min_freq = 80
max_freq = 1000
Thresh_dB = -40
min_tonal = 0.85

------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values ---------------
    local Wnd_bgd = 0x0F0F0F  
    local Wnd_Title = "Test"
    local Wnd_Dock,Wnd_X,Wnd_Y = 0,100,320 
    Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)
    -- Init window ------
    gfx.clear = Wnd_bgd         
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )  
end

------------------------------------------------------------
function Peaks_Draw(Peaks)
  local min_note = 69 + 12 * math.log(min_freq/440, 2)
  local max_note = 69 + 12 * math.log(max_freq/440, 2)
  local Thresh = 10 ^ (Thresh_dB/20)
  ----------------------
  local axis = gfx.h * 0.5
  local Ky = gfx.h * 0.5
  local Kn = gfx.h/(max_note-min_note)
  local offs = min_note * Kn
  ----------------------
  local abs, max = math.abs, math.max
  for i = 1, #Peaks, 4 do
    local max_peak, min_peak = Peaks[i], Peaks[i+1]
    local xx = i/4
    gfx.set(0,0.5,0,1)
    gfx.line(xx , axis - max_peak*Ky, xx, axis - min_peak*Ky, true) -- Peaks   
    -------------------- 
    if max(abs(max_peak), abs(min_peak)) > Thresh then
      local freq, tonal = Peaks[i+2], Peaks[i+3]
      local note = 69 + 12 * math.log(freq/440, 2)  
      if tonal >= min_tonal and note >= min_note and note <= max_note then
        gfx.x = xx gfx.y = gfx.h + offs - note*Kn
        gfx.setpixel(1,0,0)
      elseif note < min_note then
        gfx.x = xx gfx.y = gfx.h - 10
        gfx.setpixel(0,0,1)
      elseif note > max_note then
        gfx.x = xx gfx.y = 10
        gfx.setpixel(0,1,1)
      end
    end
  end
   
end
------------------------------------------------------------
function Item_GetPeaks(item)
  if not item then return end
  local take = reaper.GetActiveTake(item)
  if not take or reaper.TakeIsMIDI(take) then return end
  local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if sel_end - sel_start == 0 then sel_start = item_start sel_end = item_start + item_len end
  
  local starttime = math.max(sel_start, item_start)
  local len = math.min(sel_end, item_start + item_len) - starttime
  if len <= 0 then return end 
  ------------------
  --PCM_Source = reaper.GetMediaItemTake_Source(take)
  local n_chans = 1   -- I GetPeaks Only from 1 channel!!!
  local peakrate = gfx.w / len
  local n_spls = math.floor(len*peakrate + 0.5) -- its Peak Samples         
  local want_extra_type = 115  -- 's' char
  local buf = reaper.new_array(n_spls * n_chans * 3) -- max, min, spectral each chan(but now 1 chan only)
  buf.clear()         -- Clear buffer
  ------------------
  local retval = reaper.GetMediaItemTake_Peaks(take, peakrate, starttime, n_chans, n_spls, want_extra_type, buf)
  local spl_cnt  = (retval & 0xfffff)        -- sample_count
  local ext_type = (retval & 0x1000000)>>24  -- extra_type was available
  local out_mode = (retval & 0xf00000)>>20   -- output_mode
  ------------------
  local Peaks = {}
  if spl_cnt > 0 then
  -- if spl_cnt > 0 and ext_type > 0 then
    for i = 1, n_spls do
      local p = #Peaks
      Peaks[p+1] = buf[i]             -- max peak
      Peaks[p+2] = buf[n_spls + i]    -- min peak
      --------------
      local spectral = buf[n_spls*2 + i]    -- spectral peak
      -- freq and tonality from spectral peak --
      Peaks[p+3] = spectral&0x7fff       -- low 15 bits frequency
      Peaks[p+4] = (spectral>>15)/16384  -- tonality norm value 
    end
  end
  ------------------
  return Peaks
end

---------------------------
function Project_IsChanged()
    local cur_cnt = reaper.GetProjectStateChangeCount(0)
    if cur_cnt ~= proj_change_cnt then proj_change_cnt = cur_cnt
       return true  
    end
end

---------------------------
function main()    
    if Project_IsChanged() then
      gfx.setimgdim(0, 0, 0) -- clear buf 0
      gfx.setimgdim(0, gfx.w, gfx.h)
      gfx.dest = 0 -- set dest buf = 0   
      local item = reaper.GetSelectedMediaItem(0, 0) 
      if item then
        local Peaks = Item_GetPeaks(item)
        if Peaks then Peaks_Draw(Peaks) end
      end 
    end
    -----------
    local img_w, img_h = gfx.getimgdim(0)
    if img_w > 0 and img_h > 0 then
      gfx.a = 1 gfx.dest = -1 gfx.x, gfx.y = 0, 0
      gfx.blit(image, 1, 0, 0, 0, img_w, img_h, 0, 0, gfx.w, gfx.h)
    end
    ----------- 
    char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommand(40044, 0) end -- play
    if char ~= -1 then reaper.defer(main) end              -- defer       
    -----------  
    gfx.update()
    -----------
end

-- Init()
-- main()

function bal()

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)

if num==0 then return end

for i=0, num-1 do

	local it=reaper.GetSelectedMediaItem(0, i)

	local tk=reaper.GetActiveTake(it)

	if tk then

		reaper.Main_OnCommand(40179, 0)  --left

		local rms_l=reaper.NF_GetMediaItemPeakRMS_NonWindowed(it)
msg(rms_l)
		reaper.Main_OnCommand(40180, 0)  --right

		local rms_r=reaper.NF_GetMediaItemPeakRMS_NonWindowed(it)
msg(rms_r)
		reaper.Main_OnCommand(40176, 0)  --normal

		
		local min=math.min(rms_l, rms_r)/math.max(rms_l, rms_r)
-- -5E-10x6 - 1E-07x5 - 9E-06x4 - 0.0005x3 - 0.015x2 - 0.284x - 1.5476
-- -5E-10x6 - 1E-07x5 - 1E-05x4 - 0.0006x3 - 0.0198x2 - 0.388x - 2.5519
-- -0.0009x6 + 0.0193x5 - 0.17x4 + 0.8392x3 - 2.5005x2 + 4.365x - 2.5519
-- -0.0001x6 + 0.0037x5 - 0.0418x4 + 0.2635x3 - 1.0171x2 + 2.3396x - 1.5476


		local pan=-0.0001*min^6+0.0037*min^5-0.0418*min^4+0.2635*min^3-1.0171*min^2+2.3396*min-1.5476
		msg(pan)
		if rms_r>rms_l then pan=-pan end
msg(pan)
		reaper.SetMediaItemTakeInfo_Value(tk, 'D_PAN', pan)

	end

end

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock('平衡左右声道音量', -1)

end

function cal()
it1=reaper.GetSelectedMediaItem(0, 0)
if not it1 then return end
r1=reaper.NF_GetMediaItemPeakRMS_NonWindowed(it1)
msg(r1)

it2=reaper.GetSelectedMediaItem(0, 1)
if not it2 then return end
r2=reaper.NF_GetMediaItemPeakRMS_NonWindowed(it2)
msg(r2)
end

local num=reaper.CountSelectedMediaItems(0)
--if num==2 then cal() else bal() end
--[[
reaper.PreventUIRefresh(1)
local it=reaper.GetSelectedMediaItem(0, 0)
local rms_ori=reaper.NF_GetMediaItemPeakRMS_NonWindowed(it)
local tk=reaper.GetActiveTake(it)

file=io.open('k:\\pan.csv', 'w')

for i=0, 1, 0.01 do
	
	
	reaper.SetMediaItemTakeInfo_Value(tk, 'D_PAN', i)

	rms=reaper.NF_GetMediaItemPeakRMS_NonWindowed(it)
	bei=rms/rms_ori
	file:write(bei..','..i..'\n')

end
file:close()
reaper.PreventUIRefresh(-1)
]]

function ben()

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)

if num==0 then return end

for i=0, num-1 do

	local it=reaper.GetSelectedMediaItem(0, i)

	local tk=reaper.GetActiveTake(it)

	if tk then

		reaper.Main_OnCommand(40179, 0)  --left

		local rms_l=reaper.NF_GetMediaItemAverageRMS(it)

		reaper.Main_OnCommand(40180, 0)  --right

		local rms_r=reaper.NF_GetMediaItemAverageRMS(it)

		reaper.Main_OnCommand(40176, 0)  --normal

		local rms, pan=0, 0

		while true do

			pan=pan+0.01

			if pan==1 then break end

			reaper.SetMediaItemTakeInfo_Value(tk, 'D_PAN', pan)

			local rms_check=reaper.NF_GetMediaItemAverageRMS(it)

			if rms_check~=rms then

				rms=rms_check

			else

				reaper.SetMediaItemTakeInfo_Value(tk, 'D_PAN', pan-0.01)

				break

			end

		end

	end

end

end

function ReadTimestampsFromProjects(path)
  -- written by Meo Mespotine 27th of march 2020 - licensed under MIT-license
  --
  -- reads timestamps from all projects in path
  -- parameter:
  --    string path        - the path, in which the projects are located
  -- retvals
  --    integer count      - the number of files found in path
  --    table timestamps   - the timestamps found in the project or -1 in case of an error, as a handy table
  --    table errormessage - errormessages, if something went wrong
  --    table filenames    - filenames
  --    table timestamps_indexed_by_filename - the timestamps, but the index of the table is the filename itself
  
  local count=1
  local timestamps={}
  local timestamps2={}
  local errors={}
  local filenames={}
  while reaper.EnumerateFiles(path, count)~=nil do
    filenames[count]=reaper.EnumerateFiles(path, count)
    if pcall(io.lines, path.."/"..reaper.EnumerateFiles(path, count))==true then
      for c in io.lines(path.."/"..reaper.EnumerateFiles(path, count)) do
        timestamps[count]=tonumber(c:match(".* (.*)"))
        errors[count]=c
        if timestamps[count]==nil then timestamps[count]=-1 errors[count]="can't read timestamp: "..c end
        break
      end
    else
      timestamps[count]=-1
      errors[count]="can't read file"
    end
    timestamps2[filenames[count]]=timestamps[count]
    count=count+1
  end
  return count-1, timestamps, errors, filenames, timestamps2
end

ppath='H:\\Music\\KN项目\\剪辑'
--NumberOfTimestamps, TimeStampsArray, Errors, Filenames, Timestamps_indexed_by_filename = ReadTimestampsFromProjects(ppath)

function MeasureSpeed( function_name, ... )
  reaper.PreventUIRefresh(1)
  -- enter function name and arguments, all comma-separated
  local times_to_run = 100000 -- Set here the appropriate number
  local start = reaper.time_precise()
  for i = 1, times_to_run do
    function_name( ... )
  end
  -- returns time elapsed and function's results
  reaper.PreventUIRefresh(-1)
  return reaper.time_precise() - start, times_to_run
end
function Msg (param)
  reaper.ShowConsoleMsg(tostring (param).."\n")
end

function Msg(val)
  if console then
    reaper.ShowConsoleMsg(tostring(val).."\n")
  end
end

function wordsplit()
  cursor=reaper.GetCursorPosition()
  m, r=reaper.GetLastMarkerAndCurRegion(0, cursor)
  local _, isr, left, right, name=reaper.EnumProjectMarkers(r)

  local idx=1

  while idx<#name do
      local first=name:sub(idx, idx)
      if first:byte()<=127 then
          idx=idx+1
      else
          first=name:sub(idx, idx+2)
          idx=idx+3
      end
      --msg(first)
  end

  local it1=reaper.GetSelectedMediaItem(0, 0)
  local it2=reaper.GetSelectedMediaItem(0, 1)
  local text=reaper.ULT_GetMediaItemNote(it2)
  for line in text:gmatch('[^\n]+') do
    msg(#line)
  end
end

function meme()
  local title = reaper.JS_Localize("Media Explorer","common")
  local hWnd = reaper.JS_Window_Find(title, true)
  -- 获取ME选中项目的数量和序号
  local container = reaper.JS_Window_FindChildByID(hWnd     , 0   )
  local file_LV   = reaper.JS_Window_FindChildByID(container, 1000)
  local sel_count, sel_index = reaper.JS_ListView_ListAllSelItems(file_LV)
  -- 获取ME中指定项目的信息和状态
  for i=0, 13 do
      -- 0~13分别对应 File Size Date Type......Custom tag
      text,  state = reaper.JS_ListView_GetItem( file_LV, 0, i)
  end
  reaper.JS_ListView_SetItemText(file_LV, 0, 13, '123')
  reaper.JS_ListView_SetItemState(file_LV, 0, 2, 255)
  -- 获取ME选中项目的文件名
  for var in string.gmatch(sel_index, '[^,]+') do
      local filename = reaper.JS_ListView_GetItemText(file_LV, tonumber(var), 0)
  end
  -- 获取ME当前打开的路径
  local combo = reaper.JS_Window_FindChildByID(hWnd, 1002)
  local test = reaper.JS_Window_GetTitle(combo, "", 255)
  local edit = reaper.JS_Window_FindChildByID(combo, 1001)
  local pathSample = reaper.JS_Window_GetTitle(edit, "", 255)
end

--[[ local x, y=reaper.GetSet_ArrangeView2(0, 0, 0, 0)
msg(x..' '..y)
    local z=0.0007*(x+y)/2/2.0007
    reaper.GetSet_ArrangeView2(0, 1, 0, 0, (x+y)/2-z, (x+y)/2+z)

    local x, y=reaper.GetSet_ArrangeView2(0, 0, 0, 0)
msg(x..' '..y) ]]
function check_video()
  local text=reaper.CF_GetClipboard('')
  local cur=reaper.GetCursorPosition()
  local m, r=reaper.GetLastMarkerAndCurRegion(0, cur)
  local _, isr, left, right=reaper.EnumProjectMarkers(r)
  for line in text:gmatch('[^\n]+') do
    time1, time2=line:match('([^#]+)#([^#]+)')
    if not time1 then time1=line:match('([^#]+)') time2=right end
    reaper.AddProjectMarker2(0, 0, tonumber(time1)+left, 0, 'begin', -1, 16777471)
    reaper.AddProjectMarker2(0, 0, tonumber(time2)+left, 0, 'end', -1, 25231104)
  end
end
-- check_video()


local title = reaper.JS_Localize("Save Project","common")
local titleSaving = reaper.JS_Localize("Save project with media copy","common")
 t={}
 num=0
function save()
    local check=reaper.JS_Window_Find(title, true)
    local ret, list = reaper.JS_Window_ListAllChild(check)
    if check then
      for i=0, 100000 do
        local check=reaper.JS_Window_FindChildByID(check, i)
        if check and check~='' then
          t[i]=reaper.JS_Window_GetTitle(check)
        end
      end
      local hh=reaper.JS_Window_Find('取消', true)
      ID1=reaper.JS_Window_GetLongPtr(hh, 'ID')
      -- ID=reaper.JS_Int(ID1, 4)
      local hh1=reaper.JS_Window_Find('超变战陀  210122.rpp', true)
      ID2=reaper.JS_Window_GetLongPtr(hh1, 'ID')
    end


    reaper.defer(save)
end
-- save()

tproj=0
title1='Media Explorer'
title2=0
ttt={}
thwnd1, thwnd2=nil, nil
function checkSave()
    local check=reaper.JS_Window_Find(title1, true)
    if check then
        local focus=reaper.JS_Window_GetFocus()
        thwnd1=focus
        local focusid=reaper.JS_Window_GetLongPtr(focus, 'ID')
        tproj=reaper.JS_Window_AddressFromHandle(focusid)
        title2=reaper.JS_Window_GetTitle(focus)
        local _, list=reaper.JS_Window_ListAllChild(check)
        for address in list:gmatch('[^,]+') do
            local hwnd=reaper.JS_Window_HandleFromAddress(address)
            local name=reaper.JS_Window_GetTitle(hwnd)
            local hid=reaper.JS_Window_GetLongPtr(hwnd, 'ID')
            ttt[reaper.JS_Window_AddressFromHandle(hid)]=name
        end
        local field=reaper.JS_Window_FindChildByID(check, 41477)
        thwnd2=field
        reaper.JS_Window_SetTitle(field, 'fuckyou')

        local checkboxSub=reaper.JS_Window_Find('Create subdirectory for project', true)
        reaper.JS_WindowMessage_Send(checkboxSub, 'BM_SETCHECK', 1, 0, 0, 0)
        local checkboxCopy=reaper.JS_Window_Find('Copy all media', false)
        reaper.JS_WindowMessage_Send(checkboxCopy, 'BM_SETCHECK', 1, 0, 0, 0)
    end
    reaper.defer(checkSave)
end
-- checkSave()

--[[ hwnd=reaper.JS_Window_Find('Media Explorer', true)
local list= reaper.JS_Window_FindChild(hwnd, 'List1', true)
local _, l1, t1, r1, b1=reaper.JS_Window_GetRect(list)
msg(l1..' '..t1..' '..r1..' '..b1)    
local _, left, top, right, bottom=reaper.JS_ListView_GetItemRect(list, 0)
    msg(left..' '..top..' '..right..' '..bottom)
    local x, y=gfx.clienttoscreen(left, top)
    reaper.JS_Mouse_SetPosition(r1, b1) ]]

function select_device()    
    local h=reaper.JS_Window_Find('Audio device settings', true)
    if h then
        local parent=reaper.JS_Window_GetParent(h)
        local combo=reaper.JS_Window_FindChildByID(parent, 1000)
        reaper.JS_WindowMessage_Send(combo, 'CB_SETCURSEL', 2, 0, 0, 0)
    else
        reaper.defer(select_device)
    end
end
-- select_device()
-- reaper.ViewPrefs(118, 'Device')

function getmouseid()
    A_hwnd1 = reaper.JS_Window_FromPoint(reaper.GetMousePosition())
    A_title1=reaper.JS_Window_GetTitle(A_hwnd1)
    A_ID = reaper.JS_Window_GetLong(A_hwnd1, "ID")
    A_Style=reaper.JS_Window_GetLong(A_hwnd1, "STYLE")
    A_hwnd2=reaper.JS_Window_GetParent(A_hwnd1)
    A_title2=reaper.JS_Window_GetTitle(A_hwnd2)
    A_hwnd3=reaper.JS_Window_GetParent(A_hwnd2)
    A_title3=reaper.JS_Window_GetTitle(A_hwnd3)
    A_hwnd4=reaper.JS_Window_GetParent(A_hwnd3)
    A_title4=reaper.JS_Window_GetTitle(A_hwnd4)
    A_hwnd5=reaper.JS_Window_GetParent(A_hwnd4)
    A_title5=reaper.JS_Window_GetTitle(A_hwnd5)
    A_hwnd6=reaper.JS_Window_GetParent(A_hwnd5)
    A_title6=reaper.JS_Window_GetTitle(A_hwnd6)
    
    local _, child=reaper.JS_Window_ListAllChild(A_hwnd1)
    local A_childAll={}
    for address in child:gmatch('[^,]+') do
        local handle=reaper.JS_Window_HandleFromAddress(address)
        -- table.insert(A_childAll, {handle=handle, name=reaper.JS_Window_GetTitle(handle)})
        table.insert(A_childAll, reaper.JS_Window_GetTitle(handle))
    end

    local parent=reaper.JS_Window_GetParent(A_hwnd1)
    local A_childSaveLevel={}
    local _, child=reaper.JS_Window_ListAllChild(parent)
    for address in child:gmatch('[^,]+') do
        local handle=reaper.JS_Window_HandleFromAddress(address)
        local parentCheck=reaper.JS_Window_GetParent(handle)
        if parentCheck==parent and handle~=A_hwnd1 then
            table.insert(A_childSaveLevel, reaper.JS_Window_GetTitle(handle))
        end
    end
    reaper.defer(getmouseid)
end
-- getmouseid()

function everything()
    local h=reaper.JS_Window_Find('Everything', false)
    local _, child=reaper.JS_Window_ListAllChild(h)
    for address in child:gmatch('[^,]+') do
        local handle=reaper.JS_Window_HandleFromAddress(address)
        reaper.JS_Window_SetTitle(handle, 'fuckyou')
    end
    reaper.defer(everything)
end
-- everything()

function videowin()
    local hwnd=reaper.JS_Window_Find('Video Window', true)
    local _, left, top, right, bottom=reaper.JS_Window_GetRect(hwnd)
    local x, y=left+math.modf((right-left)/2), top+math.modf((bottom-top)/2)
    -- local xori, yori=reaper.GetMousePosition()
    -- reaper.JS_Mouse_SetPosition(x, y)
    local xc=math.modf((right-left)/2)
    local yc=math.modf((bottom-top)/2)
    -- reaper.JS_WindowMessage_Post(hwnd, 'WM_LBUTTONDBLCLK', 1, 0, 10, 10)
    reaper.JS_WindowMessage_Post(hwnd, 'WM_RBUTTONDOWN', 1, 0, xc, yc)
    reaper.JS_WindowMessage_Post(hwnd, 'WM_RBUTTONUP', 0, 0, xc, yc)
    -- reaper.Main_OnCommand(2010, 0)
    -- reaper.JS_Mouse_SetPosition(x, y-70)
    -- local hwndMenu=reaper.JS_Window_FromPoint(reaper.GetMousePosition()) msg(hwndMenu)
    -- reaper.JS_WindowMessage_Post(hwnd, 'WM_LBUTTONDOWN', 1, 0, 10, 10)
    -- reaper.JS_WindowMessage_Post(hwnd, 'WM_LBUTTONUP', 0, 0, 10, 10)
    -- reaper.Main_OnCommand(2008, 0)  --wait
    -- reaper.Main_OnCommand(2008, 0)  --wait
    -- reaper.JS_WindowMessage_Post(hwndMenu, 'WM_LBUTTONDOWN', 1, 0, 10, 10)
    -- reaper.JS_WindowMessage_Post(hwndMenu, 'WM_LBUTTONUP', 0, 0, 10, 10)
    -- reaper.JS_Mouse_SetPosition(xori, yori)
    -- reaper.BR_Win32_SendMessage(hwnd, 0x203, 0, 0)
end
-- videowin()

function toframe(frame, start)
    reaper.ApplyNudge(0, 1, 6, 18, frame+start, false, 0)
end

function from_python()
    local text=reaper.CF_GetClipboard('')
    local start=reaper.GetCursorPosition()
    local framerate=reaper.TimeMap_curFrameRate(0)
    for line in text:gmatch('[^\n]+') do
        local open, close=line:match('(%d+):(%d+)')
        -- reaper.AddProjectMarker(0, 0, start+(open)/framerate, 0, 'start', -1)
        -- reaper.AddProjectMarker(0, 0, start+(close)/framerate, 0, 'end', -1)
        reaper.AddProjectMarker(0, true, start+(open-1)/framerate, start+(close-1)/framerate, 'found', -1)
    end
end
-- from_python()

function from_colab()
    local num=reaper.CountSelectedMediaItems(0)
    if num==0 then return end
    local start=reaper.GetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, 0), 'D_POSITION')
    local text=reaper.CF_GetClipboard('')
    local line={}
    local fps=reaper.TimeMap_curFrameRate(0)
    local thLen, thEnd=0.5, 1
    local pstart, pend=-1, -1
    for time in text:gmatch('%d+') do
        time=(tonumber(time)-1)/fps
        if pstart==-1 then
            pstart=time
        elseif pend<0 then
            if time-pstart>=thEnd then
                pstart=time
            elseif time-pstart<thEnd then
                pend=time
            end
        elseif pend>0 then
            if time-pend<thEnd then
                pend=time
            elseif time-pend>=thEnd then
                if pend-pstart>=thLen then table.insert(line, {open=pstart, close=pend}) end
                pstart, pend=time, -1
            end
        end
    end
    for k, v in pairs(line) do
        reaper.AddProjectMarker(0, 1, start+v.open, start+v.close, 'line', -1)
    end
end
-- from_colab()

function esc(s)
  local matches =
  {
    ["^"] = "%^",
    ["$"] = "%$",
    ["("] = "%(",
    [")"] = "%)",
    ["%"] = "%%",
    ["."] = "%.",
    ["["] = "%[",
    ["]"] = "%]",
    ["*"] = "%*",
    ["+"] = "%+",
    ["-"] = "%-",
    ["?"] = "%?",
  }
  return (s:gsub(".", matches))
end


local function GetItemActiveTakeSamples( item )
  -- Reads the samples of the item's active take and returns them
  -- in a table, indexed per channel
  local maxpeak=0
  local take = reaper.GetActiveTake( item )
  if not take or reaper.TakeIsMIDI( take ) then return end

  local floor, max, min = math.floor, math.max, math.min

  local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  local item_len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )

  local PCM_source = reaper.GetMediaItemTake_Source( take )
  local samplerate = reaper.GetMediaSourceSampleRate( PCM_source )
  local num_channels = reaper.GetMediaSourceNumChannels( PCM_source )

  -- Ease maths
  local playrate = reaper.GetMediaItemTakeInfo_Value( take, "D_PLAYRATE" )
  local new_len
  if playrate ~= 1 then
      reaper.SetMediaItemTakeInfo_Value( take, "D_PLAYRATE", 1 )
      new_len = item_len * playrate
      reaper.SetMediaItemInfo_Value( item, "D_LENGTH", new_len )
  end
  
  -- Time range for getting samples
  local range_len = new_len or item_len
  local range_len_spls = floor( range_len * samplerate )

  -- Break the range into blocks
  local block_size = 65536
  local n_blocks = floor( range_len_spls / block_size )
  local extra_spls = range_len_spls - block_size * n_blocks

  -- 'samplebuffer' will hold all of the audio data for each block
  local buffer_sz =  block_size * num_channels
  local buffer_duration = buffer_sz / samplerate
  local samplebuffer = reaper.new_array( buffer_sz )
  local audio = reaper.CreateTakeAudioAccessor( take )

  -- initialize table that will hold samples
  local samples_per_channel = {}
  for i = 1, num_channels do
      samples_per_channel[i] = {}
  end

  -- Loop through the audio, one block at a time
  local starttime_sec = 0
  for cur_block = 0, n_blocks do

      -- The last iteration will almost never be a full block
      if cur_block == n_blocks then
        if extra_spls ~= 0 then
          block_size = extra_spls
        else
          break
        end
      end
      
      samplebuffer.clear()
      reaper.GetAudioAccessorSamples( audio, samplerate, num_channels, starttime_sec, block_size, samplebuffer )

      -- Loop through each channel separately
      for i = 1, num_channels do
          
          local num_samples = #samples_per_channel[i]
          
          for j = 1, block_size do
              -- Sample position in the block
              local pos = ( j - 1 ) * num_channels + i   
              local spl = samplebuffer[pos]
              if spl>maxpeak then maxpeak=spl end
              num_samples = num_samples + 1
              samples_per_channel[i][num_samples] = spl
          end
          
      end
      
      starttime_sec = starttime_sec + buffer_duration

  end

  reaper.DestroyAudioAccessor( audio )
  
  -- Restore playrate
  if playrate ~= 1 then
      reaper.SetMediaItemTakeInfo_Value( take, "D_PLAYRATE", playrate )
      reaper.SetMediaItemInfo_Value( item, "D_LENGTH", item_len )
  end
  msg(maxpeak)
  return samplerate, num_channels, range_len_spls, samples_per_channel, PCM_source

end

function ama()
  reaper.ClearConsole()
  local Z = collectgarbage("count")
  local t1 = reaper.time_precise()
  local samplerate, num_channels, num_samples, samples, PCM_source = 
  GetItemActiveTakeSamples( reaper.GetSelectedMediaItem(0, 0) )
  local t2 = reaper.time_precise() - t1
  -- reaper.ShowConsoleMsg( "Elapsed time: " .. t2 .. " seconds\n" )
  local file_size = (({reaper.JS_File_Stat( reaper.GetMediaSourceFileName( PCM_source, "" ) )})[2])/1024
  -- reaper.ShowConsoleMsg( string.format("Source file size: %.2f KB (%.2f MB)\n", file_size, file_size/1024) )
  -- reaper.ShowConsoleMsg( string.format("Memory used: %.2f MB\n\n",(collectgarbage("count") - Z) / 1024) )
end
-- ama()


function esc(s)
  local matches =
  {
    ["^"] = "%^",
    ["$"] = "%$",
    ["("] = "%(",
    [")"] = "%)",
    ["%"] = "%%",
    ["."] = "%.",
    ["["] = "%[",
    ["]"] = "%]",
    ["*"] = "%*",
    ["+"] = "%+",
    ["-"] = "%-",
    ["?"] = "%?",
  }
  return (s:gsub(".", matches))
end

function msg(value)
  reaper.ShowConsoleMsg(tostring(value) .. '\n')
end

function video_test()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local num=reaper.CountSelectedMediaItems(0)
  if num==0 then return end

  local fr=reaper.TimeMap_curFrameRate(0)
  local exe='k:\\dsy_video_cut.exe'
  local ffmpeg="\""..reaper.GetResourcePath().."\\UserPlugins\\ffmpeg.exe\""
  for i=0, num-1 do
    local it=reaper.GetSelectedMediaItem(0, i)
    local len=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
    local _, chunk=reaper.GetItemStateChunk(it, '', 0)
    local path=chunk:match('FILE \"([^\"]+)')
    local folder=path:match("(.+[/\\])[^/\\]+")
    local tk=reaper.GetActiveTake(it)
    local source=reaper.GetMediaItemTake_Source(tk)
    local srcType=reaper.GetMediaSourceType(source, '')
    if srcType=='VIDEO' then
      local offset=reaper.GetMediaItemTakeInfo_Value(tk, 'D_STARTOFFS')
      local framest=math.floor(offset*fr+0.5)
      local frameed=math.floor((offset+len)*fr+0.5)
      local output=folder..'vtemp.avi'
      local commandV='\"'..exe..'\" --input \"'..path..'\" --output \"'..output..'\" --framest '..framest..' --frameed '..frameed
      reaper.ExecProcess(commandV, 0)
      local sound=folder..'atemp.aac'
      local soundcut=folder..'atempcut.mp3'
      local commandAC=ffmpeg..' -y -i \"'..path..'\" -vn -acodec copy \"'..sound..'\"'
      reaper.ExecProcess(commandAC, 0)
      local commandA=ffmpeg..' -y -vn -ss '..offset..' -t '..len..' -accurate_seek -i \"'..sound..'\" -acodec mp3 \"'..soundcut..'\"'
      msg(commandA)
      reaper.ExecProcess(commandA, 0)
      commandM=ffmpeg..' -y -i \"'..output..'\" -i \"'..soundcut..'\" -vcodec libx264 -acodec aac \"'..folder..'merge.mp4\"'
      msg(commandM)
      reaper.ExecProcess(commandM, 0)
    end
  end

  local itSound=reaper.GetSelectedMediaItem(0, 0)
  local trVideo=reaper.GetMediaItemTrack(itSound)
  local pos=reaper.GetMediaItemInfo_Value(itSound, 'D_POSITION')
  local cur=reaper.GetCursorPosition()
  local _, chunk=reaper.GetItemStateChunk(itSound, '', 0)
  local pathSound=chunk:match('FILE \"([^\"]+)')
  local commandM=ffmpeg..' -y -i \"'..output..'\" -i \"'..pathSound..'\" -vcodec libx264 -acodec aac \"'..folder..'join.mp4\"'
  reaper.ExecProcess(commandM, 0)
  reaper.Main_OnCommand(40006, 0)  --remove item
  os.remove(pathSound)
  reaper.SetEditCurPos(pos, 0, 0)
  reaper.SetOnlyTrackSelected(trVideo)
  reaper.InsertMedia(folder..'join.mp4', 0)
  reaper.SetEditCurPos(cur, 0, 0)

  reaper.UpdateArrange()
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)
end

function video_cut()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local num=reaper.CountSelectedMediaItems(0)
  if num==0 then return end

  local fr=reaper.TimeMap_curFrameRate(0)
  local exe='k:\\dsy_video_cut.exe'
  local ffmpeg="\""..reaper.GetResourcePath().."\\UserPlugins\\ffmpeg.exe\""
  for i=0, num-1 do
    local it=reaper.GetSelectedMediaItem(0, i)
    local len=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
    local _, chunk=reaper.GetItemStateChunk(it, '', 0)
    local path=chunk:match('FILE \"([^\"]+)')
    local folder=path:match("(.+[/\\])[^/\\]+")
    local tk=reaper.GetActiveTake(it)
    local source=reaper.GetMediaItemTake_Source(tk)
    local srcType=reaper.GetMediaSourceType(source, '')
    if srcType=='VIDEO' then
      local offset=reaper.GetMediaItemTakeInfo_Value(tk, 'D_STARTOFFS')
      local framest=math.floor(offset*fr+0.5)
      local frameed=math.floor((offset+len)*fr+0.5)
      local output=folder..'vtemp.avi'
      local commandV='\"'..exe..'\" --input \"'..path..'\" --output \"'..output..'\" --framest '..framest..' --frameed '..frameed
      reaper.ExecProcess(commandV, 0)
      local sound=folder..'atemp.aac'
      local soundcut=folder..'atempcut.mp3'
      local commandAC=ffmpeg..' -y -i \"'..path..'\" -vn -acodec copy \"'..sound..'\"'
      reaper.ExecProcess(commandAC, 0)
      local commandA=ffmpeg..' -y -vn -ss '..offset..' -t '..len..' -accurate_seek -i \"'..sound..'\" -acodec mp3 \"'..soundcut..'\"'
      msg(commandA)
      reaper.ExecProcess(commandA, 0)
      commandM=ffmpeg..' -y -i \"'..output..'\" -i \"'..soundcut..'\" -vcodec libx264 -acodec aac \"'..folder..'merge.mp4\"'
      msg(commandM)
      reaper.ExecProcess(commandM, 0)
    end
  end

  local itSound=reaper.GetSelectedMediaItem(0, 0)
  local trVideo=reaper.GetMediaItemTrack(itSound)
  local pos=reaper.GetMediaItemInfo_Value(itSound, 'D_POSITION')
  local cur=reaper.GetCursorPosition()
  local _, chunk=reaper.GetItemStateChunk(itSound, '', 0)
  local pathSound=chunk:match('FILE \"([^\"]+)')
  local commandM=ffmpeg..' -y -i \"'..output..'\" -i \"'..pathSound..'\" -vcodec libx264 -acodec aac \"'..folder..'join.mp4\"'
  reaper.ExecProcess(commandM, 0)
  reaper.Main_OnCommand(40006, 0)  --remove item
  os.remove(pathSound)
  reaper.SetEditCurPos(pos, 0, 0)
  reaper.SetOnlyTrackSelected(trVideo)
  reaper.InsertMedia(folder..'join.mp4', 0)
  reaper.SetEditCurPos(cur, 0, 0)

  reaper.UpdateArrange()
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)
end

-- local it=reaper.GetSelectedMediaItem(0, 0)
-- local pos=reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
-- local edge=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')+pos
-- msg(reaper.NF_Win32_GetSystemMetrics(5)..' '..reaper.NF_Win32_GetSystemMetrics(7)..' '..reaper.NF_Win32_GetSystemMetrics(21))
-- reaper.GetSet_ArrangeView2(0, 1, 0, 0, pos, edge)

-- msg(left..' '..right)
-- cur=reaper.GetCursorPosition()
-- local m, r=reaper.GetLastMarkerAndCurRegion(0, cur)
-- local _, isr, rl, rr=reaper.EnumProjectMarkers(r)
-- local offset=(reaper.NF_Win32_GetSystemMetrics(7)+reaper.NF_Win32_GetSystemMetrics(10))/reaper.GetHZoomLevel() msg(offset)
-- reaper.GetSet_ArrangeView2(0, 1, 0, 0, rl, rr)
-- local offset=18/reaper.GetHZoomLevel() msg(offset)
-- reaper.GetSet_ArrangeView2(0, 1, 0, 0, rl, rr+offset)
-- reaper.BR_SetArrangeView(0, rl, rr+offset)
-- local left,right=reaper.GetSet_ArrangeView2(0, 0, 0, 0)
-- msg((rl-left)..' '..(rr-right)..' '..reaper.GetHZoomLevel()..' '..reaper.NF_Win32_GetSystemMetrics(5)..' '..reaper.NF_Win32_GetSystemMetrics(7)..' '..reaper.NF_Win32_GetSystemMetrics(21))
-- msg((rl/left)..' '..(rr/right)..' '..(reaper.GetHZoomLevel()*reaper.NF_Win32_GetSystemMetrics(7)))
-- msg(reaper.NF_Win32_GetSystemMetrics(5)..' '..reaper.NF_Win32_GetSystemMetrics(7)..' '..reaper.NF_Win32_GetSystemMetrics(10))

-- reaper.GetSet_ArrangeView2(0, 1, 0, 0, rl, rr)
-- local left, right=reaper.BR_GetArrangeView(0)
-- msg(rl..' '..rr)
-- msg(left..' '..right)



-- local hwnd=reaper.GetMainHwnd()
-- for i=0, 10000 do
--   local check=reaper.JS_Window_FindChildByID(hwnd, i)
--   -- if check and check~='' then
--   if check then
--     -- msg(i..' : '..reaper.JS_Window_GetTitle(check))
--     msg(i)
--   end
-- end
-- msg('')
-- local main=reaper.GetMainHwnd()
-- retval, list = reaper.JS_Window_ListAllChild(main)
-- for address in list:gmatch('[^,]+') do
--   local hwnd= reaper.JS_Window_HandleFromAddress(address)
--   reaper.ShowConsoleMsg(reaper.JS_Window_GetLong(hwnd, 'ID')..'\n')
-- end

function connectItem()  --把item按顺序无缝连接
  local numCheck=reaper.CountSelectedMediaItems(0)
  if numCheck==0 then return end
  local it1=reaper.GetSelectedMediaItem(0, 0)
  local start=reaper.GetMediaItemInfo_Value(it1, 'D_POSITION')+reaper.GetMediaItemInfo_Value(it1, 'D_LENGTH')
  local order={}
  for i=1, numCheck-1 do
      table.insert(order, reaper.GetSelectedMediaItem(0, i))
  end
  for k, v in pairs(order) do
      reaper.SetMediaItemPosition(v, start, 0)
      start=start+reaper.GetMediaItemInfo_Value(v, 'D_LENGTH')
  end
end

function video_glue()
  reaper.PreventUIRefresh(1)

  local time=reaper.time_precise()
  local num=reaper.CountSelectedMediaItems(0)
  if num==0 then return end

  local fr=reaper.SNM_GetIntConfigVar("projfrbase", -1)
  local proj=reaper.GetProjectName(0, ''):match("(.+)%.[^%.]+")
  local img=reaper.GetProjectPath('')..'\\images\\'
  reaper.ExecProcess('cmd /c md \"'..img..'\"', 0)
  local ffmpeg="\""..reaper.GetResourcePath().."\\UserPlugins\\ffmpeg.exe\""
  local cur=reaper.GetCursorPosition()

  local it0=reaper.GetSelectedMediaItem(0, 0)
  local start=reaper.GetMediaItemInfo_Value(it0, 'D_POSITION')
  local _, chunk=reaper.GetItemStateChunk(it, '', 0)
  local path=chunk:match('FILE \"([^\"]+)')
  local parent=path:match("(.+[/\\])[^/\\]+")
  local prefix=path:match("(.+[/\\].+)%.%w+$")
  local cur=reaper.GetCursorPosition()

  local clips, audios, fix={}, {}, {}
  local filelist='concat:'
  for i=1, num-1 do
      local it=reaper.GetSelectedMediaItem(0, i)
      audios[#audios+1]=it
      local len=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
      local tk=reaper.GetActiveTake(it)
      local offset=reaper.GetMediaItemTakeInfo_Value(tk, 'D_STARTOFFS')
      local framest=math.floor(offset*fr+0.5)
      local frameed=math.floor((offset+len)*fr+0.5)-1
      local outputTemp=prefix..'_'..framest..'_'..frameed..'.mp4'
      local outputFix=prefix..'_'..framest..'_'..frameed..'_fix.ts'
      clips[#clips+1]=outputTemp
      fix[#fix+1]=outputFix
      local command=ffmpeg..' -y -i \"'..path..'\" -an -vf select=\"between(n\\,'..framest..'\\,'..frameed..'),setpts=PTS-STARTPTS" -c:v libx264 -preset ultrafast \"'..outputTemp..'\"'
      reaper.ExecProcess(command, 0)
  end

  reaper.SelectAllMediaItems(0, 0)
  for k, v in pairs(audios) do
    reaper.SetMediaItemSelected(v, 1)
  end
  connectItem()
  reaper.Main_OnCommand(40257, 0)  --glue
  local itSound=reaper.GetSelectedMediaItem(0, 0)
  local pos=reaper.GetMediaItemInfo_Value(itSound, 'D_POSITION')
  local trVideo=reaper.GetMediaItemTrack(itSound)
  local cur=reaper.GetCursorPosition()
  local _, chunk=reaper.GetItemStateChunk(itSound, '', 0)
  local pathSound=chunk:match('FILE \"([^\"]+)')

  for k, v in pairs(clips) do
    filelist=filelist..fix[k]
    if k<#clips then filelist=filelist..'|' end
    local commandFix=ffmpeg.." -y -i \""..v.."\" -c copy -vbsf h264_mp4toannexb \""..fix[k].."\""
    reaper.ExecProcess(commandFix, 0)  --转换ts格式
  end
  local command=ffmpeg..' -y -i \"'..filelist..'\" -c copy \"'..parent..'vtemp.mp4\"'
  reaper.ExecProcess(command, 0)  --合并
  -- for k, v in pairs(fix) do os.remove(v) end

  local output=parent..'vtemp.mp4'
  local commandM=ffmpeg..' -y -i \"'..output..'\" -i \"'..pathSound..'\" -vcodec copy -acodec aac \"'..parent..'join.mp4\"'
  reaper.ExecProcess(commandM, 0)
  reaper.Main_OnCommand(40006, 0)  --remove item
  os.remove(pathSound)
  os.remove(output)

  reaper.SetEditCurPos(cur, 0, 0)
  msg(reaper.time_precise()-time)
  reaper.PreventUIRefresh(-1)
end

function cutt()
  reaper.PreventUIRefresh(1)
  local time=reaper.time_precise()
  local num=reaper.CountSelectedMediaItems(0)
  if num==0 then return end

  local img=reaper.GetProjectPath('')..'/images/'
  local fr=reaper.TimeMap_curFrameRate(0)
  reaper.ExecProcess('cmd /c md \"'..img..'\"', 0)
  local ffmpeg="\""..reaper.GetResourcePath().."/UserPlugins/ffmpeg.exe\""
  local cur=reaper.GetCursorPosition()

  local it0=reaper.GetSelectedMediaItem(0, 0)
  local start=reaper.GetMediaItemInfo_Value(it0, 'D_POSITION')
  local _, chunk=reaper.GetItemStateChunk(it, '', 0)
  local path=chunk:match('FILE \"([^\"]+)')
  local name=path:match(".+[/\\](.+)%.%w+$")
  local framest=0
  local numFrames=0

  for i=1, num-1 do
      local it=reaper.GetSelectedMediaItem(0, i)
      local pos=reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
      local len=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
      local offset=pos-start
      local frames=math.floor(len*fr+0.5)
      numFrames=numFrames+frames
      local path_img='\"'..img..name..'_%5d.png\"'
      local command=ffmpeg..' -y -ss '..offset..' -i \"'..path..'\" -vframes '..frames..' -start_number '..string.format("%05d", framest)..' '..path_img
      reaper.ExecProcess(command, 0)
      framest=framest+frames
  end
  -- ffmpeg -f image2 -i "超级飞侠传统文化 01 211127__2.8_%05d.png" merge1.mp4
  local pathVideo=img..'video.mp4'
  local commandMerge=ffmpeg..' -y -f image2 -i \"'..img..name..'_%5d.png\" -c:v libx264 -preset ultrafast \"'..pathVideo..'\"'
  reaper.ExecProcess(commandMerge, 0)

  reaper.SetMediaItemSelected(it0, 0)
  connectItem()
  reaper.Main_OnCommand(40257, 0)  --glue
  local itSound=reaper.GetSelectedMediaItem(0, 0)
  local trVideo=reaper.GetMediaItemTrack(itSound)
  local _, chunk=reaper.GetItemStateChunk(itSound, '', 0)
  local pathSound=chunk:match('FILE \"([^\"]+)')

  local commandM=ffmpeg..' -y -i \"'..pathVideo..'\" -i \"'..pathSound..'\" -vcodec copy -acodec aac \"'..img..'join.mp4\"'
  reaper.ExecProcess(commandM, 0)
  reaper.Main_OnCommand(40006, 0)  --remove item
  os.remove(pathSound)
  os.remove(pathVideo)
  for i=0, numFrames-1 do
    local imgPath=img..name..'_'..string.format("%05d", i)..'.png'
    os.remove(imgPath)
  end
  reaper.SetEditCurPos(cur, 0, 0)
  msg(reaper.time_precise()-time)
  reaper.PreventUIRefresh(-1)
end
-- cutt()

local idx=0
while true do
  local projCur=reaper.EnumProjects(idx)
  if not projcur then msg(idx) break end
  idx=idx+1
end