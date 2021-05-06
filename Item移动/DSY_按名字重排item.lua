reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num=reaper.CountSelectedMediaItems(0)
if num==0 then return end

local its={}
for i=0, num-1 do
    local it=reaper.GetSelectedMediaItem(0, i)
    local length=reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
    local tk=reaper.GetActiveTake(it)
    local name=reaper.GetTakeName(tk)
    its[i+1]={it=it, name=name, length=length}
end

function byname(t1, t2)
    return t1.name<t2.name
end
table.sort(its, byname)

local cur=reaper.GetCursorPosition()
reaper.Main_OnCommand(40290, 0)  --set ts
local left, right=reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
reaper.Main_OnCommand(40020, 0)  --remove ts
local start=left

for k, v in pairs(its) do
    reaper.SetMediaItemPosition(v.it, start, 0)
    start=start+v.length
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(debug.getinfo(1,'S').source:match[[^@?.*[\/]([^\/%.]+).+$]], -1)