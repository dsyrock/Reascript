reaper.Undo_BeginBlock()

num=reaper.CountSelectedMediaItems(0)

if num==0 then return end

-- get region

pos=reaper.GetCursorPosition()

markerid,regionid=reaper.GetLastMarkerAndCurRegion(0, pos)

markerindex,morr,regionl,regionr,name,regionindex= reaper.EnumProjectMarkers(regionid)


if num==1 then
  -- get selected item's informations

  item=reaper.GetSelectedMediaItem(0,0)

  left=reaper.GetMediaItemInfo_Value(item,"D_POSITION")

  right=reaper.GetMediaItemInfo_Value(item,"D_LENGTH")+left

  -- reset region

  reaper.SetProjectMarker(regionindex,1,left,right,name)

end

if num>1 then

  for i=0,num-1 do
  
    item=reaper.GetSelectedMediaItem(0,i)
  
    left=reaper.GetMediaItemInfo_Value(item,"D_POSITION")

    right=reaper.GetMediaItemInfo_Value(item,"D_LENGTH")+left
    
    if i==0 then
    
      min=left
      
      max=right
    
    end
    
    if i>0 then
    
      if left<min then min=left end
      
      if right>max then max=right end
      
    end
    
  end

  reaper.SetProjectMarker(regionindex,1,min,max,name)
  
end


reaper.UpdateArrange()

reaper.Undo_EndBlock("",-1)

