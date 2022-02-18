--@description DSY_GUI
--@version 1.0
--@author noiZ
--@provides [data] .

--[[
运作流程
脚本先调用本库，提前加载了各个基本变量
脚本执行gui.win函数创建窗体
窗体执行main函数，建立一个defer，并等待gui.main和gui.loop中获取到的内容并执行
脚本向库添加各main和loop函数，用于画图或持续性的功能函数

重新改变画图方式
gui.drawlist第一层，记录下每个控件类型的名字
gui.drawlist={'knob', 'slider', 'toggle', 'drop', 'button', 'board', 'label'}
gui.drawlist.knob.第二层，记录下每个控件需要绘制的内容
gui.drawlist.knob.name=t  name是knob类型下每个knob的名字，t是这个knob的参数
再调用对应各个控件的画图函数绘制 gui.draw.knob[t]
]]

gui={state='idle'}
gui.main={}
gui.loop={}
gui.late={}
gui.subloop={}
gui.win={}
gui.draw={}  --画图相关函数
gui.drawlist={'knob', 'slider', 'toggle', 'drop', 'button', 'board', 'label'}  --画图数据
gui.redraw=false  --刷新开关
gui.clean_all=false  --清除全部元素开关
gui.sub=false  --子窗口开启情况
gui.hotkey={}
gui.empty_action={}  --点击窗体空白处运行的函数
gui.running=false  --运行状态
gui.key=0  --按键检测
gui.focus={auto=false, lost=false, title='', hwnd=''}  --焦点相关
gui.__index=gui
gui.showkey=false  --是否显示按键编码
gui.exit={}  --退出时运行的函数

function gui.new()
	local class={}
	setmetatable(class, gui)
	return class
end

local font_size_btn=18  --按钮字体大小
local font_size_setup=14  --设置按钮字体大小
local font_size_big=16  --设置信息字体大小
local font_size_label=32  --标签字体大小
gfx.setfont(1, "arial", font_size_btn, 98)
gfx.setfont(2, "arial", font_size_setup)
gfx.setfont(3, "arial", font_size_big)
gfx.setfont(4, "Calibri", font_size_label, 98)
gui.font_idx={1, 2, 3, 4}
local pi=math.rad(180)

-------------------------------------------------------------------通用-------------------------------------------------------------------
function init_drawlist()
	for k, v in ipairs(gui.drawlist) do  --v是控件类型名字: button knob
		if gui.drawlist[v] then
			for k1, v1 in pairs(gui.drawlist[v]) do
				gui[v][k1]=nil  --清空已有的控件数据
			end
		end
		gui.drawlist[v]=nil
		gui.drawlist[v]={}  --初始化或清空drawlist
	end
end
init_drawlist()

function gui.is_in_area(x, y, w, h)  --判断是否在图形内
	if type(h)=='number' then
		return gfx.mouse_x>x and gfx.mouse_x<x+w and gfx.mouse_y>y and gfx.mouse_y<y+h
	else
		return gfx.mouse_x>x-w and gfx.mouse_x<x+w and gfx.mouse_y>y-w and gfx.mouse_y<y+w
	end
end

