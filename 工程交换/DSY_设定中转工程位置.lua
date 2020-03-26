function msg(value)

  reaper.ShowConsoleMsg(tostring(value) .. "\n")

end

local check, path=reaper.GetUserFileNameForRead("", "请选择中转工程位置", "RPP")

if not check then return end

path=path:gsub("\\", "/")

--local path_nofilename=path:sub(1, (path:len()-string.find(path:reverse(), "/")))

reaper.SetExtState("Temp_Proj_Path", 1, path, 1)

