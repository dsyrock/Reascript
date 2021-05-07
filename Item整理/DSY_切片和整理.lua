function msg(value)
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end

local its={}
for i=0, num-1 do
    table.insert(its, reaper.GetSelectedMediaItem(0, i))
end
reaper.SelectAllMediaItems(0, 0)

for k, v in pairs(its) do
    reaper.SetMediaItemSelected(v, 1)
    reaper.Main_OnCommand(41513, 0)  --slice
    reaper.Main_OnCommand(40033, 0)  --remove group
    local numCheck=reaper.CountSelectedMediaItems(0)
    if numCheck>1 then
        local it1=reaper.GetSelectedMediaItem(0, 0)
        local start=reaper.GetMediaItemInfo_Value(it1, 'D_POSITION')+reaper.GetMediaItemInfo_Value(it1, 'D_LENGTH')
        local order={}
        for i=1, numCheck-1 do
            table.insert(order, reaper.GetSelectedMediaItem(0, i))
        end
        for k1, v1 in pairs(order) do
            reaper.SetMediaItemPosition(v1, start, 0)
            start=start+reaper.GetMediaItemInfo_Value(v1, 'D_LENGTH')
        end
    end
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)