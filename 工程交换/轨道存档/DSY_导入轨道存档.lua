function msg(value)

  reaper.ShowConsoleMsg(tostring(value) .. "\n")

end

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)

local files={}

local check,  names = reaper.JS_Dialog_BrowseForOpenFiles("请选择轨道存档文件", "E:/aes/", "*.xml", "*.xml", true)

if check==0 then return end

local head

for v in names:gmatch("[^\0]*") do

	if v:find("\\") then

		head=v

	else

		if head:sub(-1)~="\\" then head=head.."\\" end

		files[#files+1]=head..v

	end

end

if #files==0 then files[1]=head end

local portable

if #files==1 then
    portable=head:match("(.+[/\\])[^/\\]+")..'Media\\'
else
    portable=head..'Media\\'
end

-------------------------------------------------------------------路径部分-------------------------------------------------------------------
local info = debug.getinfo(1,'S')
local main = info.source:match[[^@?(.*[\/])[^\/]-$]]
local import=main.."\\DSY_导入轨道存档 主体.lua"
local check=reaper.file_exists(import)
if not check then reaper.MB("请先把DSY_导入轨道存档 主体.lua文件与此文件放在一起", "文件缺失", 0) return end
dofile(import)

-------------------------------------------------------------------begin-------------------------------------------------------------------
local cursor=reaper.GetCursorPosition()

for i, value in pairs(files) do

	if import_track_archieve(value, portable) then

        if reaper.CountSelectedMediaItems(0)>0 and #files>1 then  --如果超过一个文件 自动建region
            reaper.Main_OnCommand(40290, 0)  --set ts
            local tsl, tsr=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
            reaper.Main_OnCommand(40020, 0)  --remove ts
            local name=value:match(".+[/\\](.+)%.%w+$")
            reaper.AddProjectMarker(0, 1, cursor, tsr, name, reaper.CountProjectMarkers(0))
            reaper.SetEditCurPos(tsr+1200, 0, 0)
            cursor=reaper.GetCursorPosition()
        else
            reaper.SetEditCurPos(cursor, 0, 0)  --光标回到起点
        end

    end

end

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("导入轨道存档", -1)