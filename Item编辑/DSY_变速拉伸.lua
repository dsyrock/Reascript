reaper.Undo_BeginBlock()

local cur=reaper.GetCursorPosition()

local num=reaper.CountSelectedMediaItems(0)

if num==0 then return end

for i=0, num-1 do

	local it=reaper.GetSelectedMediaItem(0, i)

	local tk=reaper.GetActiveTake(it)

	if tk then

		local pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")

		local length=reaper.GetMediaItemInfo_Value(it, "D_LENGTH")

		local edge=pos+length

		if cur>edge then

			local rate=(cur-pos)/length

			local rate_ori=reaper.GetMediaItemTakeInfo_Value(tk, "D_PLAYRATE")

			reaper.SetMediaItemTakeInfo_Value(tk, "D_PLAYRATE", rate_ori/rate)

		end

	end

end

reaper.Main_OnCommand(40611, 0)  -- set item end to cursor

reaper.UpdateArrange()

reaper.Undo_EndBlock("变速拉伸", -1)