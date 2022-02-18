--[[
ReaScript Name: ReaMetadata
Version: 1.0
Author: noiZ
]]
function msg(value)
    reaper.ShowConsoleMsg(tostring(value) .. '\n')
end
-------------------------------------------------------------------窗口初始化-------------------------------------------------------------------
local mainPath=debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
local library=mainPath..'DSY_GUI.lua'
dofile(library)
gui.proj_ext='ReaMetadata'

gui.win.normal('ReaMetadata', 425, 180, 0, 0, false)
-------------------------------------------------------------------常量-------------------------------------------------------------------
local title = reaper.JS_Localize("Media Explorer","common")
local hwnd = reaper.JS_Window_Find(title, true)
local nameDBHWND = reaper.JS_Window_FindChildByID(hwnd, 1002)
local nameDB=reaper.JS_Window_GetTitle(nameDBHWND)
local listmetatag={'T', 'A', 'B', 'y', 'G', 'c', 'd', 'P', 'K', 'U', 'R', 'M'}
local listmeta={'Title', 'Artist', 'Album', 'Date', 'Genre', 'Comment', 'Description', 'BPM', 'KEY', 'Custom Tags', 'Start Offset', 'Track Number'}
local listmethod={'修改', '添加', '删除'}
local win = string.find(reaper.GetOS(), "Win") ~= nil
local sep=win and '\\' or '/'
local enter=win and '\n' or '\r'
local key_press_last=0 --上次按键状态
-------------------------------------------------------------------功能相关-------------------------------------------------------------------
function get_mediadb_path(name) --获取当前的MediaDB路径，name-MediaDB名称，resource-资源文件夹路径
    local resource=reaper.GetResourcePath()..'/'
    local ini=resource..'reaper.ini'
    local fileini=io.open(ini)
    local content=fileini:read('*all')
    fileini:close()
    local idx=content:match('ShortcutT(%d+)='..name)
    local fn=content:match('Shortcut'..idx..'=([^\n\r]+)')
    return resource..'MediaDB/'..fn
end

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

function get_sel_item_path_from_me(hwnd)  --获取选中文件的路径
    local list= reaper.JS_Window_FindChild(hwnd, 'List1', true)
    local sel_count, sel_index = reaper.JS_ListView_ListAllSelItems(list)
    if sel_count==0 then return end
    local sel_index1=tonumber(sel_index:match('[^,]+'))
    -------------------------------------------------------------------检查ME是否有完整路径-------------------------------------------------------------------
    local name=reaper.JS_ListView_GetItem(list, sel_index1, 0)
    local isFull=name:match('[/\\]')
    local resumeNopath, resumePartpath=false, false
    local ext=name:match(".+%.(%w+)$")
    local resumeExt=false
    if not ext or not reaper.IsMediaExtension(ext, false) then  --扩展名无效
        resumeExt=true
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42091, 0, 0, 0)  --显示扩展名
        name=reaper.JS_ListView_GetItem(list, sel_index1, 0)
    end
    local folderhwnd = reaper.JS_Window_FindChildByID(hwnd, 1002)
    local folder=reaper.JS_Window_GetTitle(folderhwnd)
    if not folder:match('[/\\]') then  --database
        if not reaper.file_exists(name) then  --路径不完整或没有路径
            reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42026, 0, 0, 0)  --显示完整路径
            if isFull then
                resumePartpath=true
            else
                resumeNopath=true
            end
        end
    end
    -------------------------------------------------------------------获取ME中选中文件的路径-------------------------------------------------------------------
    local outputs={}  --储存ME中的文件路径
    for idx in sel_index:gmatch('[^,]+') do
        local fn=reaper.JS_ListView_GetItem(list, tonumber(idx), 0)
        fn=fn:match('[/\\]') and fn or folder..sep..fn
        if not reaper.file_exists(fn) then reaper.MB('路径\n'..fn..'\n无效或为文件夹', '操作失败', 0) break end
        outputs[#outputs+1]=esc(fn)
    end
    -------------------------------------------------------------------恢复ME路径选项-------------------------------------------------------------------
    if resumeExt then reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42091, 0, 0, 0) end  --取消显示扩展名
    if resumePartpath then reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42134, 0, 0, 0) end  --显示部分路径
    if resumeNopath then reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42026, 0, 0, 0) end  --取消显示完整路径
    reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 1009, 0, 0, 0)  --stop
    reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 1009, 0, 0, 0)  --stop
    return outputs
end

