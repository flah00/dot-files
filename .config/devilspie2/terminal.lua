-- Application: Terminal
-- Window: philipchampon@pcpc: ~
local Monitor_primary = { 0, 0, 1920, 1080 }
local Monitor_secondary = { 1920, 0, 1680, 1050 }

function Move_to_secondary_monitor()
	unmaximize()
	set_window_geometry(Monitor_primary[3], 0, 200, 200)
end

if (get_application_name() == "Terminal") or (get_application_name() == "Kitty") then
	Move_to_secondary_monitor()
	maximize()
	pin_window()
end
