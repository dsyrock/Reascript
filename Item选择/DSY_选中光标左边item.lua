--[[
ReaScript Name: 选中光标左边item
Version: 1.0
Author: noiZ
]]

function sel_left()

    local cur=reaper.GetCursorPosition()

    reaper.PreventUIRefresh(1)

    reaper.SelectAllMediaItems(0, 0)

    reaper.Main_OnCommand(40749, 0)  -- loop point link to ts

    reaper.GetSet_LoopTimeRange(true, true, 0, cur, false)

    reaper.Main_OnCommand(40717, 0)  -- select items in ts

    reaper.Main_OnCommand(40635, 0)  -- remove ts

    reaper.PreventUIRefresh(-1)

    reaper.UpdateArrange()

end

sel_left()