function edit_metadata(mode, metatagidx, keyword)
    if not keyword or keyword=='' then return end
    local mediadbPath=get_mediadb_path(nameDB)  --当前打开的db对应的database文件路径
    local file=io.open(mediadbPath)
    local mediadb=file:read('*all')
    file:close()
    local path_sel=get_sel_item_path_from_me(hwnd)  --当前选中的文件路径
    if not path_sel or #path_sel==0 then return end
    local tag=listmetatag[metatagidx]
    for k, v in pairs(path_sel) do
        local chunk=mediadb:match('(FILE \"'..v..'\".-[\n\r])FILE ') or mediadb:match('(FILE \"'..v..'\".+)')  --文件对应的块
        if chunk then
            local valueOld=chunk:match('\"'..tag..':[^\"]+\"') or chunk:match(tag..':%S+')
            local chunkNew
            if mode==1 then  --修改
                chunkNew=valueOld and chunk:gsub(esc(valueOld), '\"'..tag..':'..keyword..'\"') or chunk..'DATA \"'..tag..':'..keyword..'\"'..enter
            elseif mode==2 then  --添加
                local valueOnly=chunk:match('\"'..tag..':([^\"]+)\"') or chunk:match(tag..':(%S+)')
                chunkNew=valueOld and chunk:gsub(esc(valueOld), '\"'..tag..':'..valueOnly..' '..keyword..'\"') or chunk..'DATA \"'..tag..':'..keyword..'\"'..enter
            elseif mode==3 then  --删除
                chunkNew=valueOld and chunk:gsub(esc(valueOld), '') or chunk
            end
            mediadb=mediadb:gsub(esc(chunk), chunkNew)
        end
    end
    local file=io.open(mediadbPath, 'w')
    file:write(mediadb)
    file:close()
    reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 40018, 0, 0, 0)  --显示完整路径
end

function input_keyword()
    local ret, input=reaper.GetUserInputs('请输入关键词', 1, '关键词', '')
    if not ret or input=='' then return end
    gui.board.keyword.value=input
    gui.focus.set_focus()
end
-------------------------------------------------------------------操作相关-------------------------------------------------------------------
local click_keyword={}
click_keyword.left=input_keyword

local click_write={}
click_write.left=function() edit_metadata(gui.drop.edit_method.value, gui.drop.metadata.value, gui.board.keyword.value) end
-------------------------------------------------------------------绘图相关-------------------------------------------------------------------
function gui.main.draw()
	gui.drop.new({
		name='metadata',
		title='Metadata',
		x=10,
		y=80,
		w=135,
		h=28,
		index=listmeta,
        title_update=true,
    })

    gui.drop.new({
		name='edit_method',
		title='操作',
		x=275,
		y=80,
		w=135,
		h=28,
		index=listmethod,
        title_update=true,
    })
    
    gui.board.new({
		name='keyword',
		title='关键词',
		x=10,
		y=15,
		w=400,
		h=50,
		no_label=true,
        action=click_keyword,
        align='C',
	})
	
    gui.button.new({
        name='start_edit',
        x=10,
        y=130,
        w=400,
        h=30,
        r=10,
        title='运行',
        action=click_write,
        colr=0,  --0.45
        colg=0.6,  --0
        colb=1,  --1
    })
    
end
-------------------------------------------------------------------按键相关-------------------------------------------------------------------
function gui.loop.key()
    local key_press=reaper.JS_VKeys_GetState(0.5):byte(13)
    if key_press~=key_press_last then
        if key_press==1 and key_press_last==0 then
            edit_metadata(gui.drop.edit_method.value, gui.drop.metadata.value, gui.board.keyword.value)
        end
        key_press_last=key_press
    end
end
-------------------------------------------------------------------延迟运行-------------------------------------------------------------------
function gui.late.init()
    if not reaper.HasExtState('ReaMetadata', 'set_method') and not reaper.HasExtState('ReaMetadata', 'set_metadata') then return end
    gui.drop.metadata.value=tonumber(reaper.GetExtState('ReaMetadata', 'set_metadata'))
    gui.drop.edit_method.value=tonumber(reaper.GetExtState('ReaMetadata', 'set_method'))
end
-------------------------------------------------------------------退出相关-------------------------------------------------------------------
function gui.exit.save_settings()
    reaper.SetExtState('ReaMetadata', 'set_method', tostring(gui.drop.edit_method.value), true)
    reaper.SetExtState('ReaMetadata', 'set_metadata', tostring(gui.drop.metadata.value), true)
end