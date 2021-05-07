--[[
ReaScript Name: 剪掉鼠标右侧部分
Version: 1.0
Author: noiZ
]]

local junyuan='on'

function right(it)

	local pos=reaper.GetMediaItemInfo_Value(it, 'D_POSITION')

	local edge=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')+pos

	local tr=reaper.GetMediaItemTrack(it)

	reaper.SelectAllMediaItems(0, 0)

	reaper.SetMediaItemSelected(it, true)

	reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_SELNEXTITEM'), 0)  --select next item

	local it_n=reaper.GetSelectedMediaItem(0, 0)

	local tr_n=reaper.GetMediaItemTrack(it_n)

	if tr_n~=tr then
		
		reaper.SetMediaItemSelected(it_n, 0)
		
		reaper.SetMediaItemSelected(it, 1) 
		
		return 
	
	end

	local pos_n=reaper.GetMediaItemInfo_Value(it_n, 'D_POSITION')

	if edge-pos_n>0.0001 then

		local shape=reaper.GetMediaItemInfo_Value(it_n, "C_FADEINSHAPE")
		if shape==7 then
			reaper.SetMediaItemInfo_Value(it_n, "D_FADEINLEN_AUTO", 0)
			reaper.SetMediaItemInfo_Value(it_n, "D_FADEINLEN", 0)
			reaper.SetMediaItemInfo_Value(it_n, "C_FADEINSHAPE", 0)
		end

	end

	reaper.SelectAllMediaItems(0, 0)

	reaper.SetMediaItemSelected(it, 1)

end

function main()

	reaper.PreventUIRefresh(1)

	local it=reaper.BR_ItemAtMouseCursor()

	local its={}

	local num=reaper.CountSelectedMediaItems(0)

	local cur=reaper.GetCursorPosition()

	if it then 

		if num>0 then

			for i=1, num do

				its[i]=reaper.GetSelectedMediaItem(0, i-1)

			end

			reaper.SelectAllMediaItems(0, 0)

		end

		reaper.SetMediaItemSelected(it, 1)

		if junyuan=='on' then right(it) end

		reaper.Main_OnCommand(40513, 0)  -- move edit cursor to mouse

		reaper.Main_OnCommand(40611, 0)  -- trim right edge

		local shape=reaper.GetMediaItemInfo_Value(it, "C_FADEOUTSHAPE")
		if shape==7 then
			reaper.SetMediaItemInfo_Value(it, "D_FADEOUTLEN_AUTO", 0)
			reaper.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", 0)
			reaper.SetMediaItemInfo_Value(it, "C_FADEOUTSHAPE", 0)
		end

		reaper.SetMediaItemSelected(it, 0)

		for i=1, num do

			reaper.SetMediaItemSelected(its[i], 1)

		end

	else 

		if num>0 then

			for i=1, num do
				its[i]=reaper.GetSelectedMediaItem(0, i-1)
			end

			reaper.SelectAllMediaItems(0, 0)

			for k, v in pairs(its) do
				if junyuan=='on' then right(v) end
				local shape=reaper.GetMediaItemInfo_Value(v, "C_FADEOUTSHAPE")
				if shape==7 then
					reaper.SetMediaItemInfo_Value(v, "D_FADEOUTLEN_AUTO", 0)
					reaper.SetMediaItemInfo_Value(v, "D_FADEOUTLEN", 0)
					reaper.SetMediaItemInfo_Value(v, "C_FADEOUTSHAPE", 0)
				end
			end

			for k, v in pairs(its) do
				reaper.SetMediaItemSelected(v, true)
			end

			reaper.Main_OnCommand(40513, 0)  -- move edit cursor to mouse

			reaper.Main_OnCommand(40611, 0)  -- trim right edge

		end

	end

	reaper.SetEditCurPos(cur, 0, 0)

	reaper.PreventUIRefresh(-1)

	reaper.UpdateArrange()

end

reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("剪掉鼠标右侧部分", -1)