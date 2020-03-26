function msg(value)

  reaper.ShowConsoleMsg(tostring(value) .. "\n")

end

reaper.Undo_BeginBlock()

local files={}

local sr, fr

local check,  names = reaper.JS_Dialog_BrowseForOpenFiles("Please select the AES31 files", "E:/aes/", "*.adl", "*.adl", true)

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

------------------------------------begin------------------------------------------

--------------------------------时间格式转化函数------------------------------------
function get_time(text)  

	local h, m, s, f, r=text:match("(%d+)%D(%d+)%D(%d+)%D(%d+)/(%d+)")

	local time

	if h=='23' and m=='59' then

		time=(60-s-f/fr-r/sr)*(-1)

	else

		time=h*3600+m*60+s+f/fr+r/sr

	end

	return time

end

-----------------------------------------------------------------------------------------

local cursor=reaper.GetCursorPosition()	--获取光标位置，在光标后开始建立item

for i, value in pairs(files) do

	local path=value

	local command=[[powershell -c "dir ']]..path..[[' |%{[IO.File]::ReadAllText($_,[Text.Encoding]::Default)|Out-File ']]..path..[[' -Encoding UTF8}"]]

	reaper.ExecProcess(command, 10000)

	reaper.SelectAllMediaItems(0, 0)

	local num=reaper.CountTracks(0)

	if num>0 then

		local tr=reaper.GetTrack(0, num-1)

		reaper.SetOnlyTrackSelected(tr)

	end

	local file=io.open(path)

	local tr, it, it_idx, source, source_idx={}, {}, 0, {}, 1

	for line in io.lines(path) do

		local record=file:read("*l")

		if record:find("SEQ_SAMPLE_RATE)") then 

			sr=record:match('%d+')

		elseif record:find("SEQ_FRAME_RATE)") then

			fr=record:match('%d+')

	-----------------------------------------------------------记录轨道信息--------------------------------------------------------------
		
		elseif record:find("%(Entry%)") then

			local track_num=line:match('Cut%)%s%S%s%d+%s%S+%s(%S+)%s')

			if track_num:find("-") then

				local track_num1, track_num2=track_num:match('(%d+)%-(%d+)')

				track_num1=tonumber(track_num1)

				track_num2=tonumber(track_num2)

				tr[track_num1], tr[track_num2]={}, {}

				tr[track_num1].num=track_num

				tr[track_num1].check="keep"

				tr[track_num2].check="pass"

			else

				tr[tonumber(track_num)]={}

				tr[tonumber(track_num)].num=track_num

				tr[tonumber(track_num)].check="keep"			

			end

		end

	end

	local file=io.open(path)

	for line in io.lines(path) do

		local record=file:read("*l")

	------------------------------------------------建立轨道---------------------------------------------

		if record:find("Track)") then

			local tr_num=record:match("%s(%d+)%s")

			tr_num=tonumber(tr_num)

			if tr[tr_num] and tr[tr_num].check=="keep" then

				reaper.Main_OnCommand(40001, 0)  --                   新增轨道

				tr[tr_num].tr=reaper.GetSelectedTrack(0, 0)

				local name=''

				if not record:find('\"\"') then

					name=record:match("\"%[?([^%[%]\"]+)")

					name=name:gsub("%-L", "")

				end

				reaper.GetSetMediaTrackInfo_String(tr[tr_num].tr, "P_NAME", name, 1)

			end

		elseif record:find("Index)") then  --                                      文件源头记录

			local part1, part2, part3=record:match('localhost/([^\"]+)\"%s%S+%s(%d+%D%d+%D%d+%D%d+/%d+)%s(%S+)%s')

			source[#source+1]={}

			source[#source].sr=part1
			
			source[#source].start=get_time(part2)

			if source[#source].sr:find("/Consolidated/") then

				source[#source].length=get_time(part3)

			end

		elseif record:find("Entry)") then  --                                           音频建立

			it[#it+1]={}

			local fileidx, tr_num, part3, part4, part5=record:match('Cut%)%s%S%s(%d+)%s%S+%s(%S+)%s(%S+)%s(%S+)%s(%S+)%s')

			fileidx=tonumber(fileidx)

			local source_path=source[fileidx].sr

			local source_check=reaper.PCM_Source_CreateFromFile(source_path)

			it[#it].start=get_time(part3)

			local pos=get_time(part4)

			it[#it].length=get_time(part5)-pos

			local t

			for k, v in pairs(tr) do  --                                                   建立item

				if tr_num==tr[k].num then t=tr[k].tr break end

			end

			it[#it].it=reaper.AddMediaItemToTrack(t)

			reaper.SetMediaItemPosition(it[#it].it, pos+cursor, 0)

			reaper.SetMediaItemLength(it[#it].it, it[#it].length, 0)
			
			local tk=reaper.AddTakeToMediaItem(it[#it].it)

			reaper.SetMediaItemTake_Source(tk, source_check)					--		    片段和源文件连接

			if source[fileidx].sr:find("/Consolidated/") then	--		consolidate路径下的文件不添加偏移量
			
				reaper.SetMediaItemLength(it[#it].it, source[fileidx].length, 1)

			elseif it[#it].start<source[fileidx].start then

				reaper.SetMediaItemTakeInfo_Value(tk, "D_STARTOFFS", it[#it].start)

			else

				reaper.SetMediaItemTakeInfo_Value(tk, "D_STARTOFFS", it[#it].start-source[fileidx].start)

			end

		elseif record:find("Infade.+%d+") then  --                                           淡入

			local time=record:match("%d+%D%d+%D%d+%D%d+/%d+")

			local fadein=get_time(time)

			reaper.SetMediaItemInfo_Value(it[#it].it, "D_FADEINLEN", fadein)

		elseif record:find("Outfade.+%d+") then  --                                           淡出

			local time=record:match("%d+%D%d+%D%d+%D%d+/%d+")

			local fadeout=get_time(time)

			reaper.SetMediaItemInfo_Value(it[#it].it, "D_FADEOUTLEN", fadeout)

		elseif record:find("Gain)") and (not record:find("SYS")) then  --                                           音量

			local db=record:match('Gain%)%s%S+%s(%S+)')

			local db=tonumber(db)

			reaper.SetMediaItemInfo_Value(it[#it].it, "D_VOL", 10^((db)/20))

		elseif record:find("NAME\t\"") then  --                                           片段名称

			reaper.SetMediaItemSelected(it[#it].it, 1)

		end

	end

	reaper.Main_OnCommand(41858, 0)  -- rename with source file name

	if #files>1 then 
			
		reaper.Main_OnCommand(41039, 0)  -- set loop point

		local edgel, edger=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)

		reaper.SetEditCurPos(edger+600, 0, 0) 

		reaper.Main_OnCommand(40020, 0)  -- remove loop point and time selection

	end

end

reaper.UpdateArrange()

reaper.Undo_EndBlock("", -1)