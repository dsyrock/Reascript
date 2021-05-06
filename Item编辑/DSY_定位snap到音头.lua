reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end

local its={}
for i=0, num-1 do
    its[i+1]=reaper.GetSelectedMediaItem(0, i)
end
reaper.SelectAllMediaItems(0, 0)

local cur=reaper.GetCursorPosition()
for k, v in pairs(its) do
    reaper.SetMediaItemSelected(v, 1)
    reaper.Main_OnCommand(41173, 0)  --go to start
    reaper.Main_OnCommand(40375, 0)  --move to transient
    reaper.Main_OnCommand(40541, 0)  --set snap to cursor
    reaper.SetMediaItemSelected(v, 0)
end

for k, v in pairs(its) do
    reaper.SetMediaItemSelected(v, 1)
end
reaper.SetEditCurPos(cur, 0, 0)

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)