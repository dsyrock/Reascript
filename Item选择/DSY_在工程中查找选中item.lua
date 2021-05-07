--[[
ReaScript Name: 在工程中查找选中item
Version: 1.0
Author: noiZ
]]

function search_in_project()
	reaper.PreventUIRefresh(1)
	local num=reaper.CountSelectedMediaItems(0)
	if num==0 then return end
	local name, count=save_names(num)
	if count>0 then
		local num=reaper.CountMediaItems(0)
		for i=0,num-1 do
			local item=reaper.GetMediaItem(0, i)
			local take=reaper.GetActiveTake(item)
			if take then
				local tk_name=reaper.GetTakeName(take)
				if name[tk_name] then reaper.SetMediaItemSelected(item, 1) end
			end
		end
	end
	reaper.UpdateArrange()
	reaper.PreventUIRefresh(-1)
end
search_in_project()