function gui.get_mouse_state(name, x, y, w, h, action_input, list)
	local ret=''
	local check=gui.is_in_area(x, y, w, type(h)~='table' and h or false)
	local action=type(h)=='table' and h or action_input
	if gfx.mouse_cap==0 then
		if gui.state=='left_'..name then
			ret='LEFTUP'
			gui.state='idle'
			gui.action=name
			if list then
				gfx.x, gfx.y=gfx.mouse_x, gfx.mouse_y
				gui.drop[name].value=gfx.showmenu(table.concat(list, '|'))
			end
			if action and action.left then action.left() end
		elseif gui.state=='right_'..name then
			ret='RIGHTUP'
			gui.state='idle'
			gui.action=name
			if action and action.right then action.right() end
		elseif gui.state=='ctrl' or gui.state=='shift' or gui.state=='alt' or gui.state=='ctrlshift' or gui.state=='ctrlalt' then
			gui.state='idle'
		elseif gui.state=='middle_'..name then
			ret='MIDDLEUP'
			gui.state='idle'
			gui.action=name
			if action and action.middle then action.middle() end
		end
	elseif gfx.mouse_cap==1 then
		if gui.state=='idle' and check then
			gui.state='left_'..name
			ret='LEFTDOWN'
		elseif gui.state=='left_'..name then
			ret='LEFTHOLD' 
			if action and action.lefthold then action.lefthold() end
		end 
	elseif gfx.mouse_cap==2 then
		if gui.state=='idle' and check then
			gui.state='right_'..name
			ret='RIGHTDOWN'
		elseif gui.state=='right_'..name then
			ret='RIGHTHOLD'
		end
	elseif gfx.mouse_cap==4 then
		if gui.state=='idle' then
			ret='CTRL'
			gui.state='ctrl'
		elseif gui.state=='ctrlleft_'..name then
			ret='CTRLLEFTUP'
			gui.state='ctrl'
			gui.action=name
			if list then
				gfx.x, gfx.y=gfx.mouse_x, gfx.mouse_y
				gui.drop[name].value=gfx.showmenu(table.concat(list, '|'))
			end
			if action and action.ctrl then action.ctrl() end
		elseif gui.state=='ctrlright_'..name then
			ret='CTRLRIGHTUP'
			gui.state='ctrl'
			gui.action=name
			if action and action.ctrlright then action.ctrlright() end
		end
	elseif gfx.mouse_cap==5 then
		if (gui.state=='ctrl' or gui.state=='idle') and check then
			gui.state='ctrlleft_'..name
			ret='CTRLLEFTDOWN'
		elseif gui.state=='ctrlleft_'..name then
			ret='CTRLLEFTHOLD'
		end
	elseif gfx.mouse_cap==6 then
		if gui.state=='ctrl' and check then
			gui.state='ctrlright_'..name
			ret='CTRLRIGHTDOWN'
		elseif gui.state=='ctrlright_'..name then
			ret='CTRLRIGHTHOLD'
		end
	elseif gfx.mouse_cap==8 then
		if gui.state=='idle' then
			ret='SHIFT'
			gui.state='shift'
		elseif gui.state=='shiftleft_'..name then
			ret='SHIFTLEFTUP'
			gui.state='shift'
			gui.action=name
			if list then
				gfx.x, gfx.y=gfx.mouse_x, gfx.mouse_y
				gui.drop[name].value=gfx.showmenu(table.concat(list, '|'))
			end
			if action and action.shift then action.shift() end
		end
	elseif gfx.mouse_cap==9 then
		if (gui.state=='shift' or gui.state=='idle') and check then
			gui.state='shiftleft_'..name
			ret='SHIFTLEFTDOWN'
		elseif gui.state=='shiftleft_'..name then
			ret='SHIFTLEFTHOLD'
		end
	elseif gfx.mouse_cap==12 then
		if gui.state=='idle' or gui.state=='ctrl' or gui.state=='shift' then
			ret='CTRLSHIFT'
			gui.state='ctrlshift'
		elseif gui.state=='ctrlshiftleft_'..name then
			ret='CTRLSHIFTLEFTUP'
			gui.state='ctrlshift'
			gui.action=name
			if list then
				gfx.x, gfx.y=gfx.mouse_x, gfx.mouse_y
				gui.drop[name].value=gfx.showmenu(table.concat(list, '|'))
			end
			if action and action.ctrlshift then action.ctrlshift() end
		end
	elseif gfx.mouse_cap==13 then
		if (gui.state=='ctrlshift' or gui.state=='idle') and check then
			gui.state='ctrlshiftleft_'..name
			ret='CTRLSHIFTLEFTDOWN'
			-- gui.action=name
			if action and action.ctrlshiftdown then action.ctrlshiftdown() end
		elseif gui.state=='ctrlshiftleft_'..name then
			ret='CTRLSHIFTLEFTHOLD'
			gui.action=name
			if action and action.ctrlshifthold then action.ctrlshifthold() end
		end
	elseif gfx.mouse_cap==16 then
		if gui.state=='idle' then
			ret='ALT'
			gui.state='alt'
		elseif gui.state=='altleft_'..name then
			ret='ALTLEFTUP'
			gui.state='alt'
			gui.action=name
			if list then
				gfx.x, gfx.y=gfx.mouse_x, gfx.mouse_y
				gui.drop[name].value=gfx.showmenu(table.concat(list, '|'))
			end
			if action and action.alt then action.alt() end
		end
	elseif gfx.mouse_cap==17 then
		if (gui.state=='alt' or gui.state=='idle') and check then
			gui.state='altleft_'..name
			ret='ALTLEFTDOWN'
		elseif gui.state=='altleft_'..name then
			ret='ALTLEFTHOLD'
		end
	elseif gfx.mouse_cap==20 then
		if gui.state=='idle' or gui.state=='ctrl' or gui.state=='alt' then
			ret='CTRLALT'
			gui.state='ctrlalt'
		elseif gui.state=='ctrlaltleft_'..name then
			ret='CTRLALTLEFTUP'
			gui.state='ctrlalt'
			gui.action=name
			if list then
				gfx.x, gfx.y=gfx.mouse_x, gfx.mouse_y
				gui.drop[name].value=gfx.showmenu(table.concat(list, '|'))
			end
			if action and action.ctrlalt then action.ctrlalt() end
		end
	elseif gfx.mouse_cap==21 then
		if (gui.state=='ctrlalt' or gui.state=='idle') and check then
			gui.state='ctrlaltleft_'..name
			ret='CTRLALTLEFTDOWN'
		elseif gui.state=='ctrlaltleft_'..name then
			ret='CTRLALTLEFTHOLD'
		end
	elseif gfx.mouse_cap==64 then
		if gui.state=='idle' and check then
			gui.state='middle_'..name
			ret='MIDDLEDOWN'
		elseif gui.state=='middle_'..name then
			ret='MIDDLEHOLD'
		end
	end
	return ret
end

function gui.loop.get_mouse_state()
	if gfx.mouse_cap==0 then
		if gui.state=='click_empty_left' then
			if gui.empty_action and gui.empty_action.left then gui.empty_action.left() end
			gui.state='idle' 
		elseif gui.state=='click_empty_right' then
			if gui.empty_action and gui.empty_action.right then gui.empty_action.right() end
			gui.state='idle' 
		end
	elseif gfx.mouse_cap==1 then
		if gui.state=='idle' then
			gui.state='click_empty_left'
		end
	elseif gfx.mouse_cap==2 then
		if gui.state=='idle' then
			gui.state='click_empty_right'
		end
	end
end

function gui.hover(t)
	local coor
	for k, v in pairs(t) do
		if gui.is_in_area(v.x, v.y, v.w, v.h) then
            coor=k
			break
		end
	end
	return coor
end

function gui.value_limitation(value, min, max)
	return value>=min and value<=max and value or value<min and min or value>max and max
end

