reaper.Undo_BeginBlock()

local it=reaper.GetSelectedMediaItem(0, 0)

local tk=reaper.GetActiveTake(it)

if tk then return end

local text_ori=reaper.ULT_GetMediaItemNote(it)

local check, text=reaper.GetUserInputs("Input text", 1, "Text", text_ori)

if not check then return end

reaper.ULT_SetMediaItemNote(it, "")

reaper.ULT_SetMediaItemNote(it, text)

local _, chunk=reaper.GetItemStateChunk(it, "", 0)

chunk = string.gsub(chunk, "IMGRESOURCEFLAGS 0", "IMGRESOURCEFLAGS 2")

reaper.SetItemStateChunk(it, chunk, 0)

reaper.UpdateArrange()

reaper.Undo_EndBlock("向empty item写入文字", -1)