reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
num=reaper.CountSelectedMediaItems(0)

if num==0 then

  return  

end

item,track={},{}

tracknum=1

--get tracks
for i=0,num-1 do

  item[i]=reaper.GetSelectedMediaItem(0,i) -- get all the selected items
  
  if i>0 then  --compare difference between two item's track to find the edge of items
  
      track1=reaper.GetMediaItemTrack(item[i-1])
  
      track2=reaper.GetMediaItemTrack(item[i])
      
      if track1~=track2 then
      
        track[tracknum-1]=track1  
        
        tracknum=tracknum+1
        
      end
      
    end
      
end
--get tracks

reaper.Main_OnCommand(40289,0)  -- unselect all items

track[tracknum-1]=reaper.GetMediaItemTrack(item[num-1]) --define the last track via the last item

itemnew={}  --to store the duplicated items

numnew=0   --the number of the duplicated items

--duplicate items
for i=0,tracknum-1 do  --loop the media iitem tracks

  for j=0,num-1 do  --find all the items in track[i] then select and duplicate them
  
    tracktemp=reaper.GetMediaItemTrack(item[j])
    
    if tracktemp==track[i] then
    
       reaper.SetMediaItemSelected(item[j],true)
      
    end

  end
  
  reaper.Main_OnCommand(41295,0)  -- duplicate items
  
  numtemp=reaper.CountSelectedMediaItems(0)
  
  for k=0,numtemp-1 do
       
    itemnew[numnew]=reaper.GetSelectedMediaItem(0,k)
      
    numnew=numnew+1

  end
    
  reaper.Main_OnCommand(40289,0)  -- unselect all items
  
end

for i=0,numnew-1 do

  reaper.SetMediaItemSelected(itemnew[i],true)

end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("",-1)
