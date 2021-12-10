--[[
ReaScript Name: item置顶
Version: 1.0
Author: noiZ
]]

function msg(value)
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
end

-------------------------------------------------------------------窗口参数-------------------------------------------------------------------
-- local wWin=1300
local wWin=reaper.NF_Win32_GetSystemMetrics(16)
local hWin=400
local hwnd=reaper.JS_Window_Find('trackview', true)
local ret, viewLeft=reaper.JS_Window_GetRect(hwnd)
local wDraw=wWin
local wDrawDock=wWin-viewLeft
local hDraw=hWin*0.8
local xDraw=(wWin-wDraw)/2
local xDrawDock=viewLeft+1
local yDraw=(hWin-hDraw)/2
-- local yCenter=yDraw+hDraw/2
local yCenter=hWin/2

-------------------------------------------------------------------常量定义-------------------------------------------------------------------
local itLast=0  --上一个选中的item
local posLast=-1 --上一个选中的item的位置
local lenLast=-1  --上一个长度
local volLast=-2  --上一个音量
local offsetLast=-1  --上一个偏移量
local zoomLast=-1  --上一个缩放量
local screenL, screenR=-1 ,-1  --屏幕左右边界
local wWinLast, hWinLast=-1, -1  --上一个窗口尺寸
local samples={}  --所有采样点的数据
local waves={}  --波形每个点的坐标
local scale=1  --缩放系数
local lock=false  --锁定状态
local state=''  --按键状态
local itLock  --锁定的item
local redraw=false  --重绘状态

-------------------------------------------------------------------窗口初始化-------------------------------------------------------------------
gfx.clear=4210752
gfx.init( '显示波形', wWin, hWin, 0, 5, 100)
gfx.dock(1)
-------------------------------------------------------------------功能函数-------------------------------------------------------------------
function get_samples(item)
    local take=reaper.GetActiveTake(item)
    if not take or reaper.TakeIsMIDI( take ) then return end

    local peaks = {}

    local pos=reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len=reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local right=pos+len
    local edgeL, edgeR=reaper.GetSet_ArrangeView2(0, 0, 0, 0)
    pos=math.max( pos,edgeL )
    len=math.min( right,edgeR )-pos
    local scaled_len=wDraw
    local PCM_source = reaper.GetMediaItemTake_Source(take)
    local n_chans = reaper.GetMediaSourceNumChannels(PCM_source)
    local peakrate = scaled_len/len -- pixels/seconds
    local n_spls = math.floor(len*peakrate + 0.5)     
    local want_extra_type = -1--115  -- 's' char
    local buf = reaper.new_array(n_spls*n_chans*2) -- no spectral info
    
    buf.clear()
    ------------------
    local retval = reaper.GetMediaItemTake_Peaks(take, peakrate, pos, n_chans, n_spls, want_extra_type, buf)
    local spl_cnt  = (retval & 0xfffff)        -- sample_count
    --local ext_type = (retval & 0x1000000)>>24  -- extra_type was available
    --local out_mode = (retval & 0xf00000)>>20   -- output_mode
    ------------------
  
    if spl_cnt > 0 then
        for i = 1, n_chans do
            peaks[i] = {} -- create a table for each channel
        end
        local s = 0 -- table size counter
        for pos = 1, n_spls*n_chans, n_chans do -- move bufferpos to start of next max peak
            -- loop through channels
            for i = 1, n_chans do
                local p = peaks[i]
                p[s+1] = buf[pos+i-1]                   -- max peak
                p[s+2] = buf[pos+n_chans*n_spls+i-1]    -- min peak
            end 
            s = s + 2
      end
    end
    ------------------
    return peaks
end

function get_coor_from_smpls(smpls, vol, xrec, yrec, wrec, hrec, yC)
    local t={}
    --按照通道数初始化
    for i=1, #smpls do
        t[i]={}
    end
    local nSamples=#smpls[1]  --采样数
    local dPerSample=wrec/(nSamples-1)  --每个采样点之间间隔，n个采样点包含n-1个间隔
    -- msg(nSamples..' '..dPerSample)
    local stereo=#smpls>1  --是否双声道

    for k, v in pairs(smpls) do
        local count=0
        for k1, v1 in pairs(v) do
            if v1==0 then count=count+1 end
            local x=xrec+(k1-1)*dPerSample  --横坐标
            local ymin, ymax  --纵坐标极值
            if stereo then
                if k==1 then
                    ymin, ymax=yC, yrec
                else
                    ymin, ymax=yrec+hrec, yC
                end
            else
                ymin, ymax=yrec+hrec, yrec
            end
            local vScale=v1*vol
            vScale=(vScale<-1 and -1) or (vScale>1 and 1) or vScale
            local y=value_convert(vScale, -1, 1, ymin, ymax)
            t[k][k1]={x, y}
        end
        -- msg(count)
    end
    return t
end

function value_convert(value, value_min, value_max, x_min, x_max)  --相对值的换算
    local x=(value-value_min)*(x_max-x_min)/(value_max-value_min)+x_min
    return x
end

function get_scale_size()
    local x, y, w, h
    if gfx.dock(-1)>0 then
        x, y, w, h=0, yDraw, wWin, hDraw
    elseif gfx.w==wWin and gfx.h==hWin then
        x, y, w, h=xDraw, yDraw, wDraw, hDraw
    else
        w, h=gfx.w*0.8, gfx.h*0.8
        x, y=(gfx.w-w)/2, (gfx.h-h)/2
    end
    return x, y, w, h
end