function gui.value_convert(value, value_min, value_max, x_min, x_max)  --相对值的换算
	local x=(value-value_min)*(x_max-x_min)/(value_max-value_min)+x_min
	return gui.value_limitation(x, x_min, x_max)
end

function gui.split_words(s)  --分割字符串
	local tb = {}
	for utfChar in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
		table.insert(tb, utfChar)
	end
	return tb
end

function gui.text(x, y, content, size, position, color, colorr, colorg, colorb, font_name, size_ori, w, h)  --字符
    gfx.setfont(size)
    local w_t, h_t=gfx.measurestr(content)
	local idx_temp
	if w and w_t>=w or h and h_t>=h then
		idx_temp=gui.font_idx[#gui.font_idx]+1
		gui.font_idx[#gui.font_idx+1]=idx_temp
		local size_temp=size_ori
		while w and w_t>=w or h and h_t>=h do
			size_temp=size_temp-1
			if size_temp==0 then break end
			gfx.setfont(idx_temp, font_name, size_temp)
			w_t, h_t=gfx.measurestr(content)
		end
	end

    if position=='C' then
        gfx.x, gfx.y=x-w_t/2, y-h_t/2
    elseif position=='R' then
        gfx.x, gfx.y=x-w_t, y-h_t/2
    elseif position=='L' then
        gfx.x, gfx.y=x, y-h_t/2
    end
    if not color then
        gfx.set(1, 1, 1, 1)
    elseif color=='black' then
		gfx.set(0, 0, 0, 1)
	else
		gfx.set(color, colorg, colorb)
    end
	gfx.drawstr(content)
	return idx_temp
end

function gui.roundrect(x, y, w, h, r, antialias, fill, mode)  --圆角矩形
	local aa = antialias or 1
    fill = fill or 0
	if fill == 0 or false then
		gfx.roundrect(x, y, w, h, r, aa)
	elseif h >= 2 * r then
		gfx.circle(x + r, y + r, r, 1, aa)		-- top-left
		if w>r*2 and mode~='left' then gfx.circle(x + w - r, y + r, r, 1, aa) end  -- top-right
		if w>r*2 and mode~='left' then gfx.circle(x + w - r, y + h - r, r , 1, aa) end  -- bottom-right
		gfx.circle(x + r, y + h - r, r, 1, aa)		-- bottom-left
		gfx.rect(x, y + r, r, h - r * 2)
		gfx.rect(x + w - r, y + r, r + 1, h - r * 2)
		gfx.rect(x + r, y, w - r * 2, h + 1)
	else
		r = h / 2 - 1
		gfx.circle(x + r, y + r, r, 1, aa)
		if x+w-r>x+r and mode~='left' then gfx.circle(x + w - r, y + r, r, 1, aa) end
		gfx.rect(x + r, y, w - r * 2, h)
	end	
end

function gui.draw_btn(x, y, w, h, r, colr, colg, colb, fill)
	gfx.set(colr, colg, colb)
	gui.roundrect(x, y, w, h, r, true, fill)  --画出按钮
end

function gui.frame(x, y, w, h, r, times, colr, colg, colb)
	gfx.set(colr, colg, colb, 1)  --蓝色
	local x1, y1, x2, y2, x3, y3, x4, y4=x-w/2, y-h/2, x+w/2, y-h/2, x-w/2, y+h/2, x+w/2, y+h/2
	for i=1, times*10 do
		gfx.arc(x1-i*0.1, y1-i*0.1, r, -pi/2, 0, 1)
		gfx.arc(x2+i*0.1, y2-i*0.1, r, 0, pi/2, 1)
		gfx.arc(x3-i*0.1, y3+i*0.1, r, pi*1.5, pi, 1)
		gfx.arc(x4+i*0.1, y4+i*0.1, r, pi, pi/2, 1)
	end
end

function gui.clear(buf, gfx_dest, w, h)
    -- local w = w or gfx.w
    -- local h = h or gfx.h
    gfx.setimgdim(buf, -1, -1) -- clear buffer
    gfx.setimgdim(buf, gfx.w, gfx.h)
    gfx.dest = gfx_dest
end

function gui.redrawAll()  --重新绘制函数
	for k, v in ipairs(gui.drawlist) do  --v是控件类型名字
		local list=gui.drawlist[v]  --各个控件下的全部绘制内容
		for k1, v1 in pairs(list) do  --k1是控件名字 v1是控件的绘制参数
			gui.draw[v](v1)  --gui.draw[v]是每个控件的绘画函数
		end
	end
end

function gui.blit(buf, opt_gfx_dest, opt_dest_w, opt_dest_h)
	opt_gfx_dest = opt_gfx_dest or -1
	opt_dest_w, opt_dest_h = gfx.w or 0, gfx.h or 0
	local img_w, img_h = gfx.getimgdim(buf)
	if img_w > 0 and img_h > 0 then
		-- gfx.mode = -1
		gfx.a = 1
		gfx.dest = opt_gfx_dest;
		-- gfx.x, gfx.y = 0, 0
		gfx.blit(buf, 1, 0, 0, 0, img_w, img_h, 0, 0, opt_dest_w, opt_dest_h)
	end
end
-------------------------------------------------------------------旋钮-------------------------------------------------------------------
gui.knob=gui.new()

function gui.knob.calc(r, min, max, y_st, arc_st)  --计算移动距离与填充变化关系
	local arc=arc_st-(gfx.mouse_y-y_st)*(max-min)/r  --dv/dy=(max-min)/r  移动距离与数值变化量成比例
	if arc<min then
		arc=min
	elseif arc>max then
		arc=max
	end
	return arc
end

function gui.draw.knob(t)
	local tt=gui.knob[t.name]

	--旋钮
	gfx.set(1, 1, 1, 1)
	gfx.circle(t.x, t.y, t.r, 1, 1)

	--填充
	local min, max=-pi*0.75, pi*0.75
	local knob_st=t.both and 0 or min
    if not t.no_fill then
        gfx.set(1, 0.6, 0, 1)
        local fill_w=t.r/5
        for i=1, fill_w*2.5 do
            gfx.arc(t.x, t.y, t.r+t.d+i*0.4, knob_st, tt.arc_now or tt.arc_st, 1)
        end
    end

	--指针
    local ind_r=t.r*0.1
    local ind_d=t.r*0.7
	local ind_x, ind_y=t.x+math.sin(tt.arc_now or tt.arc_st)*ind_d, t.y-math.cos(tt.arc_now or tt.arc_st)*ind_d
	local ind_x0, ind_y0=ind_x+math.sin(tt.arc_now or tt.arc_st)*ind_r, ind_y-math.cos(tt.arc_now or tt.arc_st)*ind_r
	local ang1=(tt.arc_now or tt.arc_st)+math.rad(-120)
	local ang2=(tt.arc_now or tt.arc_st)+math.rad(120)
	local ind_x1, ind_y1=ind_x+math.sin(ang1)*ind_r, ind_y-math.cos(ang1)*ind_r
	local ind_x2, ind_y2=ind_x+math.sin(ang2)*ind_r, ind_y-math.cos(ang2)*ind_r
	gfx.set(0, 0, 0, 1)
    gfx.triangle(ind_x0, ind_y0, ind_x1, ind_y1, ind_x2, ind_y2)
    gfx.triangle(ind_x0, ind_y0, ind_x1, ind_y1, ind_x2, ind_y2)
    gfx.triangle(ind_x0, ind_y0, ind_x1, ind_y1, ind_x2, ind_y2)
    gfx.triangle(ind_x0, ind_y0, ind_x1, ind_y1, ind_x2, ind_y2)

    --刻度
    if not t.no_scale then
        local scale_d=fill_w or t.r/5+t.r*0.2+t.r
        local scale_r=t.r/50
        gfx.set(1, 1, 1, 1)
        for i=min, max, pi/6 do 
            local x1, y1=t.x+math.sin(i)*scale_d, t.y-math.cos(i)*scale_d
            gfx.circle(x1, y1, scale_r, 1, 1)
        end
    end

    --标签显示
    if not t.no_label then gui.text(t.x, t.y+t.r*1.3, t.title, 1, 'C') end

    --数值显示
    if not t.no_value then gui.text(t.x, t.y, string.format("%0.2f", tt.value), 1, 'C', 'black') end
end

function gui.knob.new(t)
	local init=t.redraw or false
	if not gui.knob[t.name] then
		init=true
		gui.knob[t.name]={min=t.min, max=t.max, last={value=-65536}, master={}}
	end
	local tt=gui.knob[t.name]
	gui.drawlist.knob[t.name]=t

	--填充
	local min, max=-pi*0.75, pi*0.75
	local knob_st=t.both and 0 or min
	if not tt.value then
		tt.value=t.start  --初始化
	else
		tt.value=gui.value_limitation(tt.value, tt.min, tt.max)
	end
	tt.arc_now=gui.value_convert(tt.value, tt.min, tt.max, min, max)
	tt.arc_st=not tt.arc_st and tt.arc_now or tt.arc_st  --鼠标按下时的弧度起点

	--判断鼠标位置
	local mouse=gui.get_mouse_state(t.name, t.x, t.y, t.r, t.action)

	if mouse=='LEFTUP' then
		tt.arc_st=tt.arc_now
	elseif mouse=='LEFTDOWN' then
		tt.y_st=gfx.mouse_y
	elseif mouse=='LEFTHOLD' then
		tt.arc_now=gui.knob.calc(150, min, max, tt.y_st, tt.arc_st)
		tt.value=gui.value_convert(tt.arc_now, min, max, tt.min, tt.max)
	elseif mouse=='' and tt.master.value then
		if tt.master.value~=tt.value then  --以外部数据影响图形
			tt.value=gui.value_limitation(tt.master.value, tt.min, tt.max)
			tt.arc_now=gui.value_convert(tt.value, tt.min, tt.max, min, max)  
			tt.arc_st=tt.arc_now
		end
	end

	if init or tt.last.value~=tt.value then  --图形需更新
		gui.redraw=true
		tt.last.value=tt.value
	end
end

-------------------------------------------------------------------滑动条-------------------------------------------------------------------
gui.slider=gui.new()

function gui.draw.slider(t)
	local tt=gui.slider[t.name]

	--画线
	
	gfx.set(1, 1, 1, 1)
	gui.roundrect(t.x, t.y-t.r/2, t.length, t.r, t.r/2, 1, 0)

	gfx.set(0, 1, 0, 1)
	gui.roundrect(t.x, t.y-t.r/2, tt.x-t.x, t.r, t.r/2, 1, 1)

	if tt.x-t.x<=t.r then
		gfx.set(0.25, 0.25, 0.25, 1)
		gui.roundrect(tt.x, t.y-t.r/2, tt.x-t.x, t.r, t.r/2, 1, 1)  --未完成部分
		gfx.set(1, 1, 1, 1)
		gui.roundrect(t.x, t.y-t.r/2, t.length, t.r, t.r/2, 1, 0)
	end

	--把手
	gfx.set(1, 0.6, 0, 1)
	local handle_w, handle_h=t.r, t.r+6
	--gfx.circle(tt.x, tt.y, t.r, true,true)
	--gfx.rect(tt.x-handle_w/2, tt.y-handle_h/2, handle_w, handle_h%2~=0 and handle_h or handle_h+1, 1)
	gui.roundrect(tt.x-handle_w/2, tt.y-handle_h/2, handle_w, handle_h, t.r/2, 1, 1)

    --标题
    if not t.no_label then gui.text(t.x-20, t.y, t.title, 1, 'R') end

    --数值
    if not t.no_value then gui.text(t.x+t.length+20, t.y, tt.value, 1, 'L') end
end

function gui.slider.new(t)
	--初始化
	local init=t.redraw or false
	if not gui.slider[t.name] then
		init=true
        gui.slider[t.name]={x=gui.value_convert(t.start, t.min, t.max, t.x, t.x+t.length), y=t.y, r=t.r, value=nil, name=t.name, min=t.min, max=t.max}
		gui.slider[t.name].last={x=gui.slider[t.name].x, y=gui.slider[t.name].y}
		gui.slider[t.name].master={max=t.max}
	end
	local tt=gui.slider[t.name]
	gui.drawlist.slider[t.name]=t

	local max=tt.master.max or t.max
	
	if not tt.value then
		tt.value=t.start  --初始化
	else
		tt.value=gui.value_limitation(tt.value, tt.min, max)
	end
	tt.x=gui.value_convert(tt.value, t.min, max, t.x, t.x+t.length)  --初始化图形

	--判断鼠标位置
	local mouse=gui.get_mouse_state(t.name, tt.x, tt.y, tt.r, t.action)
	
	--判断把手位置
	local x_max=t.x+t.length
	if mouse=='LEFTHOLD' then
		tt.x=gui.value_limitation(gfx.mouse_x, t.x, x_max)
		tt.value=gui.value_convert(tt.x, t.x, t.x+t.length, tt.min, max)
		tt.master.value=tt.value
	elseif mouse=='' and tt.master.value then
		if tt.master.value~=tt.value then tt.value=gui.value_limitation(tt.master.value, tt.min, max) end  --以外部数据影响图形
	end
	
	if init or tt.x~=tt.last.x or tt.y~=tt.last.y then  --图形需更新
		tt.last.x=tt.x
		tt.last.y=tt.y
		gui.redraw=true
	end
end

-------------------------------------------------------------------开关-------------------------------------------------------------------
gui.toggle=gui.new()

function gui.draw.toggle(t)
	local tt=gui.toggle[t.name]

	--画出按钮和文字
	gui.draw_btn(t.x, t.y, t.w, t.h, t.r, (tt.value or tt.state) and 0 or 1, (tt.value or tt.state) and 0.6314 or 0.6, tt.state and 0.3608 or 0, (tt.value or tt.state) and true)
	gui.text(t.x+t.w/2, t.y+t.h/2, t.title, 1, 'C')
end

function gui.toggle.new(t)
	--初始化
	local init=t.redraw or false
	if not gui.toggle[t.name] then
		init=true
		gui.toggle[t.name]={state=t.state, last={state=t.state, value=''}, master={}}
	end
	local tt=gui.toggle[t.name]
	gui.drawlist.toggle[t.name]=t

	--判断鼠标位置
	if not t.disable then
		local mouse=gui.get_mouse_state(t.name, t.x, t.y, t.w, t.h, t.action)
		if mouse:match('DOWN') then
			tt.state=not tt.state
		end
	end
	
	if init or tt.state~=tt.last.state or tt.value~=tt.last.value then  --图形需更新
		tt.last.state=tt.state
		tt.last.value=tt.value
		gui.redraw=true
	end
end

-------------------------------------------------------------------下拉列表-------------------------------------------------------------------
gui.drop=gui.new()

function gui.draw.drop(t)
	local tt=gui.drop[t.name]

	--边框
	gfx.set(tt.state and 1 or 0.375, tt.state and 0.6 or 0.375, tt.state and 0 or 0.375)
	gfx.rect(t.x, t.y, t.w, t.h, 1)
	
	--文本框
	gfx.set(0.1875, 0.1875, 0.1875, 1)
	gfx.rect(t.x+1, t.y+1, t.w-t.h, t.h-2, 1)

	--标签
	gui.text(t.x+1+t.w/2-t.h/2, t.y+1+t.h/2-1, t.title_update and tt.value and t.index[tt.value] or t.title, 1, 'C')

	--等腰三角
	local x, y, d=t.x+t.w-t.h/2, t.y+t.h/2, t.h/10
	local len=d*3^0.5
	local x1, y1=x+len, y-d/2
	local x2, y2=x-len, y-d/2
	local x3, y3=x, y+d
	gfx.set(0, 0, 0, 1)
	gfx.triangle(x1, y1, x2, y2, x3, y3)
end

function gui.drop.new(t)
	local init=t.redraw or false
	if not gui.drop[t.name] then
		init=true
		gui.drop[t.name]={state=false, last={state=false}}
	end
	local tt=gui.drop[t.name]
	gui.drawlist.drop[t.name]=t

	--判断鼠标位置
	local mouse=gui.get_mouse_state(t.name, t.x, t.y, t.w, t.h, t.action, t.index)
	if mouse:match('DOWN') then
		tt.state=true
	elseif mouse:match('UP') then
		tt.state=false
		-- gui.action=t.name
	end

	if init or tt.state~=tt.last.state then  --图形需更新
		tt.last.state=tt.state
		gui.redraw=true
	end
end

-------------------------------------------------------------------按钮-------------------------------------------------------------------
gui.button=gui.new()

function gui.draw.button(t)
	local tt=gui.button[t.name]

	--阴影
	if not tt.state then
		gfx.set(0.2, 0.2, 0.2, 1)
		gui.roundrect(t.x+3, t.y+3, t.w, t.h, t.r, 1, 1)  --外层
		gfx.set(0.16, 0.16, 0.16, 1)
		gui.roundrect(t.x+2, t.y+2, t.w, t.h, t.r, 1, 1)  --中层
	end
	-- gfx.set(0.11, 0.11, 0.11, 1)
	-- gui.roundrect(tt.state and t.x+1 or t.x-1, tt.state and t.y+1 or t.y-1, t.w+2, t.h+2, t.r, 1, 1)  --外层

	--按钮本体和文字
	gfx.set(tt.colr or 0.375, tt.colg or 0.375, tt.colb or 0.375, 1)
	gui.roundrect(tt.state and t.x+2 or t.x, tt.state and t.y+2 or t.y, t.w, t.h, t.r, 1, 1)
	gui.text(tt.state and t.x+2+t.w/2 or t.x+t.w/2, tt.state and t.y+2+t.h/2 or t.y+t.h/2, t.title, t.size or 1, 'C', t.text_colr, t.text_colg, t.text_colb)
	--边框
	if t.frame and tt.frame then gui.frame(t.x+t.w/2, t.y+t.h/2, t.w, t.h, 10, 1, 0, 1, 0) end
end

function gui.button.new (t)
	local init=t.redraw or false
	if not gui.button[t.name] then
		init=true
		gui.button[t.name]={state=false, frame=false, last={state=false, colr=-1, colg=-1, colb=-1, title=t.title}, master={}}
	end
	local tt=gui.button[t.name]
	gui.drawlist.button[t.name]=t
	tt.colr, tt.colg, tt.colb=tt.master.r or t.colr, tt.master.g or t.colg, tt.master.b or t.colb

	--判断鼠标位置
	local mouse=gui.get_mouse_state(t.name, t.x, t.y, t.w, t.h, t.action)
	if mouse:match('DOWN') then
		tt.state=true
	elseif mouse:match('UP') then
		tt.state=false
		tt.frame=not tt.frame
		-- gui.action=t.name
	end

	if init or tt.state~=tt.last.state or tt.colr~=tt.last.colr or tt.colg~=tt.last.colg or tt.colb~=tt.last.colb or t.title~=tt.last.title then
		tt.last.state=tt.state
		tt.last.colr=t.colr
		tt.last.colg=t.colg
		tt.last.colb=t.colb
		tt.last.title=t.title
		gui.redraw=true
	end
end

-------------------------------------------------------------------信息板-------------------------------------------------------------------
gui.board=gui.new()

function gui.draw.board(t)
	local tt=gui.board[t.name]

	--边框
	gfx.set(0.375, 0.375, 0.375, 1)
	-- gfx.rect(t.x-1, t.y-1, t.w+2, t.h+2, false)
	gui.roundrect(t.x-1, t.y-1, t.w+2, t.h+2, 8, 0, 1)

	--本体
	gfx.set(tt.colr or 0.1875, tt.colg or 0.1875, tt.colb or 0.1875, 1)
	gui.roundrect(t.x, t.y, t.w, t.h, 8, 1, 1)
	-- gfx.rect(t.x, t.y, t.w, t.h, true)

	--内容
	local x, y=not t.align and t.x+5 or t.align=='C' and t.x/2+t.w/2 or t.align=='R' and t.x+t.w-5, t.y+t.h/2
	gui.text(x, y, tt.value or '', 3, t.align or 'L')

	--标题
	if not t.no_label then
		local x, y=t.x-5, t.y+t.h/2
		gui.text(x, y, t.title, 3, 'R')
	end
end

function gui.board.new (t)
	local init=t.redraw or false
	if not gui.board[t.name] then
		init=true
		gui.board[t.name]={state=false, last={value='', colr=-1, colg=-1, colb=-1}, master={}}
	end
	local tt=gui.board[t.name]
	gui.drawlist.board[t.name]=t

	--判断鼠标位置
	local mouse=gui.get_mouse_state(t.name, t.x, t.y, t.w, t.h, t.action)
	if mouse:match('UP') then
		-- gui.action=t.name
	end

	--本体
	tt.colr, tt.colg, tt.colb=tt.master.r or t.colr, tt.master.g or t.colg, tt.master.b or t.colb
	
	--内容
	if t.note then
		tt.value=t.note
	end

	if init or tt.last.value~=tt.value or tt.last.colr~=tt.colr or tt.last.colg~=tt.colg or tt.last.colb~=tt.colb then  --需要重新绘制图形
		tt.last.value=tt.value
		tt.last.colr, tt.last.colg, tt.last.colb=t.colr, t.colg, t.colb
		gui.redraw=true
	end
end

-------------------------------------------------------------------标签-------------------------------------------------------------------
gui.label=gui.new()

function gui.draw.label(t)
	local tt=gui.label[t.name]
	
	--内容
	local size=gui.text(t.center and t.x+t.w/2 or t.x, t.y, tt.value or '', tt.font_size or t.font, t.center and 'C' or 'L', nil, nil, nil, nil, 'Calibri', font_size_label, t.w, t.h)
	if size then tt.font_size=size end
end

function gui.label.new (t)
	local init=t.redraw or false
	if not gui.label[t.name] then
		init=true
		gui.label[t.name]={state=false, last={value=''}, master={}}
	end
	local tt=gui.label[t.name]
	gui.drawlist.label[t.name]=t

	--内容
	tt.value=tt.value or t.note or ''

	if init or tt.last.value~=tt.value then  --图形需要更新
		tt.last.value=tt.value
		-- table.remove(gui.font_idx, tt.font_size)
		tt.font_size=nil
		gui.redraw=true
	end
end

-------------------------------------------------------------------主体-------------------------------------------------------------------
function main()
	gui.key=gfx.getchar()

	if gui.focus.auto then
		local check_dock, x, y, w=gfx.dock(-1, 1, 1, 1)
		if gui.is_in_area(x, y, w, 45) then
			reaper.JS_Window_SetFocus(gui.focus.hwnd)
			gui.focus.lost=true
		else
			if gui.focus.lost then focus() gui.focus.lost=false end
		end
	end

	if gui.running and not gui.sub then
		for k, v in pairs(gui.main) do
			if type(v)=='function' then v() end
		end
		for k, v in pairs(gui.loop) do
			if type(v)=='function' then v() end
		end
	end

	if gui.sub and not gui.running then  --子窗口启动后的子进程
		for k, v in pairs(gui.subloop) do
			if type(v)=='function' then v() end
		end
	end

	local late=false  --检测是否有运行过延迟函数
	if gui.late then  --延迟运行
		for k, v in pairs(gui.late) do  
			if type(v)=='function' then v() late=true end
		end
	end
	if late then gui.late=nil end  --延迟函数执行完毕后清空

	if gui.redraw then  --检测到需要刷新画面的信号
		gui.redraw=false
		gui.clear(0, 0)  --重置画面
		gui.redrawAll()  --绘制所有元素
	end

	-- local hotkey=gui.key>0 and (gui.hotkey[string.char(gui.key)] or gui.hotkey[gui.key]) or nil
	local hotkey=gui.key>0 and (gui.hotkey[gui.key] or gui.hotkey[gui.key>127 and gui.key or string.char(gui.key)]) or nil
	if hotkey then hotkey() end

	if gui.showkey and gui.key>0 then msg('You are pressing '..gui.key) end

	gui.blit(0)

	if gui.clean_all then
		gui.clean_all=false
		init_drawlist()
	end

	if gui.key>=0 then reaper.defer(main) end
end
-------------------------------------------------------------------焦点-------------------------------------------------------------------
function gui.focus.set_focus()  --获得焦点
	reaper.JS_Window_SetFocus(gui.focus.hwnd)
end
-------------------------------------------------------------------窗口初始化-------------------------------------------------------------------
function get_longest(t)
    if #t==0 then return end
	local name_len, name_longest=0, ''  --记录最长的长度
    for k, v in ipairs(t) do
        if v:len()>name_len then
			name_longest=v
			name_len=v:len()
		end
    end
	return name_longest
end

function gui.win.init(win_title, t, line_max, row_max, pad_btn_x, pad_btn_y, gap_btn_btn, gap_btn_win_x, gap_btn_win_y, gap_btn_win_btm_y, w_force, h_force)
	local btns={}
    gfx.setfont(1)
	local name_longest=get_longest(t) or '空白'
	local w_est, h_est=gfx.measurestr(name_longest)  --获取名字的宽和高
	local w_btn, h_btn, r_btn=w_est+2*pad_btn_x, h_est+2*pad_btn_y, 10  --计算按钮的宽、高和半径
	local w_auto, h_auto=w_btn*row_max+gap_btn_btn*(row_max-1)+2*(gap_btn_win_x), h_btn*(line_max)+gap_btn_btn*(line_max-1)+gap_btn_win_y+(gap_btn_win_btm_y or gap_btn_win_y)  --计算窗口的宽和高  宽=一行5个按钮+4个按钮间间距+2个按钮和窗口间距 高=总数/5行按钮+总数/5-1个按钮间间距+2个按钮和窗口间距
	local w_win, h_win=w_force and math.max(w_force, w_auto) or w_auto , h_force and math.max(h_force, h_auto) or h_auto
	local check_dock, check_x, check_y=gfx.dock(-1, 1, 1)
	local x_win, y_win=gui.running and check_x or (1920-w_win)/2, gui.running and check_y or (1080-h_win)/2  --窗口左上角坐标，让窗口出现在屏幕中间(仅限屏幕分辨率为1920*1080)
    for i=1, line_max do
		for j=1, row_max do
			local x, y=gap_btn_win_x+(j-1)*(w_btn+gap_btn_btn), gap_btn_win_y+(y_start or 0)+(h_btn+gap_btn_btn)*(i-1)  --计算每个按钮的坐标
            local tag_name=t[i..j] or '空白'
			btns[i..j]={x=x, y=y, w=w_btn, h=h_btn, r=r_btn, name=tag_name}  --储存每个按钮的坐标 文字和边界
        end
    end
	-------------------------------------------------------------- 窗口初始化 -----------------------------------------
	gfx.clear=4210752  --背景颜色
	x_win=reaper.HasExtState(gui.proj_ext, 'Last_X') and tonumber(reaper.GetExtState(gui.proj_ext, 'Last_X')) or x_win
	y_win=reaper.HasExtState(gui.proj_ext, 'Last_Y') and tonumber(reaper.GetExtState(gui.proj_ext, 'Last_Y')) or y_win
	gfx.init(win_title, w_win, h_win, 0, x_win, y_win)  --窗口初始化 
	gui.focus.title=win_title
	gui.focus.hwnd=reaper.JS_Window_Find(win_title, true)
	if gui.running then
		reaper.JS_Window_Resize(reaper.JS_Window_Find(win_title, false), w_win+16, h_win+39)
	else
		gui.running=true
		main()
	end
	gui.win.x, gui.win.y, gui.win.w, gui.win.h, gui.win.title=x_win, y_win, w_win, h_win, win_title
	return btns
end

function gui.win.init_custom(win_title, t, line_max, row_max, pad_btn_x, pad_btn_y, gap_btn_btn, gap_btn_win_x, gap_btn_win_y, w_force, h_force)
	local btns={}
    gfx.setfont(1)
	local name_longest=get_longest(t) or '空白'
	local w_est, h_est=gfx.measurestr(name_longest)  --获取名字的宽和高
	local w_btn, h_btn, r_btn=w_est+2*pad_btn_x, h_est+2*pad_btn_y, 10  --计算按钮的宽、高和半径
	local w_auto, h_auto=w_btn*row_max+gap_btn_btn*(row_max-1)+2*gap_btn_win_x, h_btn*(line_max)+gap_btn_btn*(line_max-1)+gap_btn_win_y*2  --计算窗口的宽和高  宽=一行5个按钮+4个按钮间间距+2个按钮和窗口间距 高=总数/5行按钮+总数/5-1个按钮间间距+2个按钮和窗口间距
	local w_win, h_win=w_force and math.max(w_force, w_auto) or w_auto , h_force and math.max(h_force, h_auto) or h_auto
	local check_dock, check_x, check_y=gfx.dock(-1, 1, 1)
	local x_win, y_win=gui.running and check_x or (1920-w_win)/2, gui.running and check_y or (1080-h_win)/2  --窗口左上角坐标，让窗口出现在屏幕中间(仅限屏幕分辨率为1920*1080)
	local count=1
    for i=1, line_max do
		for j=1, row_max do
			local x, y=gap_btn_win_x+(j-1)*(w_btn+gap_btn_btn), gap_btn_win_y+(h_btn+gap_btn_btn)*(i-1)  --计算每个按钮的坐标
            local tag_name=t[count] or '空白'
			btns[tag_name]={x=x, y=y, w=w_btn, h=h_btn, r=r_btn, name=tag_name}  --储存每个按钮的坐标 文字和边界
			count=count+1
        end
    end
	-------------------------------------------------------------- 窗口初始化 -----------------------------------------
	gfx.clear=4210752  --背景颜色
	x_win=reaper.HasExtState(gui.proj_ext, 'Last_X') and tonumber(reaper.GetExtState(gui.proj_ext, 'Last_X')) or x_win
	y_win=reaper.HasExtState(gui.proj_ext, 'Last_Y') and tonumber(reaper.GetExtState(gui.proj_ext, 'Last_Y')) or y_win
	gfx.init(win_title, w_win, h_win, 0, x_win, y_win)  --窗口初始化 
	gui.focus.title=win_title
	gui.focus.hwnd=reaper.JS_Window_Find(win_title, true)
	if gui.running then
		reaper.JS_Window_Resize(reaper.JS_Window_Find(win_title, false), w_win+16, h_win+39)
	else
		gui.running=true
		main()
	end
	gui.win.x, gui.win.y, gui.win.w, gui.win.h, gui.win.title=x_win, y_win, w_win, h_win, win_title
	return btns
end

function gui.win.normal(win_title, w_win, h_win, x_win, y_win, dock)
	gfx.clear=4210752  --背景颜色
	x_win=reaper.HasExtState(gui.proj_ext, 'Last_X') and tonumber(reaper.GetExtState(gui.proj_ext, 'Last_X')) or x_win
	y_win=reaper.HasExtState(gui.proj_ext, 'Last_Y') and tonumber(reaper.GetExtState(gui.proj_ext, 'Last_Y')) or y_win
	gfx.init(win_title, w_win, h_win, dock and 1 or 0, x_win, y_win)  --窗口初始化 
	gui.focus.title=win_title
	gui.focus.hwnd=reaper.JS_Window_Find(win_title, true)
	if gui.running then
		-- reaper.JS_Window_Resize(reaper.JS_Window_Find(win_title, false), w_win+16, h_win+39)
	else
		gui.running=true
		main()
	end
	gui.win.x, gui.win.y, gui.win.w, gui.win.h, gui.win.title=x_win, y_win, w_win, h_win, win_title
end

function gui.win.sub(x, y, w, h)  --子窗口
	gui.running=false
	gui.sub=true
	gui.clean_all=true
	if w>gfx.w or h>gfx.h then
		reaper.JS_Window_Resize(gui.focus.hwnd, w+16, h+39)
	end
	-- gfx.set(0.25, 0.25, 0.25, 1)
	-- gui.roundrect(x, y, w, h, 10, true, true)
end

function gui.win.resume()  --恢复主窗口
	gui.sub=false
	gui.running=true
	gui.clean_all=true
	reaper.JS_Window_Resize(gui.focus.hwnd, gui.win.w+16, gui.win.h+39)
	-- gfx.set(0.25, 0.25, 0.25, 1)
end

-------------------------------------------------------------------退出程序-------------------------------------------------------------------
function gui.before_exit()
	local dock, x, y=gfx.dock(-1, 0, 0)
	reaper.SetExtState(gui.proj_ext, 'Last_X', x, true)  --保存位置
	reaper.SetExtState(gui.proj_ext, 'Last_Y', y, true)  --保存位置
	for k, v in pairs(gui.exit) do
		if type(v)=='function' then v() end
	end
end
reaper.atexit(gui.before_exit)

function gui.quit()
	gfx.quit()
end