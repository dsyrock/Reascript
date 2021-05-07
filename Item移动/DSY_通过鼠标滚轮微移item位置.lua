--[[
ReaScript Name: 通过鼠标滚轮微移item位置
Version: 1.0
Author: noiZ
]]

function main()

reaper.PreventUIRefresh(1)

num=reaper.CountSelectedMediaItems(0)

is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()

local fr = reaper.TimeMap_curFrameRate(0)

local d=1/fr*0.4

if val>0 and num==0 then 

  item= reaper.BR_ItemAtMouseCursor()
  
  if item~=nil then

    local pos=reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  
    reaper.SetMediaItemPosition(item, pos+d, 1)
  
  end
      
end

if val>0 and num>0 then
  
    for i=0, num-1 do

      local item=reaper.GetSelectedMediaItem(0, i)

      local pos=reaper.GetMediaItemInfo_Value(item, "D_POSITION")

      reaper.SetMediaItemPosition(item, pos+d, 1)

    end
    
end
  
if val<0 and num==0 then 

  item= reaper.BR_ItemAtMouseCursor()
  
  if item~= nil then
    
    local pos=reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  
    reaper.SetMediaItemPosition(item, pos-d, 1)
  
  end
      
end
  
if val<0 and num>0 then
    
  for i=0, num-1 do

    local item=reaper.GetSelectedMediaItem(0, i)

    local pos=reaper.GetMediaItemInfo_Value(item, "D_POSITION")

    reaper.SetMediaItemPosition(item, pos-d, 1)

  end

end  

  reaper.UpdateArrange()
  
reaper.PreventUIRefresh(-1)

end

reaper.defer(main)