function get_coor_from_smpls(smpls, vol, xrec, yrec, wrec, hrec, yC)
    local t={}
    --按照通道数初始化
    for i=1, #smpls do
        t[i]={}
    end
    local nSamples=#smpls[1]  --采样数
    local dPerSample=wrec/(nSamples-1)  --每个采样点之间间隔，n个采样点包含n-1个间隔
    -- msg(nSamples..' '..dPerSample)
    local stereo=#smpls>1  --是否双声道

    for k, v in pairs(smpls) do
        local count=0
        for k1, v1 in pairs(v) do
            if v1==0 then count=count+1 end
            local x=xrec+(k1-1)*dPerSample  --横坐标
            local ymin, ymax  --纵坐标极值
            if stereo then
                if k==1 then
                    ymin, ymax=yC, yrec
                else
                    ymin, ymax=yrec+hrec, yC
                end
            else
                ymin, ymax=yrec+hrec, yrec
            end
            local vScale=v1*vol
            vScale=(vScale<-1 and -1) or (vScale>1 and 1) or vScale
            local y=value_convert(vScale, -1, 1, ymin, ymax)
            t[k][k1]={x, y}
        end
        -- msg(count)
    end
    return t
end

function draw_waves(t, scaleX, scaleY)
    if not t then return end
    if not t[1] then return end
    gfx.set(not lock and 1 or 0, lock and 1 or 0, 0, 1)
    for k, v in pairs(t) do
        for i=2, #v do
            local x1, y1=v[i-1][1], v[i-1][2]
            local x2, y2=v[i][1], v[i][2]
            gfx.line(x1*scaleX, y1*scaleY, x2*scaleX, y2*scaleY, 0)
        end
    end
end

function clear_and_set_gfx_buffer(buf, gfx_dest, w, h)
    w = w or gfx.w
    h = h or gfx.h
    gfx.setimgdim(buf, 0, 0) -- clear buffer
    gfx.setimgdim(buf, w, h)
    gfx.dest = gfx_dest
end
clear_and_set_gfx_buffer(1, 1)


function blit_from_buffer(buf, opt_gfx_dest, opt_dest_w, opt_dest_h)
    opt_gfx_dest = opt_gfx_dest or -1
    opt_dest_w, opt_dest_h = gfx.w or 0, gfx.h or 0
    local img_w, img_h = gfx.getimgdim(buf)
    --   gfx.mode = -1
    gfx.a = 1; gfx.dest = opt_gfx_dest; gfx.x, gfx.y = 0, 0
    gfx.blit(buf, 1, 0, 0, 0, img_w, img_h, 0, 0, opt_dest_w, opt_dest_h)
end

-------------------------------------------------------------------功能-------------------------------------------------------------------
function set_lock()
    if not lock then
        local it=reaper.GetSelectedMediaItem(0, 0)
        if not it then return end
        local take=reaper.GetActiveTake(it)
        if not take or reaper.TakeIsMIDI( take ) then return end
        itLock=it
    end
    lock=not lock
    redraw=true
end

-------------------------------------------------------------------主进程-------------------------------------------------------------------
function main()
    if lock or reaper.CountSelectedMediaItems(0)>0 then
        local it=lock and itLock or reaper.GetSelectedMediaItem(0, 0)
        local tk=reaper.GetActiveTake(it)
        if not it or reaper.TakeIsMIDI(tk) then return end
        local posCheck=reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
        local lenCheck=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
        local volIT=reaper.GetMediaItemInfo_Value(it, 'D_VOL')
        local volTK=reaper.GetMediaItemTakeInfo_Value(tk, 'D_VOL')
        local volCheck=volIT*volTK
        local offsetCheck=reaper.GetMediaItemTakeInfo_Value(tk, 'D_STARTOFFS')
        local zoomCheck=reaper.GetHZoomLevel()
        local screenLCheck, screenRCheck=reaper.GetSet_ArrangeView2(0, 0, 0, 0)
        if posCheck<screenRCheck and posCheck+lenCheck>screenLCheck and ((lock and it~=itLast) or posCheck~=posLast or lenCheck~=lenLast or volCheck~=volLast or offsetCheck~=offsetLast or gfx.w~=wWinLast or gfx.h~=hWinLast or zoomCheck~=zoomLast or screenLCheck~=screenL or screenRCheck~=screenR or redraw) then
            itLast=it
            posLast=posCheck
            lenLast=lenCheck
            volLast=volCheck
            offsetLast=offsetCheck
            zoomLast=zoomCheck
            screenL=screenLCheck
            screenR=screenRCheck
            wWinLast=gfx.w
            hWinLast=gfx.h
            samples, waves={}, {}
            local isDock=gfx.dock(-1)
            local leftMax=math.max(screenL, posLast)
            local xDrawCur=isDock>0 and xDrawDock+(leftMax-screenL)*zoomLast or xDraw
            local wDrawCur=isDock>0 and (math.min(screenR, posLast+lenLast)-leftMax)*zoomLast or wDraw
            samples=get_samples(itLast)  --获取采样数据
            waves=get_coor_from_smpls(samples, volCheck, xDrawCur, yDraw, wDrawCur, hDraw, yCenter)  --获取坐标数据
            clear_and_set_gfx_buffer(0, 0)
            draw_waves(waves, gfx.w/wWin, gfx.h/hWin)  --绘制波形
            redraw=false
        end
        gfx.blit(0, 1, 0)
    else
        itLast=0
    end
    gfx.blit(1, 1, 0)
end

function check_input()  --检测鼠标按键情况
    if gfx.mouse_cap==0 then  --无按键
        if state=='lock' then
            set_lock()
        end
        state='idle'
    elseif gfx.mouse_cap==1 then  --按住左键
    elseif gfx.mouse_cap==2 then  --按住右键
        state='lock'
    end
end

function main_loop()
    main()
    check_input()
    if gfx.getchar()>=0 then reaper.defer(main_loop) end
end
main_loop()