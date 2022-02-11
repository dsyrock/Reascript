--[[
ReaScript Name: 搜索助手
Version: 1.0
Author: noiZ
]]

--[[
文本结构：分类名#按钮编号#关键词1|关键词2|......|关键词n
数据结构：  words={分类1，分类2，......，分类n}
            words[分类1]=｛关键词1, 关键词2, ...关键词n｝
            words[分类2]=｛关键词1, 关键词2, ...关键词n｝
            tags={分类1，分类2，......，分类n}
            tags[编号1]=分类1
            tags[编号2]=分类2
]]

function msg(value)
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
end

local config_path=reaper.GetResourcePath()..'/'
config_path=config_path..'/Scripts/DSY_搜索助手.ini'
if not reaper.file_exists(config_path) then
    local file=io.output(config_path)
    file:close()
end

-------------------------------------------------------------------常量-------------------------------------------------------------------
local words={}  --记录路径
local tags={}
local btns={}
local version='V1.0'  --版本号
local line_max, row_max=5, 10  --行，列
local searchWords=''  --搜索内容
local dragFrom=0  --拖拽起始位置

-------------------------------------------------------------------读取配置文件函数-------------------------------------------------------------------
function load_config(config_path)
	local file=io.open(config_path, 'r')
	local content=file:read('*a')
	file:close()
    for line in content:gmatch('[^\n\r]+') do  --读取配置文件
		local name, coor, texts=line:match('([^#]+)#([^#]+)#([^#]+)')
		if name and coor and texts then
			if not words[name] then  --如果遇到新类型
				table.insert(words, name)  --把新类型的名字加到表中
                tags[#tags+1]=name
                words[name]={}    --用新类型名字建立表
                tags[coor]=name
			end
            for keyword in texts:gmatch('[^|]+') do
                table.insert(words[name], keyword)  --把关键词加到表中
            end
		end
    end
end
load_config(config_path)
--------------------------------------------------------------窗口基本参数--------------------------------------------------------------
local w_Title='搜索助手 '..version  --窗口标题
local pad_btn_x=8  --文字与按钮左右边界的距离
local pad_btn_y=5  --文字与按钮上下边界的距离
local gap_btn_btn=20  --按钮与按钮之间的距离
local gap_btn_win_x=25  --按钮与窗口左右的距离
local gap_btn_win_top=100  --按钮与窗口上距离
local gap_btn_win_btm=25  --按钮与窗口下距离
local proj=reaper.GetProjectName(-1, '')  --初始工程

local library=reaper.GetResourcePath()..'/Scripts/DSY_GUI.lua'
dofile(library)

gui.proj_ext='search_helper'

function win_init()
    btns=gui.win.init(w_Title, tags, line_max, row_max, pad_btn_x, pad_btn_y, gap_btn_btn, gap_btn_win_x, gap_btn_win_top, gap_btn_win_btm)
end
win_init()
-------------------------------------------------------------------数据相关-------------------------------------------------------------------
function refresh_ini(path)  --刷新配置文件
    local ini=''
    if #words >0 then
		for i=1, #words do  --遍历所有类型
			local name=words[i]
            local coor
            for k, v in pairs(tags) do--遍历所有类型的坐标
                if type(k)=='string' and v==name then coor=k break end
            end
            ini=ini..name..'#'..coor..'#'..table.concat(words[name], "|")..'\n'
		end
    end
    local file=io.open(path, 'w')
    file:write(ini)
    file:close()
	words, tags, btns={}, {}, {}
	load_config(path)
	win_init()
end

function add_words()  --添加关键词
    local coor=gui.action
    local title_ori=tags[coor] or ''
    local titleNew=title_ori
    local answer_title, answer_word=-1, -1
    local rewrite=false  --是否重写
    if title_ori~='' then  --如果按钮上不是空的
        answer_title=reaper.MB('是否需要修改分类名称', '操作确认', 4)
        answer_word=reaper.MB('是否需要添加关键词', '操作确认', 4)
    end
    if title_ori=='' or answer_title==6 then  --修改分类名称
        local ret, title=reaper.GetUserInputs('请输入标题', 1, '标题', title_ori)
        if ret and title~='' then titleNew=title end
        if ret and not words[title] then
            table.insert(words, title)
            table.insert(tags, coor)
            words[title]={}
            if tags[coor] then  --如果分类已经存在
                for k, v in pairs(words[title_ori]) do  --把原来的分类中的关键词添加到新类型中
                    words[title][k]=v
                end
                words[title_ori]=nil  --删除原来的分类
                for k, v in ipairs(words) do
                    if v==title_ori then
                        table.remove(words, k)--删除原来的分类
                        table.remove(tags, k)--删除原来的分类
                        break
                    end
                end
            end
            tags[coor]=title  --更改分类名称
            rewrite=true
        end
    end
    if title_ori=='' or answer_word==6 then  --添加关键词
        local ret, word=reaper.GetUserInputs('请输入关键词', 1, '多个关键词用空格分隔,extrawidth=300', '')
        if ret and word~='' then
            for single in word:gmatch('%S+') do
                local duplicate=false
                for k, v in pairs(words[titleNew]) do  --检查是否有重复的关键词
                    if single==v then
                        duplicate=true
                        break
                    end
                end
                if not duplicate then
                    table.insert(words[titleNew], single)
                    rewrite=true
                else
                    reaper.MB('关键词已存在', '操作确认', 0)
                end
            end
        end
    end
    if rewrite then refresh_ini(config_path) end  --如果有修改则刷新配置文件
    reaper.JS_Window_SetFocus(gui.focus.hwnd)
end

function del_all_words()  --删除按钮
    local coor=gui.action
    local title=tags[coor]
    if not title then return end  --如果没有分类则返回
    local ret=reaper.MB('是否需要删除该分类下的所有关键词', '操作确认', 4)
    reaper.JS_Window_SetFocus(gui.focus.hwnd)
    if ret==7 then return end
    for k, v in ipairs(words) do
        if v==title then
            table.remove(words, k)
            table.remove(tags, k)
            break
        end
    end
    words[title]=nil
    tags[coor]=nil
    refresh_ini(config_path)
end

function insert_to_search_words(text, need_or)
    if not searchWords:find(text) then
        local connect= need_or and ' OR ' or ' AND '
        searchWords=#searchWords>0 and searchWords..connect..text or text
    end
end

function select_single_word(delete)  --选择或删除单个关键词
    local coor=gui.action
    local title=tags[coor]
    if not title then return end  --如果没有分类则返回
    gfx.x, gfx.y=gfx.mouse_x, gfx.mouse_y
    local idx=gfx.showmenu(table.concat(words[title], '|'))
    if idx==0 then return end
    if not delete then
        insert_to_search_words(words[title][idx])
    else
        if reaper.MB('是否删除关键词\n'..words[title][idx], '操作确认', 4)==7 then reaper.JS_Window_SetFocus(gui.focus.hwnd) return end
        table.remove(words[title], idx)
        refresh_ini(config_path)
        reaper.JS_Window_SetFocus(gui.focus.hwnd)
    end

end

function insert_words(need_or)  --插入关键词
    local coor=gui.action
    local title=tags[coor]
    if not title then return end  --如果没有分类则返回
    local result=#words[title]>1 and '( '..table.concat(words[title], ' OR ')..' )' or words[title][1]
    insert_to_search_words(result, need_or)
end
-------------------------------------------------------------------搜索相关-------------------------------------------------------------------
function start_search(text)
    local title = reaper.JS_Localize("Media Explorer","common")
    local hwnd = reaper.JS_Window_Find(title, true) or reaper.JS_Window_Find(reaper.LocalizeString("Media Explorer", 'explorer', 1 ), true)
    local search = reaper.JS_Window_FindChildByID(hwnd, 1015)
    reaper.JS_Window_SetTitle(search, text)
    reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42051, 0, 0, 0)
    reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42051, 0, 0, 0)
    searchWords=''
