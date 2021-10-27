--[[
ReaScript Name: 选中光标右边item
Version: 1.0
Author: noiZ
]]

function sel_right()

    local cur=reaper.GetCursorPosition()

    local edge=reaper.GetProjectLength(0)

    reaper.PreventUIRefresh(1)

    reaper.SelectAllMediaItems(0, 0)

    reaper.Main_OnCommand(40749, 0)  -- loop point link to ts

    reaper.GetSet_LoopTimeRange(true, true, cur, edge, false)

    reaper.Main_OnCommand(40717, 0)  -- select items in ts

    reaper.Main_OnCommand(40635, 0)  -- remove ts

    reaper.PreventUIRefresh(-1)

    reaper.UpdateArrange()

end

sel_right()