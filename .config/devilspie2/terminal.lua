-- Application: Terminal
-- Window: philipchampon@pcpc: ~
monitor_primary = {0, 0, 1920, 1080}
monitor_secondary = {1920, 0, 1680, 1050}

function move_to_secondary_monitor()
    unmaximize()
    set_window_geometry(monitor_primary[3], 0, 200, 200)
end

if (get_application_name() == "Terminal") then
  move_to_secondary_monitor()
  maximize()
	pin_window();
end