end
-------------------------------------------------------------------显示相关-------------------------------------------------------------------
function gui.loop.show_search_words()
    gui.board.search_words.value=searchWords
end
-------------------------------------------------------------------拖拽相关-------------------------------------------------------------------
function drag_from()  --拖拽开始
    local coor=gui.action
    local title=tags[coor]
    if not title then return end  --如果没有分类则返回
    dragFrom=gui.action
end

function drag_to()  --拖拽结束
    if dragFrom==0 then return end  --如果没有拖拽则返回
    local coor1=dragFrom
    local coor2=gui.hover(btns)  --获取当前鼠标所在位置
    if coor1==coor2 then dragFrom=0 return end
    local name_from, name_to=tags[coor1], tags[coor2]
    if name_from then
		tags[coor2]=name_from
		if not name_to then tags[coor1]=nil end
	end
	if name_to then
		tags[coor1]=name_to
		if not name_from then tags[coor2]=nil end
	end
    dragFrom=0
    refresh_ini(config_path)
end
-------------------------------------------------------------------画图相关-------------------------------------------------------------------
local click_keyword={}
click_keyword.left=insert_words
click_keyword.ctrl=select_single_word
click_keyword.shift=function() insert_words(true) end
click_keyword.ctrlshift=drag_to
click_keyword.ctrlshifthold=drag_from
click_keyword.alt=del_all_words
click_keyword.right=add_words
click_keyword.ctrlright=function() select_single_word(true) end

local click_search={}
click_search.left=function() start_search(searchWords) end

local click_search_words={}
click_search_words.right=function() searchWords='' end

function gui.main.drawing()
    for k, v in pairs(btns) do
        gui.button.new({
            name=k,
            x=k==dragFrom and gfx.mouse_x or v.x,
            y=k==dragFrom and gfx.mouse_y or v.y,
            w=v.w,
            h=v.h,
            r=v.r,
            title=v.name,
            action=click_keyword,
            colr=1,  --0.45
            colg=0.6,  --0
            colb=0,  --1
            text_colr=tags[k] and 0 or 0.5,
            text_colg=tags[k] and 0 or 0.5,
            text_colb=tags[k] and 0 or 0.5,
            redraw=k==dragFrom or false,
        })
	end

    gui.button.new({
        name='search',
        x=20,
        y=55,
        w=gui.win.w-40,
        h=30,
        r=10,
        title='开始搜索',
        action=click_search,
        colr=0,  --0.45
        colg=0.6,  --0
        colb=1,  --1
    })
    
    gui.board.new({
		name='search_words',
		title=searchWords,
		x=20,
		y=15,
		w=gui.win.w-40,
		h=30,
		no_label=true,
        action=click_search_words,
	})
	
end