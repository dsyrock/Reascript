--[[
ReaScript Name: 一键导出
Version: 1.0
Author: noiZ
]]

local debug=0

function msg(value)

    if debug==1 then reaper.ShowConsoleMsg(tostring(value) .. "\n") end

end

-------------------------------------------------------------------常量定义-------------------------------------------------------------------
local shadow_dist=2

local queue_state=false

local queue={}

local click_idx=0  --记录点击的按钮编号

local lang='chn'

local version='v1.3'  --版本号

--------------------------------------------------------------读取预置文件------------------------------------------------------------------------------------
local sep=reaper.GetOS():find('Win') and '\\' or '/'
local check_, render_path=reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', '', 0)
if not check and render_path=='' then render_path=reaper.GetProjectPath('')..sep end

local config_path=reaper.GetResourcePath()  --获取预置文件路径

config_path=config_path..'/reaper-render.ini'  --补全预置文件路径

local file=io.open(config_path)  --读取预置文件路径

local text=file:read('all')  --读取预置文件所有内容

file:close()

local preset_flag={}  --分类储存预置文件内容

local name_len=0  --记录预置名字最长的长度

local name_longest

for v in text:gmatch('<[^>]+>[^<]+OUTPUT[^<]+') do

	local name1, name2

	local sr, channel, render_mode, sr_use, resam, dither, code, bound, edl, edr, source, pattern, tail

	if not v:find('[\'\"]') then

		name1=v:match('RENDERPRESET (%S+) %d+')

		name2=v:match('OUTPUT (%S+) %d+')

		if name1==name2 then 
			msg(name1)
			sr, channel, render_mode, sr_use, resam, dither, code, bound, edl, edr, source, pattern, tail=v:match('<RENDERPRESET %S+ (%d+) (%d+) (%d+) (%d+) (%d+) (%d+)%s?%d?%s+(%S+)[^>]+>[^>]+OUTPUT %S+ (%d+) (%S+) (%S+) (%d+) %d+ (%S+) (%d+)') 
		
		end

	else

		name1=v:match('RENDERPRESET [\'\"]+([^\"\']+)[\'\"]+ %d+')

		name2=v:match('OUTPUT [\'\"]+([^\"\']+)[\'\"]+ %d+')

		if name1==name2 then 
			msg(name1)
			sr, channel, render_mode, sr_use, resam, dither, code, bound, edl, edr, source, pattern, tail=v:match('<RENDERPRESET [\'\"]+[^\"\']+[\'\"]+ (%d+) (%d+) (%d+) (%d+) (%d+) (%d+)%s?%d?%s+(%S+)[^>]+>[^>]+OUTPUT [\'\"]+[^\"\']+[\'\"]+ (%d+) (%S+) (%S+) (%d+) %d+ (%S+) (%d+)') 
		
		end

	end
	
	if sr then
		msg(sr) msg(channel) msg(render_mode) msg(sr_use) msg(resam) msg(dither) msg(code) msg(bound) msg(edl) msg(edr) msg(source) msg(pattern) msg(tail)	
		preset_flag[#preset_flag+1]={name=name1, sr=sr, channel=channel, sr_use=sr_use, dither=dither, code=code, bound=bound, edl=edl, edr=edr, source=source, pattern=pattern, tail=tail, path=render_path}

		if name1:len()>name_len then

			name_longest=name1  --保留预置名字最长的名字

			name_len=name1:len()  --保留预置名字最长的长度

		end

		table.insert(queue, false)
		
	end

end

--------------------------------------------------------------窗口基本参数--------------------------------------------------------------

local w_Title  --窗口标题

if lang=='chn' then w_Title = "一键导出 "..version else w_Title = "Render Preset "..version end

local pad_btn_x=5  --文字与按钮左右边界的距离

local pad_btn_y=5  --文字与按钮上下边界的距离

local gap_btn_btn=20  --按钮与按钮之间的距离

local gap_btn_win_x=50  --按钮与左右边界的距离

local gap_btn_win_y=50  --按钮与左右边界的距离

gfx.setfont(1, "arial", 28, 98)

local w_est, h_est=gfx.measurestr(name_longest)  --获取名字的宽和高

local w_btn, h_btn, r_btn=w_est+2*pad_btn_x, h_est+2*pad_btn_y, 10  --计算按钮的宽、高和半径

local w_win, h_win=w_btn+2*gap_btn_win_x, h_btn*#preset_flag+gap_btn_btn*(#preset_flag-1)+2*gap_btn_win_y  --计算窗口的宽和高

local x_win, y_win=(1920-w_win)/2, (1080-h_win)/2  --窗口左上角坐标，让窗口出现在屏幕中间(仅限屏幕分辨率为1920*1080)

local btns={}  --计算每个按钮的参数

for i=1, #preset_flag do

	local x, y=gap_btn_win_x, gap_btn_win_y+(h_btn+gap_btn_btn)*(i-1)  --计算每个按钮的坐标

	local w, h=gfx.measurestr(preset_flag[i].name)

	local x_cap, y_cap=x+(w_btn-w)/2, y+(h_btn-h)/2

	btns[#btns+1]={x=x, y=y, x_cap=x_cap, y_cap=y_cap, name=preset_flag[i].name, ed_x=x+w_btn, ed_y=y+h_btn}  --储存每个按钮的坐标 文字和边界

end

-------------------------------------------------------------- 窗口初始化 -----------------------------------------
local red=16777471

gfx.clear=4210752  --背景颜色

gfx.init( w_Title, w_win, h_win, 0, x_win,y_win )  --窗口初始化

--------------------------------------------------------------圆角矩形--------------------------------------------------------------
function roundrect(x, y, w, h, r, antialias, fill)
	
	local aa = antialias or 1
	fill = fill or 0
	
	if fill == 0 or false then
		gfx.roundrect(x, y, w, h, r, aa)
	elseif h >= 2 * r then
		
		-- Corners
		gfx.circle(x + r, y + r, r, 1, aa)		-- top-left
		gfx.circle(x + w - r, y + r, r, 1, aa)		-- top-right
		gfx.circle(x + w - r, y + h - r, r , 1, aa)	-- bottom-right
		gfx.circle(x + r, y + h - r, r, 1, aa)		-- bottom-left
		
		-- Ends
		gfx.rect(x, y + r, r, h - r * 2)
		gfx.rect(x + w - r, y + r, r + 1, h - r * 2)
			
		-- Body + sides
		gfx.rect(x + r, y, w - r * 2, h + 1)
		
	else
	
		r = h / 2 - 1
	
		-- Ends
		gfx.circle(x + r, y + r, r, 1, aa)
		gfx.circle(x + w - r, y + r, r, 1, aa)
		
		-- Body
		gfx.rect(x + r, y, w - r * 2, h)
		
	end	
	
end

---------------------------------------------------------------窗口主程序---------------------------------------------------------------
function main()

	for k, v in pairs(btns) do
	
		gfx.set(0.5, 0.5, 0.5, 1)  --灰色

		roundrect(v.x, v.y, w_btn, h_btn, r_btn, true, true)  --画出按钮

		gfx.set(0, 0, 0, 1)  --黑色

		for i=1, shadow_dist do  --画出阴影

			gfx.x, gfx.y = v.x_cap + i, v.y_cap + i

			gfx.drawstr(v.name)

		end

		gfx.set(1, 1, 1, 1)  --白色

		gfx.x, gfx.y=v.x_cap, v.y_cap

		gfx.drawstr(v.name)  --画出按钮标题

	end

    if gfx.getchar()>=0 then reaper.defer(main) end

end

main()

--------------------------------------------------------------导出函数--------------------------------------------------------------
function render(preset_index)

    reaper.CSurf_OnPlayRateChange(1)

    reaper.GetSetProjectInfo(0, 'RENDER_SETTINGS', preset_flag[preset_index].source, true)  --source

    reaper.GetSetProjectInfo(0, 'RENDER_BOUNDSFLAG', preset_flag[preset_index].bound, true)  --bound

    reaper.GetSetProjectInfo(0, 'RENDER_CHANNELS', preset_flag[preset_index].channel, true)  --channel

    reaper.GetSetProjectInfo(0, 'RENDER_SRATE', preset_flag[preset_index].sr, true)  --sample rate

    reaper.GetSetProjectInfo(0, 'RENDER_STARTPOS', preset_flag[preset_index].edl, true)  --start pos

    reaper.GetSetProjectInfo(0, 'RENDER_ENDPOS', preset_flag[preset_index].edr, true)  --end pos

    reaper.GetSetProjectInfo(0, 'RENDER_TAILFLAG', preset_flag[preset_index].tail, true)  --tail flag

    reaper.GetSetProjectInfo(0, 'RENDER_DITHER', preset_flag[preset_index].dither, true)  --DITHER

    reaper.GetSetProjectInfo(0, 'PROJECT_SRATE_USE', preset_flag[preset_index].sr_use, true)  --sample rate use

    reaper.GetSetProjectInfo_String(0, 'RENDER_FILE', preset_flag[preset_index].path, true)  --render path

    reaper.GetSetProjectInfo_String(0, 'RENDER_PATTERN', preset_flag[preset_index].pattern, true)  --render pattern

    reaper.GetSetProjectInfo_String(0, 'RENDER_FORMAT', preset_flag[preset_index].code, true)  --render format
    
    reaper.Main_OnCommand(42230, 0)  --render using recent setting   auto close dialog
        
end

function render_queue()

	queue_state=false

	for k, v in pairs(queue) do

		if v then

			render(k)

			queue[k]=false

		end

	end

end
-------------------------------------------------------------------添加Action-------------------------------------------------------------------
function add_action(idx)

	local script_path=reaper.GetResourcePath()  --获取脚本文件夹路径

	local script_name='DSY_导出预置_'..btns[idx].name..'.lua'

	if lang=='chn' then script_name='DSY_导出预置_'..btns[idx].name..'.lua' else script_name='DSY_Render_Preset_'..btns[idx].name..'.lua' end

	script_path=script_path..'/Scripts/'..script_name  --补全脚本文件路径

	local file=io.output(script_path)  --读取脚本文件路径

	local path=reaper.GetOS():find('Win') and preset_flag[idx].path..'\\' or preset_flag[idx].path
	file:write('reaper.CSurf_OnPlayRateChange(1)\n')
	file:write('reaper.GetSetProjectInfo(0, \'RENDER_SETTINGS\', '..preset_flag[idx].source..', true)\n')
	file:write('reaper.GetSetProjectInfo(0, \'RENDER_BOUNDSFLAG\', '..preset_flag[idx].bound..', true)\n')
	file:write('reaper.GetSetProjectInfo(0, \'RENDER_CHANNELS\', '..preset_flag[idx].channel..', true)\n')
	file:write('reaper.GetSetProjectInfo(0, \'RENDER_SRATE\', '..preset_flag[idx].sr..', true)\n')
	file:write('reaper.GetSetProjectInfo(0, \'RENDER_STARTPOS\', '..preset_flag[idx].edl..', true)\n')
	file:write('reaper.GetSetProjectInfo(0, \'RENDER_ENDPOS\', '..preset_flag[idx].edr..', true)\n')
	file:write('reaper.GetSetProjectInfo(0, \'RENDER_TAILFLAG\', '..preset_flag[idx].tail..', true)\n')
	file:write('reaper.GetSetProjectInfo(0, \'RENDER_DITHER\', '..preset_flag[idx].dither..', true)\n')
	file:write('reaper.GetSetProjectInfo(0, \'PROJECT_SRATE_USE\', \''..preset_flag[idx].sr_use..'\', true)\n')
	file:write('reaper.GetSetProjectInfo_String(0, \'RENDER_FILE\', \''..path..'\', true)\n')
	file:write('reaper.GetSetProjectInfo_String(0, \'RENDER_PATTERN\', \''..preset_flag[idx].pattern..'\', true)\n')
	file:write('reaper.GetSetProjectInfo_String(0, \'RENDER_FORMAT\', \''..preset_flag[idx].code..'\', true)\n')
	file:write('reaper.Main_OnCommand(42230, 0)')

	file:close()

	reaper.AddRemoveReaScript(true, 0, script_path, true)

	if lang=='chn' then

		reaper.MB('已添加Action:\n'..script_name..'\n到Action List中', '操作成功', 0)

	else

		reaper.MB('Add action:\n'..script_name..'\nto Action List', 'Done', 0)

	end

end

-------------------------------------------------------------------添加边框-------------------------------------------------------------------
function frame(idx, times, color)

	if color=='red' then

		gfx.set(1, 0, 0, 1)  --红色

	elseif color=='green' then

		gfx.set(0, 1, 0, 1)  --绿色

	elseif color=='blue' then

		gfx.set(0, 0, 1, 1)  --蓝色

	end

	for i=1, times do

		gfx.roundrect(btns[idx].x-(i-1), btns[idx].y-(i-1), w_btn+2*(i-1), h_btn+2*(i-1), r_btn, true)  --画出按钮边框外围

	end

end

function frame_cons()

	for k, v in pairs(queue) do

		if v then frame(k, 3, 'blue') end

	end

    if gfx.getchar()>=0 then reaper.defer(frame_cons) end

end

--------------------------------------------------------------检测用户输入--------------------------------------------------------------
function check_mouse_position()  --检测鼠标位置处于哪个按键上

	local index

	for k, v in pairs(btns) do

		if gfx.mouse_x>v.x and gfx.mouse_x<v.ed_x and gfx.mouse_y>v.y and gfx.mouse_y<v.ed_y then

			index=k

			break

		end

	end

	return index

end

function check_input()  --检测鼠标按键情况

	if gfx.mouse_cap==0 then  

		if queue_state==true then render_queue() end

	end

	local idx=check_mouse_position()

	if idx then 

		if gfx.mouse_cap==0 then  --没有按键

			frame(idx, 3, 'red')

		elseif gfx.mouse_cap==1 then  --按下左键

			render(idx)

		elseif gfx.mouse_cap==4 then  --按下ctrl

			frame(idx, 3, 'green')

		elseif gfx.mouse_cap==5 then  --ctrl+左键

			add_action(idx)

		elseif gfx.mouse_cap==8 then  --按下shift

			queue_state=true

			if click_idx>0 then queue[idx]=not queue[idx] end

			click_idx=0

			frame(idx, 1, 'blue')

		elseif gfx.mouse_cap==9 then  --shift+左键

			click_idx=idx

		end

		gfx.set(1, 1, 1, 1)

		gfx.x, gfx.y=5, 5

		local head

		if lang=='chn' then head='预置: ' else head='Preset: ' end

		gfx.drawstr(head..btns[idx].name)

	end

    if gfx.getchar()>=0 then reaper.defer(check_input) end

end

check_input()

frame_cons()