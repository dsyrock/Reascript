--[[
ReaScript Name: 整理选中item
Version: 1.0
Author: noiZ
]]

function organize()

    reaper.PreventUIRefresh(1)
    
    local num=reaper.CountSelectedMediaItems(0)

    if num==0 then return end

    local first_it=reaper.GetSelectedMediaItem(0, 0)

    local first_track=reaper.GetMediaItem_Track(first_it)
    
    local items={}

    for i=1,num do
    
        items[i]={}

        items[i].item=reaper.GetSelectedMediaItem(0, i-1)

        items[i].pos=reaper.GetMediaItemInfo_Value(items[i].item, "D_POSITION")

        local length=reaper.GetMediaItemInfo_Value(items[i].item, "D_LENGTH")

        items[i].edge=items[i].pos+length

        reaper.MoveMediaItemToTrack(items[i].item,first_track)

    end

    function by_pos(t1,t2)

      return t1.pos<t2.pos

    end

    table.sort(items,by_pos)
 
    reaper.Main_OnCommand(40289, 0)  -- unselect all items
   
    function check_overlap(value)
 
        for i=1,value-1 do
      
            if items[i].edge>items[value].pos then
        
                local track=reaper.GetMediaItem_Track(items[value].item)

                local track_check=reaper.GetMediaItem_Track(items[i].item)
         
                if track==track_check then 
         
                    return true
         
                end
        
            end
      
        end
    
    end

    for i=2,#items do

        while check_overlap(i)==true do
         
            reaper.SetMediaItemSelected(items[i].item, 1)

            reaper.Main_OnCommand(40118, 0) 
            
            reaper.SetMediaItemSelected(items[i].item, 0)

        end

    end
   
    reaper.PreventUIRefresh(-1)

end


reaper.Undo_BeginBlock()

organize()

reaper.Undo_EndBlock("",-1)
