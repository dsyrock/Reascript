--@version 1.0
--@author noiZ
--@description DSY_GUI

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
