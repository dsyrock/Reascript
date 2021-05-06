reaper.Undo_BeginBlock()

local num=reaper.CountSelectedMediaItems(0)

if num<=1 then return end

local its={}

for i=0, num-1 do

	table.insert(its, reaper.GetSelectedMediaItem(0, i))

end

local check, ep=reaper.GetUserInputs("请输入第一个视频的集数", 1, "集数", "")

if not check then return end

local _, chunk=reaper.GetItemStateChunk(its[1], '', false)

local path=chunk:match('FILE \"([^\"]+)\"')

local filename=path:match(".+[/\\]([^/\\]+)")

local idx=filename:find(ep, 1, true)

for k, v in pairs(its) do

    local pos=reaper.GetMediaItemInfo_Value(v, 'D_POSITION')

    local edge=reaper.GetMediaItemInfo_Value(v, 'D_LENGTH')+pos

    local _, chunk=reaper.GetItemStateChunk(v, '', false)

    local path=chunk:match('FILE \"([^\"]+)\"')
    
    local filename=path:match(".+[/\\]([^/\\]+)")

    local name

    if idx then

        name=filename:sub(idx, idx+#ep-1)

    else

        name=path:match(".+[/\\](.+)%.%w+$")

    end

    reaper.AddProjectMarker(0, true, pos, edge, name, reaper.CountProjectMarkers(0))

end

reaper.Undo_EndBlock("批量添加region并命名", -1)